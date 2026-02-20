import std/macros
import ../term
import ../core/widget
import ../core/constraints
import ../container
import std/hashes

export term

# Helper predicates
proc isOnEventCommand(n: NimNode): bool =
  (n.kind == nnkCall or n.kind == nnkCommand) and n.len >= 2 and n[0].kind == nnkIdent and
    $n[0] == "onEvent"

proc isOnInitCommand(n: NimNode): bool =
  (n.kind == nnkCall or n.kind == nnkCommand) and n.len >= 2 and n[0].kind == nnkIdent and
    $n[0] == "onInit"

proc isOnQuitCommand(n: NimNode): bool =
  (n.kind == nnkCall or n.kind == nnkCommand) and n.len >= 2 and n[0].kind == nnkIdent and
    $n[0] == "onQuit"

proc isWithCommand(n: NimNode): bool =
  n.kind == nnkCommand and n.len >= 2 and n[0].kind == nnkIdent and $n[0] == "with"

proc transformStmt(parent: NimNode, stmt: NimNode): NimNode

proc transformBody(parent: NimNode, body: NimNode): NimNode =
  result = newStmtList()
  for stmt in body:
    result.add transformStmt(parent, stmt)

proc transformStmt(parent: NimNode, stmt: NimNode): NimNode =
  if stmt.isOnEventCommand():
    let param = stmt[1]
    let eventBody = stmt[2]
    result = quote:
      `parent`.handler = proc(`param`: Event): bool =
        `eventBody`
  elif stmt.isWithCommand():
    let widgetExpr = stmt[1]
    let widgetBody =
      if stmt.len > 2:
        stmt[2]
      else:
        newStmtList()
    let widgetSym = genSym(nskLet, "widget")
    let randomValue = widgetSym.repr
    result = quote:
      block:
        let `widgetSym` = `widgetExpr`
        `widgetSym`.randomValue = `randomValue`
        when not (`parent` is Container):
          {.error: "cannot add children to non-container widget".}
        `parent`.children.add(`widgetSym`)
        with(`widgetSym`, `widgetBody`)
  elif stmt.kind in {nnkIfStmt, nnkWhenStmt}:
    # Recurse into branches
    result = stmt.copyNimTree()
    for i in 0 ..< result.len:
      let branch = result[i]
      # branch is nnkElifBranch, nnkElifExpr, or nnkElse
      let lastIdx = branch.len - 1
      branch[lastIdx] = transformBody(parent, branch[lastIdx])
  elif stmt.kind == nnkCaseStmt:
    result = stmt.copyNimTree()
    for i in 1 ..< result.len: # skip the selector expression
      let branch = result[i]
      let lastIdx = branch.len - 1
      branch[lastIdx] = transformBody(parent, branch[lastIdx])
  elif stmt.kind in {nnkBlockStmt, nnkStmtList}:
    result = stmt.copyNimTree()
    let lastIdx = result.len - 1
    result[lastIdx] = transformBody(parent, result[lastIdx])
  else:
    result = stmt

macro with*(parent: Widget | Container, body: untyped = nil): untyped =
  ## Core with macro that processes all statements in body
  ##
  ## Handles:
  ## - Regular statements (executed with `self` = parent in scope)
  ## - Nested with commands (creates child widgets)
  ## - onEvent handlers (attached to parent)
  ##
  ## Usage:
  ##   with(myContainer):
  ##     # self refers to myContainer
  ##     self.padding = 10
  ##
  ##     # Create child widget
  ##     with newLabel("Hello"):
  ##       self.color = fgRed
  ##
  ##     # Attach event handler to myContainer
  ##     onEvent e:
  ##       if e.kind == evKey:
  ##         echo "Key pressed"
  let selfSym = ident("self")
  result = newStmtList()
  result.add quote do:
    let `selfSym` {.used.} = `parent`

  for stmt in body:
    result.add transformStmt(parent, stmt)

  result = newBlockStmt(result)

