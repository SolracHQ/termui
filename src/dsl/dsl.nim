import std/macros
import illwill
import ../widgets/hbox as widget_hbox
import ../widgets/vbox as widget_vbox
import ../widgets/label as widget_label
import ../widgets/padding as widget_padding
import ../widgets/rect as widget_rect
import ../widgets/textbox as widget_textbox
import ../layout/size_specs
import ../debug/boxes

# Helper predicates
proc isWithCommand(n: NimNode): bool =
  n.kind == nnkCommand and n.len > 0 and n[0].kind == nnkIdent and $n[0] == "with"

proc isAsInfix(n: NimNode): bool =
  n.kind == nnkInfix and n.len > 0 and $n[0] == "as"

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

proc processNode(n: NimNode, parentSym: NimNode): NimNode =
  result = newStmtList()

  for stmt in n:
    if not stmt.isWithCommand():
      result.add stmt
      continue

    let (widgetExpr, widgetSym, body, userSym) = parseWithClause(stmt)
    let hasChildren = body.hasNestedWithCommands()

    # Wrap each node in a block to create a new scope for `self`
    var blockContent = newStmtList()

    # Create widget with internal symbol
    blockContent.add quote do:
      let `widgetSym` = `widgetExpr`

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
        blockContent.add child

    # Wrap in block
    result.add newBlockStmt(blockContent)

proc generateTuiCode(body: NimNode, debug: bool): NimNode =
  let rootSym = genSym(nskVar, "root")
  let treeCode = processNode(body, rootSym)
  let selfSym = ident("self")
  let ctxSym = genSym(nskVar, "ctx")
  let tbSym = genSym(nskVar, "tb")

  let renderCall =
    if debug:
      newCall(ident("renderBoxes"), rootSym, ctxSym)
    else:
      newCall(newDotExpr(rootSym, ident("render")), ctxSym)

  result = quote:
    block:
      var `rootSym` = newVBox(width = fill(), height = fill())
      let `selfSym` = `rootSym`
      `treeCode`

      var `tbSym` = newTerminalBuffer(terminalWidth(), terminalHeight())
      let terminalRect = Rect(
        pos: Position(x: 0, y: 0),
        size: Size(width: terminalWidth(), height: terminalHeight()),
      )

      discard `rootSym`.measure(terminalRect.size)
      discard `rootSym`.arrange(terminalRect)

      var `ctxSym` = RenderContext(tb: `tbSym`, clipRect: terminalRect)
      `renderCall`
      `tbSym`.display()

macro tui*(body: untyped): untyped =
  generateTuiCode(body, false)

macro tuiDebug*(body: untyped): untyped =
  ## Debug version of tui that renders colored boxes showing widget boundaries
  ## instead of the actual widget content. Useful for debugging layout issues.
  generateTuiCode(body, true)
