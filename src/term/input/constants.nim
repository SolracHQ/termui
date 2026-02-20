import ../../core
export core

const None* = Event(kind: ekNone)

proc event*(e: KeyEvent | MouseMoveEvent | MouseButtonEvent | MouseScrollEvent): Event =
  when e is KeyEvent:
    result = Event(kind: ekKey, key: e)
  elif e is MouseMoveEvent:
    result = Event(kind: ekMouseMove, mouseMove: e)
  elif e is MouseButtonEvent:
    result = Event(kind: ekMouseButton, mouseButton: e)
  elif e is MouseScrollEvent:
    result = Event(kind: ekMouseScroll, mouseScroll: e)
  else:
    result = None

proc initKeyEventArray(): array[1023, Event] =
  for i in 0 ..< 1023:
    result[i] = None

  # Special ASCII characters
  result[1] = KeyEvent(code: 1, name: "A", modifier: emCtrl).event
  result[2] = KeyEvent(code: 2, name: "B", modifier: emCtrl).event
  result[3] = KeyEvent(code: 3, name: "C", modifier: emCtrl).event
  result[4] = KeyEvent(code: 4, name: "D", modifier: emCtrl).event
  result[5] = KeyEvent(code: 5, name: "E", modifier: emCtrl).event
  result[6] = KeyEvent(code: 6, name: "F", modifier: emCtrl).event
  result[7] = KeyEvent(code: 7, name: "G", modifier: emCtrl).event
  result[8] = KeyEvent(code: 8, name: "H", modifier: emCtrl).event
  result[9] = KeyEvent(code: 9, name: "Tab").event # Ctrl-I
  result[10] = KeyEvent(code: 10, name: "J", modifier: emCtrl).event
  result[11] = KeyEvent(code: 11, name: "K", modifier: emCtrl).event
  result[12] = KeyEvent(code: 12, name: "L", modifier: emCtrl).event
  result[13] = KeyEvent(code: 13, name: "Enter").event # Ctrl-M
  result[14] = KeyEvent(code: 14, name: "N", modifier: emCtrl).event
  result[15] = KeyEvent(code: 15, name: "O", modifier: emCtrl).event
  result[16] = KeyEvent(code: 16, name: "P", modifier: emCtrl).event
  result[17] = KeyEvent(code: 17, name: "Q", modifier: emCtrl).event
  result[18] = KeyEvent(code: 18, name: "R", modifier: emCtrl).event
  result[19] = KeyEvent(code: 19, name: "S", modifier: emCtrl).event
  result[20] = KeyEvent(code: 20, name: "T", modifier: emCtrl).event
  result[21] = KeyEvent(code: 21, name: "U", modifier: emCtrl).event
  result[22] = KeyEvent(code: 22, name: "V", modifier: emCtrl).event
  result[23] = KeyEvent(code: 23, name: "W", modifier: emCtrl).event
  result[24] = KeyEvent(code: 24, name: "X", modifier: emCtrl).event
  result[25] = KeyEvent(code: 25, name: "Y", modifier: emCtrl).event
  result[26] = KeyEvent(code: 26, name: "Z", modifier: emCtrl).event
  result[27] = KeyEvent(code: 27, name: "Escape").event
  result[28] = KeyEvent(code: 28, name: "h", modifier: emCtrl).event
  result[29] = KeyEvent(code: 29, name: "t", modifier: emCtrl).event

  # Printable ASCII characters
  result[32] = KeyEvent(code: 32, name: "Space").event
  result[33] = KeyEvent(code: 33, name: "ExclamationMark").event
  result[34] = KeyEvent(code: 34, name: "DoubleQuote").event
  result[35] = KeyEvent(code: 35, name: "Hash").event
  result[36] = KeyEvent(code: 36, name: "Dollar").event
  result[37] = KeyEvent(code: 37, name: "Percent").event
  result[38] = KeyEvent(code: 38, name: "Ampersand").event
  result[39] = KeyEvent(code: 39, name: "SingleQuote").event
  result[40] = KeyEvent(code: 40, name: "LeftParen").event
  result[41] = KeyEvent(code: 41, name: "RightParen").event
  result[42] = KeyEvent(code: 42, name: "Asterisk").event
  result[43] = KeyEvent(code: 43, name: "Plus").event
  result[44] = KeyEvent(code: 44, name: "Comma").event
  result[45] = KeyEvent(code: 45, name: "Minus").event
  result[46] = KeyEvent(code: 46, name: "Dot").event
  result[47] = KeyEvent(code: 47, name: "Slash").event
  result[48] = KeyEvent(code: 48, name: "Zero").event
  result[49] = KeyEvent(code: 49, name: "One").event
  result[50] = KeyEvent(code: 50, name: "Two").event
  result[51] = KeyEvent(code: 51, name: "Three").event
  result[52] = KeyEvent(code: 52, name: "Four").event
  result[53] = KeyEvent(code: 53, name: "Five").event
  result[54] = KeyEvent(code: 54, name: "Six").event
  result[55] = KeyEvent(code: 55, name: "Seven").event
  result[56] = KeyEvent(code: 56, name: "Eight").event
  result[57] = KeyEvent(code: 57, name: "Nine").event
  result[58] = KeyEvent(code: 58, name: "Colon").event
  result[59] = KeyEvent(code: 59, name: "Semicolon").event
  result[60] = KeyEvent(code: 60, name: "LessThan").event
  result[61] = KeyEvent(code: 61, name: "Equals").event
  result[62] = KeyEvent(code: 62, name: "GreaterThan").event
  result[63] = KeyEvent(code: 63, name: "QuestionMark").event
  result[64] = KeyEvent(code: 64, name: "At").event
  result[65] = KeyEvent(code: 65, name: "A", modifier: emShift).event
  result[66] = KeyEvent(code: 66, name: "B", modifier: emShift).event
  result[67] = KeyEvent(code: 67, name: "C", modifier: emShift).event
  result[68] = KeyEvent(code: 68, name: "D", modifier: emShift).event
  result[69] = KeyEvent(code: 69, name: "E", modifier: emShift).event
  result[70] = KeyEvent(code: 70, name: "F", modifier: emShift).event
  result[71] = KeyEvent(code: 71, name: "G", modifier: emShift).event
  result[72] = KeyEvent(code: 72, name: "H", modifier: emShift).event
  result[73] = KeyEvent(code: 73, name: "I", modifier: emShift).event
  result[74] = KeyEvent(code: 74, name: "J", modifier: emShift).event
  result[75] = KeyEvent(code: 75, name: "K", modifier: emShift).event
  result[76] = KeyEvent(code: 76, name: "L", modifier: emShift).event
  result[77] = KeyEvent(code: 77, name: "M", modifier: emShift).event
  result[78] = KeyEvent(code: 78, name: "N", modifier: emShift).event
  result[79] = KeyEvent(code: 79, name: "O", modifier: emShift).event
  result[80] = KeyEvent(code: 80, name: "P", modifier: emShift).event
  result[81] = KeyEvent(code: 81, name: "Q", modifier: emShift).event
  result[82] = KeyEvent(code: 82, name: "R", modifier: emShift).event
  result[83] = KeyEvent(code: 83, name: "S", modifier: emShift).event
  result[84] = KeyEvent(code: 84, name: "T", modifier: emShift).event
  result[85] = KeyEvent(code: 85, name: "U", modifier: emShift).event
  result[86] = KeyEvent(code: 86, name: "V", modifier: emShift).event
  result[87] = KeyEvent(code: 87, name: "W", modifier: emShift).event
  result[88] = KeyEvent(code: 88, name: "X", modifier: emShift).event
  result[89] = KeyEvent(code: 89, name: "Y", modifier: emShift).event
  result[90] = KeyEvent(code: 90, name: "Z", modifier: emShift).event
  result[91] = KeyEvent(code: 91, name: "LeftBracket").event
  result[92] = KeyEvent(code: 92, name: "Backslash").event
  result[93] = KeyEvent(code: 93, name: "RightBracket").event
  result[94] = KeyEvent(code: 94, name: "Caret").event
  result[95] = KeyEvent(code: 95, name: "Underscore").event
  result[96] = KeyEvent(code: 96, name: "GraveAccent").event
  result[97] = KeyEvent(code: 97, name: "A").event
  result[98] = KeyEvent(code: 98, name: "B").event
  result[99] = KeyEvent(code: 99, name: "C").event
  result[100] = KeyEvent(code: 100, name: "D").event
  result[101] = KeyEvent(code: 101, name: "E").event
  result[102] = KeyEvent(code: 102, name: "F").event
  result[103] = KeyEvent(code: 103, name: "G").event
  result[104] = KeyEvent(code: 104, name: "H").event
  result[105] = KeyEvent(code: 105, name: "I").event
  result[106] = KeyEvent(code: 106, name: "J").event
  result[107] = KeyEvent(code: 107, name: "K").event
  result[108] = KeyEvent(code: 108, name: "L").event
  result[109] = KeyEvent(code: 109, name: "M").event
  result[110] = KeyEvent(code: 110, name: "N").event
  result[111] = KeyEvent(code: 111, name: "O").event
  result[112] = KeyEvent(code: 112, name: "P").event
  result[113] = KeyEvent(code: 113, name: "Q").event
  result[114] = KeyEvent(code: 114, name: "R").event
  result[115] = KeyEvent(code: 115, name: "S").event
  result[116] = KeyEvent(code: 116, name: "T").event
  result[117] = KeyEvent(code: 117, name: "U").event
  result[118] = KeyEvent(code: 118, name: "V").event
  result[119] = KeyEvent(code: 119, name: "W").event
  result[120] = KeyEvent(code: 120, name: "X").event
  result[121] = KeyEvent(code: 121, name: "Y").event
  result[122] = KeyEvent(code: 122, name: "Z").event
  result[123] = KeyEvent(code: 123, name: "LeftBrace").event
  result[124] = KeyEvent(code: 124, name: "Pipe").event
  result[125] = KeyEvent(code: 125, name: "RightBrace").event
  result[126] = KeyEvent(code: 126, name: "Tilde").event
  result[127] = KeyEvent(code: 127, name: "Backspace").event

  # Special characters with virtual keycodes
  result[1001] = KeyEvent(code: 1001, name: "Up").event
  result[1002] = KeyEvent(code: 1002, name: "Down").event
  result[1003] = KeyEvent(code: 1003, name: "Right").event
  result[1004] = KeyEvent(code: 1004, name: "Left").event
  result[1005] = KeyEvent(code: 1005, name: "Home").event
  result[1006] = KeyEvent(code: 1006, name: "Insert").event
  result[1007] = KeyEvent(code: 1007, name: "Delete").event
  result[1008] = KeyEvent(code: 1008, name: "End").event
  result[1009] = KeyEvent(code: 1009, name: "PageUp").event
  result[1010] = KeyEvent(code: 1010, name: "PageDown").event
  result[1011] = KeyEvent(code: 1011, name: "F1").event
  result[1012] = KeyEvent(code: 1012, name: "F2").event
  result[1013] = KeyEvent(code: 1013, name: "F3").event
  result[1014] = KeyEvent(code: 1014, name: "F4").event
  result[1015] = KeyEvent(code: 1015, name: "F5").event
  result[1016] = KeyEvent(code: 1016, name: "F6").event
  result[1017] = KeyEvent(code: 1017, name: "F7").event
  result[1018] = KeyEvent(code: 1018, name: "F8").event
  result[1019] = KeyEvent(code: 1019, name: "F9").event
  result[1020] = KeyEvent(code: 1020, name: "F10").event
  result[1021] = KeyEvent(code: 1021, name: "F11").event
  result[1022] = KeyEvent(code: 1022, name: "F12").event

const keyEvents* = initKeyEventArray()

func toKey*(c: int): Event =
  ## Converts a character code to a Key event
  if c >= 0 and c <= 1022:
    return keyEvents[c]
  else:
    return None

const Tab* = keyEvents[9]
const Enter* = keyEvents[13]
const Escape* = keyEvents[27]
const Space* = keyEvents[32]
const Backspace* = keyEvents[127]
const Up* = keyEvents[1001]
const Down* = keyEvents[1002]
const Right* = keyEvents[1003]
const Left* = keyEvents[1004]
const End* = keyEvents[1008]
const Home* = keyEvents[1005]
const Insert* = keyEvents[1006]
const Delete* = keyEvents[1007]
const PageUp* = keyEvents[1009]
const PageDown* = keyEvents[1010]
const F1* = keyEvents[1011]
const F2* = keyEvents[1012]
const F3* = keyEvents[1013]
const F4* = keyEvents[1014]
const F5* = keyEvents[1015]
const F6* = keyEvents[1016]
const F7* = keyEvents[1017]
const F8* = keyEvents[1018]
const F9* = keyEvents[1019]
const F10* = keyEvents[1020]
const F11* = keyEvents[1021]
const F12* = keyEvents[1022]
