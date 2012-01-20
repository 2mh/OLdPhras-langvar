import strutils
import tables
import math
import language_model
import os
import osproc
import subexes

type
  TKorpus = enum k1600_1650, k1650_1700, k1700_1750, k1750_1800, k1800_1850, k1850_1900, k1900_2010
  TRun = object
    result: TKorpus
    length: int
    
const
  tests = 0
  orders = 6
  charBased = [0, 1]
  resultFileName = "results_test_$#_char_$#_order_$#"
  perLineOutput = "actual $# result $# $#"
  guessOutput = "guess actual $# result $# found $# times if above $#"
  resultOutput = "correct testkorpus $# $# if above $#"

template korpus_name(): expr = ($korpus).substr(1)
template korpus_file(): expr = "train_" & $test & "." & korpus_name

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

  var commands: seq[string] = @[]
  # generation
  for korpus in low(TKorpus)..high(TKorpus):
    echo "./korpusgenerator" & " " & korpusfile & " " & $charBased.ord & " " & $order
    commands.add("./korpusgenerator" & " " & korpusfile & " " & $charBased.ord & " " & $order)
  if execProcesses(commands) != 0:
    raise newException(EIO, "corpi not written")
  else:
    echo "korpi generated!"
  for korpus in low(TKorpus)..high(TKorpus):
    var
      inputFile = open("trained_" & korpus_file & $charBased & $order)
      lm: PLanguageModel
    lm = load(inputFile)
    if order > 1:
      var fallbackFile = open("trained_" & korpus_file & $charBased & "1")
      lm.fallback = load(fallbackFile)
    korpi[korpus] = lm
    
  var resultFile = open(resultFileName % [$test, $CharBased.ord, $order], fmWrite)
  for korpus in low(TKorpus)..high(TKorpus):
    var
      runs: seq[TRun] = @[]
    for line in lines("test_" & $test & "." & korpus_name):
      if line.len > 20:
        var run: TRun
        # run the tests
        run.result = recognize[TKorpus](korpi, line)
        run.length = len(line)
        runs.add(run)
    # accumulate the results
    for above in [20,50,100,150]:
      var accumulatedResults: array[TKorpus, int]
      for i,j in accumulatedResults: accumulatedResults[i] = 0 # clear the array
      for run in runs:
        if run.length < above: continue
        inc(accumulatedResults[run.result])
      for guess, count in accumulatedResults:
        resultFile.writeln(guessOutput % [$korpus, $guess, $count, $above])
      resultFile.writeln(resultOutput % [$korpus, formatFloat(accumulatedResults[korpus]/len(runs)), $above])
      resultFile.write("\n")
