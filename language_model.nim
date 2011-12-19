import tables
import math
import strutils

type
  TLanguageModel* = object
    model*: TTable[string, float]
    order: int
    charBased: bool

const
  # this should work in almost all cases
  joinChar = $'\x01'
  beginningOfLine = '\x02'

proc initLanguageModel*(order: int, charBased: bool): TLanguageModel =
  result.model = initTable[string, float](32)
  result.order = order
  result.charBased = charBased
  

template ngrams(basedOn, iter: expr) =
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

ngrams(char, items)
ngrams(string, split)

proc join(a: openarray[char], sep: string): string =
  result = newStringOfCap(a.len*2-1)
  for item in a.items():
    result.add(item)
    result.add(sep)

template processngrams() = 
  hist = history.join(joinChar) # join hack
  if not freqs.has_key(hist):
    freqs[hist] = init_count_table[string](32)
  freqs.mget(hist).inc($ word)

proc train*(model: var TLanguageModel, file: TFile) =
  # this overwrites current training data, feel free to change
  var
    freqs = init_table[string, TCountTable[string]](128)
    hist: string
    sum: int
    
  for line in lines(file):
    if model.charBased:
      for history, word in ngramschar(line, model.order):
        processngrams()
    else: 
      for history, word in ngramsstring(line, model.order):
        processngrams()
  for history, counts in freqs.pairs:
    sum = 0
    for number in counts.values: sum.inc(number)
    for word, count in counts.pairs:
      model.model[history & joinChar & word] = count/sum

proc load*(file: TFile): TLanguageModel =
  result.model = init_table[string, float](32)
  for line in file.lines:
    var splitted = line.split
    result.model[splitted[1..(-1)].join(joinChar)] = math.log2(splitted[0].parseFloat)
  
proc dump*(model: TLanguageModel, file: TFile) =
  for key, value in model.model.pairs():
    file.write(formatFloat(value) & " " & key & "\n")
  
