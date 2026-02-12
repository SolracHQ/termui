import std/macros
import illwill
import ../layout
import ../core/event
import std/hashes
import std/os

export illwill
export os
export event

# Helper predicates
proc isWithCommand(n: NimNode): bool =
  n.kind == nnkCommand and n.len > 0 and n[0].kind == nnkIdent and $n[0] == "with"

proc isAsInfix(n: NimNode): bool =
  n.kind == nnkInfix and n.len > 0 and $n[0] == "as"

proc isOnEventCommand(n: NimNode): bool =
  (n.kind == nnkCall or n.kind == nnkCommand) and n.len >= 3 and n[0].kind == nnkIdent and
    $n[0] == "onEvent"

proc isOnInitCommand(n: NimNode): bool =
  (n.kind == nnkCall or n.kind == nnkCommand) and n.len >= 2 and n[0].kind == nnkIdent and
    $n[0] == "onInit"

proc isOnQuitCommand(n: NimNode): bool =
  (n.kind == nnkCall or n.kind == nnkCommand) and n.len >= 2 and n[0].kind == nnkIdent and
    $n[0] == "onQuit"

proc hasNestedWithCommands(body: NimNode): bool =
  for child in body:
    if child.isWithCommand():
      return true
  return false

proc parseWithClause(
    stmt: NimNode
): tuple[expr: NimNode, sym: NimNode, body: NimNode, userSym: NimNode] =
  ## Parse with statment and return components
  ## "with" expr ( "as" ident )? ( ":" body )?
  let callOrInfix = stmt[1]
  result.body =
    if stmt.len > 2:
      stmt[2]
    else:
      newStmtList()

  if callOrInfix.isAsInfix():
    # with Widget() as name
    result.expr = callOrInfix[1]
    result.userSym = callOrInfix[2]
    result.sym = genSym(nskLet, $callOrInfix[2])
  else:
    # with Widget()
    result.expr = callOrInfix
    result.userSym = ident("self")
    result.sym = genSym(nskLet, "self")

proc parseOnEventCommand(stmt: NimNode): tuple[param: NimNode, body: NimNode] =
  ## Parse onEvent command - works for both onEvent(e): and onEvent e:
  result.param = stmt[1]
  result.body = stmt[2]

proc addWidgetTypeCheck(result: var NimNode, widgetSym, widgetExpr: NimNode) =
  ## Add a compile-time check to ensure the expression is a Widget
  let exprStr = widgetExpr.repr
  let errorNode = quote:
    when not (`widgetSym` is Widget):
      {.error: "expected a Widget but got '" & `exprStr` & "'".}
  result.add errorNode

proc addContainerTypeCheck(result: var NimNode, widgetSym, widgetExpr: NimNode) =
  ## Add a compile-time check to ensure the widget is a Container if it has children
  let exprStr = widgetExpr.repr
  let errorNode = quote:
    when not (`widgetSym` is Container):
      {.error: "cannot add children to non-container widget '" & `exprStr` & "'".}
  result.add errorNode

proc addWidgetToParent(result: var NimNode, parentSym, widgetSym: NimNode) =
  result.add quote do:
    `parentSym`.children.add(`widgetSym`)

proc processOnEventCommand(stmt: NimNode, widgetSym: NimNode): NimNode =
  ## Process onEvent command and attach handler to widget
  let (param, body) = parseOnEventCommand(stmt)

  result = quote:
    `widgetSym`.handler = proc(`param`: Event): bool =
      `body`

proc processNode(n: NimNode, parentSym: NimNode): NimNode =
  result = newStmtList()

  for stmt in n:
    # Handle onEvent at current level (attaches to parent)
    if stmt.isOnEventCommand():
      result.add processOnEventCommand(stmt, parentSym)
      continue

    # Handle regular statements
    if not stmt.isWithCommand():
      result.add stmt
      continue

    # Handle with commands
    let (widgetExpr, widgetSym, body, userSym) = parseWithClause(stmt)
    let hasChildren = body.hasNestedWithCommands()
    let randomValue = widgetSym.repr

    # Wrap each node in a block to create a new scope for `self`
    var blockContent = newStmtList()

    # Create widget with internal symbol
    blockContent.add quote do:
      let `widgetSym` = `widgetExpr`
      `widgetSym`.randomValue = `randomValue`

    # Create user-visible symbol (self or custom name)
    blockContent.add newLetStmt(userSym, widgetSym)

    # Type checks
    addWidgetTypeCheck(blockContent, widgetSym, widgetExpr)

    # Add widget to parent (using internal symbol)
    addWidgetToParent(blockContent, parentSym, widgetSym)

    if hasChildren:
      addContainerTypeCheck(blockContent, widgetSym, widgetExpr)
      blockContent.add processNode(body, widgetSym)
    else:
      # Process body statements with userSym in scope
      for child in body:
        if child.isOnEventCommand():
          blockContent.add processOnEventCommand(child, widgetSym)
        elif child.isOnInitCommand() or child.isOnQuitCommand():
          error(
            "onInit and onQuit are only allowed at the top level of tui block", child
          )
        else:
          blockContent.add child

    # Wrap in block
    result.add newBlockStmt(blockContent)

proc generateWidgetCode(procDef: NimNode): NimNode =
  ## Transform a widget proc into a proc that returns a Widget

  let body = procDef.body
  let resultSym = ident("result")
  let rootSym = genSym(nskVar, "root")
  let selfSym = ident("self")

  # Remove the widget pragma from the proc
  var newProcDef = procDef.copyNimTree()
  newProcDef.pragma = newEmptyNode()

  # Change return type to Widget
  newProcDef.params[0] = ident("Widget")

  # Create new body
  var newBody = newStmtList()

  # Initialize result as a VBox
  newBody.add quote do:
    var `rootSym` = newVBox(width = content(), height = content())
    let `selfSym` = `rootSym`
    `resultSym` = `rootSym`

  # Process the widget tree
  newBody.add processNode(body, rootSym)

  newProcDef.body = newBody
  result = newProcDef

