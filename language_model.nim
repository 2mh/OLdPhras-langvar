import tables
import math
import strutils

type
  TModelKind = enum firstOrder, higherOrder
  TLanguageModel* = object
    model*: TTable[string, float]
    order*: int
    charBased*: bool
    case kind: TModelKind
    of firstOrder:
      smooth: float
    of higherOrder:
      fallback*: PLanguageModel
  PLanguageModel* = ref TLanguageModel

const
  # this should work in almost all cases
  joinChar = '\x01'
  beginningOfLine = '\x02'
  dumpsplit = '\x03'

proc pow(x,y: int): float =
  result = pow(toFloat(x), toFloat(y))

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
  if order > 1:
    result.kind = higherOrder
  else:
    result.kind = firstOrder
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
  for i in 0..len(a)-1:
    result.add(a[i])
    if i < len(a)-1:
      result.add(sep)

template ngrams(line, order, CharBased: expr, execute: stmt): stmt = 
  if charBased:
    for history, word in ngramschar(line, order):
      execute
  else: 
    for history, word in ngramsstring(line, order):
      execute

proc train*(model: var PLanguageModel, file: TFile) =
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

  if model.kind == firstOrder:
    model.smooth = math.log2(0.5/toFloat(len(freqs)))

  for history, counts in freqs.pairs:
    sum = 0
    for number in counts.values: sum.inc(number)
    for word, count in counts.pairs:
      var prob: float
      # smoothing
      if model.kind == firstOrder:
        prob = math.log2((count.toFloat+0.5)/sum.toFloat*1.5)
        model.model[word] = prob
      elif model.kind == higherOrder:
        prob = math.log2(count.toFloat/(sum.toFloat+len(model.fallback.model).pow(model.order-1)*0.5))
        model.model[history & $joinChar & word] = prob
      else:
        raise newException(EIO, "no order set, don't know how to smooth")

proc load*(file: TFile): PLanguageModel =
  var
    first = file.readline
    order: int
    charBased: bool
  file.setFilePos(0)
  
  # guess model type
  var grams = first.split(dumpsplit)[1].split(joinChar)
  charBased = not any(grams, len(it) > 1)
  order = len(grams)
  
  # load file
  result = newLanguageModel(order, charBased)
  for line in file.lines:
    var splitted = line.split(dumpsplit)
    result.model[splitted[1]] = splitted[0].parseFloat
  if order > 1:
    result.kind = higherOrder
  else:
    result.kind = firstOrder
  if result.kind == firstOrder:
    result.smooth = math.log2(0.5/toFloat(len(result.model)))
  
proc dump*(model: PLanguageModel, file: TFile) =
  # format: float word\x01word\x01word\n
  for key, value in model.model.pairs():
    file.write(formatFloat(value) & dumpsplit & key & "\n")

proc get(model: PLanguageModel, key: string): float
proc get(model: PLanguageModel, key, word: string): float =
  if model.model.hasKey(key):
    result = model.model[key]
  else:
    if model.kind == higherOrder:
      result = model.fallback.get(word)/((model.fallback.model.len).pow(model.order-1)*0.5)
    else:
      result = model.smooth
proc get(model: PLanguageModel, key: string): float =
  result = get(model, key, "")
  
iterator pairs*[T: enum, U](ary: array[T,U]): tuple[index: T, value: U] =
  for index in low(T)..high(T):
    yield(index, ary[index])

proc recognize*[T](models: array[T, PLanguageModel], target: string): array[T, tuple[korpus: T, probability: float]] =
  # it is advised to set model.fallback to the model of order 1
  var key: string
  for name, model in pairs(models):
    var probability: float
    ngrams(target, model.order, model.charBased):
      var ngram = history
      ngram.add(word)
      key = join(ngram,joinChar) # join hack
      probability += get(model, key, $word)
    result[name] = (korpus: name, probability: probability)
