import osproc
import os
import language_model
import strutils
const korpi = ["1600_1650", "1650_1700", "1700_1750", "1750_1800", "1800_1850", "1850_1900", "1900_2010"]

var
  korpus_name = os.paramStr(1)
  charBased = bool(os.paramStr(2).parseInt)
  order = os.paramStr(3).parseInt
  inputFile = open(korpus_name)
  outputName = "trained_" & korpus_name & $charBased & $order
  outputFile = open(outputName, fmWrite)
  lm = newLanguageModel(order, charBased)

if order > 1:
  var fallbackFile = open("trained_" & $korpus_name & $charBased & $1)
  lm.fallback = load(fallbackFile)
if existsFile(outputName):
  echo "already trained: " & korpus_name
else:
  lm.train(inputFile)
  lm.dump(outputFile)
  echo "trained " & korpus_name