proc generateTuiCode(body: NimNode): NimNode =
  ## Generate the full TUI application code from the body statements

  # Separate statements
  var onInitBody = newStmtList()
  var onQuitBody = newStmtList()
  var treeCode = newStmtList()
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
      # Everything else goes into treeCode (including onEvent and with)
      treeCode.add(stmt)

  let rootSym = ident("root")
  let selfSym = ident("self")
  let quitProc = ident("quit")
  let ctxSym = genSym(nskVar, "ctx")
  let debugModeSym = ident("debugMode")

  result = quote:
    block:
      var `rootSym` =
        newContainer(modifier = newModifier(width = fill(), height = fill()))
      let `selfSym` {.used.} = `rootSym`

      # Debug mode flag - can be toggled at runtime
      var `debugModeSym` {.inject.} = false

      # onInit runs once before the loop
      `onInitBody`

      var prevHash: Hash
      var shouldQuit = false

      # Inject quit proc into scope
      proc `quitProc`() =
        shouldQuit = true

      # Main loop using onTerm template
      onTerm(fullscreen = true, mouse = true, targetFps = 60):
        if shouldQuit:
          frExit
        else:
          # Dispatch events to current tree
          for event in events:
            discard `rootSym`.onEvent(event)

          # Rebuild tree
          `rootSym` =
            newContainer(modifier = newModifier(width = fill(), height = fill()))

          # Build widget tree using with macro
          with(`rootSym`, `treeCode`)

          let terminalRect = Rect(
            pos: Position(x: 0, y: 0), size: Size(width: tb.width, height: tb.height)
          )

          discard `rootSym`.measure(terminalRect.size)
          discard `rootSym`.arrange(terminalRect)

          # Check if render needed
          let currentHash =
            hash(`rootSym`) !& hash(`debugModeSym`) !& hash(terminalRect)
          if currentHash != prevHash:
            prevHash = currentHash

            var `ctxSym` = RenderContext(slice: newSlice(tb, terminalRect))

            # Runtime debug mode toggle
            if `debugModeSym`:
              renderBoxes(`rootSym`, `ctxSym`)
            else:
              `rootSym`.render(`ctxSym`)

            frDisplay
          else:
            frPreserve

      # onQuit runs after loop exits
      `onQuitBody`

macro tui*(body: untyped): untyped =
  ## Main TUI macro
  ##
  ## Can be used in two ways:
  ##
  ## 1. Block syntax:
  ##    tui:
  ##      onInit:
  ##        echo "Starting app"
  ##
  ##      with newLabel("Hello"):
  ##        self.color = fgRed
  ##
  ##      onEvent e:
  ##        if e.kind == evKey and e.key == Key.Escape:
  ##          quit()
  ##
  ##      onQuit:
  ##        echo "Goodbye"
  ##
  ## 2. Proc pragma syntax:
  ##    proc main() {.tui.} =
  ##      with newLabel("Hello")
  ##      onEvent e:
  ##        if e.kind == evKey and e.key == Key.Escape:
  ##          quit()
  ##
  ## Debug mode:
  ##   You can toggle debug mode at runtime by setting debugMode = true/false
  ##   in your code (e.g., in onInit or in an event handler):
  ##
  ##    tui:
  ##      onEvent e:
  ##        if e.kind == ekKey and e.key.name == "D":
  ##          debugMode = not debugMode  # Toggle debug mode

  if body.kind == nnkProcDef:
    # Proc definition - transform the body
    result = body.copyNimTree()
    result.body = generateTuiCode(result.body)
  elif body.kind == nnkStmtList:
    # Block syntax
    result = generateTuiCode(body)
  else:
    error("tui macro expects a proc definition or a block of statements", body)

macro widget*(procDef: untyped): untyped =
  ## Transform a proc into a widget builder function.
  ##
  ## Usage:
  ##   proc myButton(text: string) {.widget.} =
  ##     with newLabel(text):
  ##       self.color = fgRed
  ##
  ##     onEvent e:
  ##       if e.kind == evKey:
  ##         echo "Key pressed on button"

  if procDef.kind != nnkProcDef:
    error("widget pragma can only be applied to proc definitions", procDef)

  let body = procDef.body
  let resultSym = ident("result")
  let parentSym = genSym(nskLet, "parent")

  # Remove the widget pragma from the proc
  var newProcDef = procDef.copyNimTree()

  # Change return type to Widget
  newProcDef.params[0] = ident("Widget")

  # Create new body
  newProcDef.body = quote:
    let `parentSym` = newContainer()
    `resultSym` = `parentSym`
    with(`parentSym`, `body`)

  result = newProcDef
