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
  var
    freqs = init_table[string, TCountTable[string]](128)
    n = 3
    hist: string
    sum: int
    language_model = init_table[string, float]
    input_file = "t" & korpus & ".txt"
    output_file = "k" & korpus
    
  for line in lines(input_file):
    for history, word in ngrams(line, n):
      hist = history.join(join_char) # join hack
      if not freqs.has_key(hist):
        freqs[hist] = init_count_table[string](32)
      freqs.mget(hist).inc(word)
  for history, counts in freqs.pairs():
    sum = 0
    for number in counts.values(): sum.inc(number)
    for word, count in counts.pairs():
      language_model[history & join_char & word] = count/sum
  for key, value in language_model:
    output_file.write(value & " " & key & "\n")
