import strutils
import tables
import math
import language_model
import os
import osproc

type TKorpus = enum k1600_1650, k1650_1700, k1700_1750, k1750_1800, k1800_1850, k1850_1900, k1900_2010
const tests = 9
const orders = 6
const charBased = [0, 1]

template korpus_name(): expr = ($korpus).substr(1)
if os.paramCount() == 0:
  var prepare: seq[string] = @[]
  var commands: seq[string] = @[]
  for test in 0..tests:
    for based in charBased:
      prepare.add(os.getAppFilename() & " " & $test & " " & $based & " " & $1)
      for order in 2..orders:
        commands.add(os.getAppFilename() & " " & $test & " " & $based & " " & $order)
  discard execProcesses(prepare, n = 6)
  discard execProcesses(commands, n = 6)

else:
  var
    test = os.paramStr(1).parseInt
    charBased = bool(os.paramStr(2).parseInt)
    order = os.paramStr(3).parseInt
    korpi: array[TKorpus, PLanguageModel]

  for korpus in low(TKorpus)..high(TKorpus):
    var
      inputFile = open("train_" & $test & "." & korpus_name)
      lm = newLanguageModel(order, charBased)
    if order > 1:
      var fallbackFile = open($test & $korpus_name & $charBased & $order)
      lm.fallback = load(fallbackFile)
    lm.train(inputFile)
    korpi[korpus] = lm
    if order == 1:
      var
        outputName = $test & $korpus_name & $charBased & $order
        outputFile = open(outputName, fmWrite)
      lm.dump(outputFile)
    
  for korpus in low(TKorpus)..high(TKorpus):
    for line in lines("test_" & $test & "." & korpus_name):
      var results = recognize(korpi, line)
