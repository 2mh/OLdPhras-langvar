import osproc
import os
import language_model
import strutils

proc parseBool(b: string): bool =
  var e: ref EInvalidValue
  case b
  of "true":
    result = true
  of "false":
    result = false
  else:
    e.new()
    e.msg = $b & " is not a bool"
    raise e
  
if os.paramCount() == 0:
  var commands: seq[string] = @[]
  for n in 1..6:
    for korpusName in ["1600_1650", "1650_1700", "1700_1750", "1750_1800", "1800_1850", "1850_1900", "1900_2010"].items():
      for charBased in [0, 1].items():
        commands.add(os.getAppFilename() & " " & korpusName & " " & $n & " " & $charBased)
  discard execProcesses(commands, n = 6)

else:
  var
    korpus_name = os.paramStr(1)
    n = os.paramStr(2).parseInt
    charBased = parseBool(os.paramStr(3))
    inputFile = open("t" & korpus_name & ".txt")
    outputName = "k" & korpus_name & "W" & $n
    lm = initLanguageModel(n, charBased)
    outputFile = open(outputName, fmWrite)
  lm.train(inputFile)
  lm.dump(outputFile)
  echo outputName
