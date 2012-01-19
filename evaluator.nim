import strutils
import tables
import math
import language_model
import os
import osproc
import subexes

type TKorpus = enum k1600_1650, k1650_1700, k1700_1750, k1750_1800, k1800_1850, k1850_1900, k1900_2010
const tests = 9
const orders = 6
const charBased = [0, 1]
const resultFileName = "results_ $# $[chars|words]# $#"
const perLineOutput = "perline actual $# result $# $#"
const resultOutput = "correct testkorpus $#"

template max_by(a: seq, by: expr): expr =
  block:
    var
      result = a[0]
      tmp = a[0].by
    for item in a:
      if item.by > tmp:
        result = item
        tmp = item.by
    result

template korpus_name(): expr = ($korpus).substr(1)
if os.paramCount() == 0:
  var prepare: seq[string] = @[]
  var commands: seq[string] = @[]
  for test in 0..tests:
    for based in charBased:
      prepare.add(os.getAppFilename() & " " & $test & " " & $based & " " & $1)
      for order in 2..orders:
        commands.add(os.getAppFilename() & " " & $test & " " & $based & " " & $order)
  if execProcesses(prepare, n = 6) != 0:
    raise newException(EIO, "preparation failed, aborting!")
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
    
  var resultFile = open(resultFileName % [$test, $CharBased.ord, $order], fmWrite)
  for korpus in low(TKorpus)..high(TKorpus):
    var
      runs: seq[seq[tuple[korpus: TKorpus, probability: float]]]
    for line in lines("test_" & $test & "." & korpus_name):
      # run the tests
      var run = recognize[TKorpus](korpi, line)
      runs.add(run)
      for res in run:
        resultFile.writeln(perLineOutput % [$korpus, $res.korpus, $res.probability])
      resultFile.write("\n")
    # accumulate the results
    var correct = 0
    for results in runs:
      if max_by(results, probability).korpus == korpus:
        correct += 1
    resultFile.writeln(resultOutput % [$(correct/len(runs))])
