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
  resultFileName = "results_test_$#_char_$#_order_$#_tested_$#"
  perLineOutput = "actual $# result $# $#"
  guessOutput = "guess actual $# result $# found $# times if above $#"
  resultOutput = "correct testkorpus $# $# if above $#"

template korpusname(): expr = ($korpus).substr(1)
template korpusfile(): expr = "train_" & $test & "." & korpusname

if os.paramCount() == 0:
  # generation
  var
    prepare: seq[string] = @[]
    commands: seq[string] = @[]
  for test in 0..tests:
    for based in charBased:
      for order in 1..orders:
        for korpus in low(TKorpus)..high(TKorpus):
          prepare.add("./korpusgenerator" & " " & korpusfile & " " & $based.ord & " " & $order)
          commands.add(os.getAppFilename() & " " & $test & " " & $based & " " & $order & " " & $korpus)
  if execProcesses(prepare) != 0:
    #raise newException(EIO, "corpi not written")
  else:
    echo "korpi generated!"
  discard execProcesses(commands, n = 6)

else:
  var
    test = os.paramStr(1).parseInt
    charBased = bool(os.paramStr(2).parseInt)
    order = os.paramStr(3).parseInt
    s = os.paramStr(4)
    korpi: array[TKorpus, PLanguageModel]
    totest: TKorpus
  for k in low(TKorpus)..high(TKorpus):
    if $k == s:
      totest = k

  for korpus in low(TKorpus)..high(TKorpus):
    var
      inputFile = open("trained_" & korpus_file & $charBased & $order)
      lm: PLanguageModel
    lm = load(inputFile)
    if order > 1:
      var fallbackFile = open("trained_" & korpus_file & $charBased & "1")
      lm.fallback = load(fallbackFile)
    korpi[korpus] = lm
    
  var resultFile = open(resultFileName % [$test, $CharBased.ord, $order, $totest], fmWrite)
  var
    korpus = totest
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
    var sum = 0
    for guess, count in accumulatedResults:
      sum += count
      resultFile.writeln(guessOutput % [$korpus, $guess, $count, $above])
    resultFile.writeln(resultOutput % [$korpus, formatFloat(accumulatedResults[korpus]/sum), $above])
    resultFile.write("\n")
