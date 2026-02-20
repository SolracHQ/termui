## Low level console operations for Windows and Unix.
when defined(windows):
  import platform/windows
  export windows
elif defined(posix):
  import platform/unix
  export unix
else:
  {.error, "Unsupported platform".}
