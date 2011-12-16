import strutils
import tables
import osproc
import os

iterator ngrams(korpus: string, n: int, word_based = false): tuple[history: seq[string], word: string] = 
  var
    history: seq[string] = @[]
  for i in countup(0,n-2):
    history.add("")
  for word in korpus.split():
    yield(history, word)
    history.delete(0)
    history.add(word)

proc korpus_of(input_name: string, n: int): TTable[string, float] = 
  const
    join_char = "{"
  var
    freqs = init_table[string, TCountTable[string]](128)
    hist: string
    sum: int
    
  result = init_table[string, float]()
  for line in lines(input_name):
    for history, word in ngrams(line, n):
      hist = history.join(join_char) # join hack
      if not freqs.has_key(hist):
        freqs[hist] = init_count_table[string](32)
      freqs.mget(hist).inc(word)
  for history, counts in freqs.pairs:
    sum = 0
    for number in counts.values: sum.inc(number)
    for word, count in counts.pairs:
      result[history & join_char & word] = count/sum

if os.paramCount() == 0:
  var commands: seq[string] = @[]
  for n in 1..6:
    for korpus_name in ["1600_1650", "1650_1700", "1700_1750", "1750_1800", "1800_1850", "1850_1900", "1900_2010"].items():
      commands.add(os.getAppFilename() & " " & korpus_name & " " & $n)
  discard execProcesses(commands, n = 6)

else:
  var
    korpus_name = os.paramStr(1)
    n = os.paramStr(2).parse_int
    input_name = "t" & korpus_name & ".txt"
    output_name = "k" & korpus_name & "W" & $n
    korpus = korpus_of(input_name, n)
    output_file = open(output_name, fmWrite)
  echo output_name
  for key, value in korpus.pairs:
    output_file.write(formatFloat(value) & " " & key & "\n")
