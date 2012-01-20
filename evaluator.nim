import strutils
import tables
import math
import language_model
import os
import osproc
import subexes

type TKorpus = enum k1600_1650, k1650_1700, k1700_1750, k1750_1800, k1800_1850, k1850_1900, k1900_2010
const tests = 0
const orders = 6
const charBased = [0, 1]
const resultFileName = "results_test_$#_char_$#_order_$#"
const perLineOutput = "actual $# result $# $#"
const guessOutput = "guess actual $# result $# found $# times if above $#"
const resultOutput = "correct testkorpus $# $# if above $#"

template max_by(a, by: expr): expr =
  block:
    var
      result = a[k1600_1650]
      tmp = a[k1600_1650].by
    for item in a:
      if item.by > tmp:
        result = item
        tmp = item.by
    result

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
    #commands.add("./korpusgenerator" & " " & korpusfile & " " & $charBased.ord & " " & $order)
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
      run: array[TKorpus, tuple[korpus: TKorpus, probability: float]]
      runs: seq[tuple[guesses: array[TKorpus, tuple[korpus: TKorpus, probability: float]], length: int]] = @[]
    for line in lines("test_" & $test & "." & korpus_name):
      if line.len > 20:
        # run the tests
        run = recognize[TKorpus](korpi, line)
        echo repr(line)
        echo repr(run)
        runs.add((guesses: run, length: len(line)))
    # accumulate the results
    for above in [20,50,100,150]:
      var accumulatedGuesses: array[TKorpus, int]
      for i, j in accumulatedGuesses: accumulatedGuesses[i] = 0 # clear the array
      for run in runs:
        if run.length < above: continue
        var guess = max_by(run.guesses, probability).korpus
        inc(accumulated_guesses[guess])
      for guess, count in accumulatedGuesses:
        resultFile.writeln(guessOutput % [$korpus, $guess, $count, $above])
      resultFile.writeln(resultOutput % [$korpus, formatFloat(accumulatedGuesses[korpus]/len(runs)), $above])
      resultFile.write("\n")