proc generateTuiCode(body: NimNode, debug: bool): NimNode =
  ## Generate the full TUI application code from the body statements

  # Extract top-level onInit/onQuit blocks
  var onInitBody = newStmtList()
  var onQuitBody = newStmtList()
  var treeBody = newStmtList()
  var hasOnInit = false
  var hasOnQuit = false

  for stmt in body:
    if stmt.isOnInitCommand():
      if hasOnInit:
        error("tui block can only have one onInit block", stmt)
      hasOnInit = true
      onInitBody = stmt[1]
    elif stmt.isOnQuitCommand():
      if hasOnQuit:
        error("tui block can only have one onQuit block", stmt)
      hasOnQuit = true
      onQuitBody = stmt[1]
    else:
      treeBody.add stmt

  let rootSym = genSym(nskVar, "root")
  let runningSym = genSym(nskVar, "running")
  let quitProc = ident("quit")
  let selfSym = ident("self")
  let treeCode = processNode(treeBody, rootSym)
  let ctxSym = genSym(nskVar, "ctx")

  let renderCall =
    if debug:
      newCall(ident("renderBoxes"), rootSym, ctxSym)
    else:
      newCall(newDotExpr(rootSym, ident("render")), ctxSym)

  let setupCode = quote:
    # Setup illwill
    proc exitProc() {.noconv.} =
      illwillDeinit()
      showCursor()
      quit(0)

    illwillInit(fullscreen = true, mouse = false)
      # illwill mouse support is completely broken, TODO: fix it or migrate to another library
    setControlCHook(exitProc)
    hideCursor()

  let cleanupCode = quote:
    illwillDeinit()
    showCursor()

  result = quote:
    block:
      `setupCode`

      # onInit runs once
      `onInitBody`

      var `runningSym` = true
      var prevHash: Hash
      var prevWidth = terminalWidth()
      var prevHeight = terminalHeight()

      # Inject quit proc into scope
      proc `quitProc`() =
        `runningSym` = false

      while `runningSym`:
        # Poll event
        var event: Event
        let key = getKey()

        case key
        of Key.None:
          let (w, h) = (terminalWidth(), terminalHeight())
          if w != prevWidth or h != prevHeight:
            event = Event(kind: evResize, newWidth: w, newHeight: h)
            prevWidth = w
            prevHeight = h
          else:
            event = Event(kind: evUpdate, delta: 0.016) # TODO: calculate real delta
        of Key.Mouse:
          # event = Event(kind: evMouse, mouse: getMouse())
          discard
            # This is currently not supported due to issues with the underlying library. TODO: fix or migrate to another library.
        else:
          event = Event(kind: evKey, key: key)

        # Rebuild tree every frame
        var `rootSym` = newVBox(width = fill(), height = fill())
        let `selfSym` = `rootSym`
        `treeCode`

        # Dispatch event through tree
        discard `rootSym`.onEvent(event)

        # Hash and conditional render
        let currentHash = hash(`rootSym`)
        if currentHash != prevHash or event.kind == evResize:
          var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
          let terminalRect = Rect(
            pos: Position(x: 0, y: 0),
            size: Size(width: terminalWidth(), height: terminalHeight()),
          )

          discard `rootSym`.measure(terminalRect.size)
          discard `rootSym`.arrange(terminalRect)

          var `ctxSym` = RenderContext(tb: tb, clipRect: terminalRect)
          `renderCall`
          tb.display()

          prevHash = currentHash

        sleep(16)

      # onQuit runs after loop exits
      `onQuitBody`
      `cleanupCode`

macro widget*(procDef: untyped): untyped =
  ## Transform a proc into a widget builder function.
  ##
  ## Usage:
  ##   proc myButton(text: string, onClick: proc()) {.widget.} =
  ##     with newBorder():
  ##       with newLabel(text):
  ##         onEvent e:
  ##           if e.kind == evKey and e.key == Key.Enter:
  ##             onClick()
  ##
  ##   # Use it:
  ##   tui:
  ##     with myButton("Click me", proc() = echo "clicked!")

  if procDef.kind != nnkProcDef:
    error("widget pragma can only be applied to proc definitions", procDef)

  result = generateWidgetCode(procDef)

macro tui*(body: untyped): untyped =
  ## Main TUI macro. Can be used in two ways:
  ##
  ## 1. Block syntax (original):
  ##    tui:
  ##      with newLabel("Hello")
  ##      onEvent e:
  ##        if e.kind == evKey and e.key == Key.Escape:
  ##          quit()
  ##
  ## 2. Proc pragma syntax (new):
  ##    proc main() {.tui.} =
  ##      with newLabel("Hello")
  ##      onEvent e:
  ##        if e.kind == evKey and e.key == Key.Escape:
  ##          quit()

  if body.kind == nnkProcDef:
    result = body
    result.body = generateTuiCode(result.body, false)
  elif body.kind == nnkStmtList:
    result = generateTuiCode(body, false)
  else:
    error("tui macro expects a proc definition or a block of statements", body)

macro tuiDebug*(body: untyped): untyped =
  ## Debug version of tui that renders colored boxes showing widget boundaries
  ## instead of the actual widget content. Useful for debugging layout issues.
  if body.kind == nnkProcDef:
    result = body
    result.body = generateTuiCode(result.body, true)
  elif body.kind == nnkStmtList:
    result = generateTuiCode(body, true)
  else:
    error("tuiDebug macro expects a proc definition or a block of statements", body)
