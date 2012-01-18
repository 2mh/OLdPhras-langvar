import tables
import math
import strutils

type
  TLanguageModel* = object
    model*: TTable[string, float]
    order*: int
    charBased*: bool
  PLanguageModel* = ref TLanguageModel

const
  # this should work in almost all cases
  joinChar = '\x01'
  beginningOfLine = '\x02'

template any(container, cond: expr): expr =
  block:
    var result = false
    for it in items(container):
      if cond:
        result = true
        break
    result

proc newLanguageModel*(order: int, charBased: bool): PLanguageModel =
  new(result)
  result.model = initTable[string, float](32)
  result.order = order
  result.charBased = charBased
  
template ngramiter(basedOn, iter: expr) =
  iterator `ngrams basedOn`*(line: string, n: int): tuple[history: seq[basedOn], word: basedOn] = 
    var history: seq[basedOn] = @[]
    for i in countup(0,n-2):
      when basedOn is string:
        history.add($ beginningOfLine)
      else:
        history.add(beginningOfLine)
    for word in line.iter:
      yield(history, word)
      history.delete(0)
      history.add(word)

ngramiter(char, items)
ngramiter(string, split)

proc join(a: openarray[string], sep: char): string =
  result = a.join($sep)

proc join(a: openarray[char], sep: char): string =
  result = newStringOfCap(a.len*2-1)
  for item in a.items():
    result.add(item)
    result.add(sep)

template ngrams(line, order, CharBased: expr, execute: stmt): stmt = 
  if charBased:
    for history, word in ngramschar(line, order):
      execute
  else: 
    for history, word in ngramsstring(line, order):
      execute

proc train*(model: var TLanguageModel, file: TFile) =
  # this overwrites current training data, feel free to change
  var
    freqs = init_table[string, TCountTable[string]](128)
    hist: string
    sum: int
    
  for line in lines(file):
    ngrams(line, model.order, model.charBased):
      hist = history.join(joinChar) # join hack
      if not freqs.has_key(hist):
        freqs[hist] = init_count_table[string](32)
      freqs.mget(hist).inc($ word)
  for history, counts in freqs.pairs:
    sum = 0
    for number in counts.values: sum.inc(number)
    for word, count in counts.pairs:
      model.model[history & $joinChar & word] = count/sum

proc load*(file: TFile): PLanguageModel =
  var
    first = file.readline
    order: int
    charBased: bool
  file.setFilePos(0)
  
  # guess model type
  var grams = first.split(' ')[1].split(joinChar)
  if any(grams, len(it) > 1):
    charBased = false
  order = len(grams)
  
  # load file
  result = newLanguageModel(order, charBased)
  for line in file.lines:
    var splitted = line.split
    result.model[splitted[1]] = splitted[0].parseFloat
  
proc dump*(model: PLanguageModel, file: TFile) =
  # format: float word\x01word\x01word\n
  for key, value in model.model.pairs():
    file.write(formatFloat(value) & " " & key & "\n")
