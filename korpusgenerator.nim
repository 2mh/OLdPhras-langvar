import strutils
import tables
import math

iterator ngrams(korpus: string, n: int, word_based = false): tuple[history: seq[string], word: string] = 
  var
    history: seq[string] = @[]
  for i in countup(0,n-2):
    history.add("")
  for word in korpus.split():
    yield(history, word)
    history.delete(0)
    history.add(word)

for korpus in ["1600_1650", "1650_1700", "1700_1750", "1750_1800", "1800_1850", "1850_1900", "1900_2010"].items():
  const
    join_char = "{"
    n = 3
  var
    freqs = init_table[string, TCountTable[string]](128)
    hist: string
    sum: int
    language_model = init_table[string, float]()
    input_name = "t" & korpus & ".txt"
    output_name = "k" & korpus
    
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
      language_model[history & join_char & word] = count/sum
  var output_file = open(output_name, fmWrite)
  for key, value in language_model.pairs:
    output_file.write($value & " " & key & "\n")
