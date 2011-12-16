import strutils
import tables
import math

const
  join_char = "{"

const langs = ["1600_1650", "1650_1700", "1700_1750", "1750_1800", "1800_1850", "1850_1900", "1900_2010"]

# copy/pasted
iterator ngrams(korpus: string, n: int, word_based = false): tuple[history: seq[string], word: string] = 
  var
    history: seq[string] = @[]
  for i in countup(0,n-2):
    history.add("")
  for word in korpus.split():
    yield(history, word)
    history.delete(0)
    history.add(word)
# </paste>

proc read_lang(lang_name: string, n: int): TTable[string, float] = 
  result = init_table[string, float](32)
  for line in lines("k" & lang_name & "W" & $n):
    var splitted = line.split()
    result[splitted[1]] = math.log2(splitted[0].parseFloat)

proc probabilities(line: string, n :int, models: seq[TTable[string, float]]): seq[float] =
  result = @[]
  for model in models.items():
    var counter = 0.0
    for history, word in ngrams(line, n):
      counter.inc model[history.join(joinchar) & joinchar & word]
    result.add(pow(counter, 2))
    
if os.paramCount() == 0:
  var commands: seq[string] = @[]
  for n in 1..6:
    for lang_name in langs.items():
      commands.add(os.getAppFilename() & " " & lang_name & " " & $n)
  discard execProcesses(commands, n = 6)

else:
  var
    lang_name = os.paramStr(1)
    n = os.paramStr(2).parse_int
    #korpus_name = "k" & korpus_name & "W" & $n
    #korpus = read_korpus(korpus_name, n)
    input_name = "e100-" & lang_name & ".txt"
  echo n
  echo lang_name
  var korpi = @[]
  for lang in langs.items():
    korpi.add read_korpus(lang_name, n)
  for line in lines(input_name):
    probabilities(line, n, korpi)
