## Low-level Windows console operations
## Handles console initialization, mode management, and Windows-specific console APIs

import std/[winlean, bitops, encodings, unicode]
import ../core

proc getConsoleMode(
  hConsoleHandle: Handle, dwMode: ptr DWORD
): WINBOOL {.stdcall, dynlib: "kernel32", importc: "GetConsoleMode".}

proc setConsoleMode(
  hConsoleHandle: Handle, dwMode: DWORD
): WINBOOL {.stdcall, dynlib: "kernel32", importc: "SetConsoleMode".}

const
  ENABLE_MOUSE_INPUT = 0x10
  ENABLE_WINDOW_INPUT = 0x8
  ENABLE_QUICK_EDIT_MODE = 0x40
  ENABLE_EXTENDED_FLAGS = 0x80
  ENABLE_WRAP_AT_EOL_OUTPUT = 0x0002

var gOldConsoleModeInput*: DWORD
var gOldConsoleMode: DWORD

proc consoleInit*() =
  ## Initializes the Windows console
  ## Stores the old console modes for later restoration
  discard getConsoleMode(getStdHandle(STD_INPUT_HANDLE), gOldConsoleModeInput.addr)
  if gTermCtx.fullscreen:
    if getConsoleMode(getStdHandle(STD_OUTPUT_HANDLE), gOldConsoleMode.addr) != 0:
      var mode = gOldConsoleMode and (not ENABLE_WRAP_AT_EOL_OUTPUT)
      discard setConsoleMode(getStdHandle(STD_OUTPUT_HANDLE), mode)
  else:
    discard getConsoleMode(getStdHandle(STD_OUTPUT_HANDLE), gOldConsoleMode.addr)

proc consoleDeinit*() =
  ## Restores the original console mode
  if gOldConsoleMode != 0:
    discard setConsoleMode(getStdHandle(STD_OUTPUT_HANDLE), gOldConsoleMode)

proc enableMouse*(hConsoleInput: Handle) =
  ## Enables mouse input for the console
  var currentMode: DWORD
  discard getConsoleMode(hConsoleInput, currentMode.addr)
  discard setConsoleMode(
    hConsoleInput,
    ENABLE_WINDOW_INPUT or ENABLE_MOUSE_INPUT or ENABLE_EXTENDED_FLAGS or
      (currentMode and ENABLE_QUICK_EDIT_MODE.bitnot()),
  )

proc disableMouse*(hConsoleInput: Handle, oldConsoleMode: DWORD) =
  ## Disables mouse input and restores the old console mode
  discard setConsoleMode(hConsoleInput, oldConsoleMode)

proc writeConsole(
  hConsoleOutput: HANDLE,
  lpBuffer: pointer,
  nNumberOfCharsToWrite: DWORD,
  lpNumberOfCharsWritten: ptr DWORD,
  lpReserved: pointer,
): WINBOOL {.stdcall, dynlib: "kernel32", importc: "WriteConsoleW".}

var hStdout = getStdHandle(STD_OUTPUT_HANDLE)
var utf16LEConverter = open(destEncoding = "utf-16", srcEncoding = "UTF-8")

proc put*(s: string) =
  var us = utf16LEConverter.convert(s)
  var numWritten: DWORD
  discard
    writeConsole(hStdout, pointer(us[0].addr), DWORD(s.runeLen), numWritten.addr, nil)
