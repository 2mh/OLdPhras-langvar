# -*- coding: utf-8 -*-
from __future__ import division
'''
Created on Nov 17, 2011

@author: hernani
'''
"Based upon the reference solution of exec. 6; to avoid ugliness of the my own one"
from collections import defaultdict
from operator import itemgetter
import math # Aufg 1.2
import cPickle as cpickle

#traverse through an iterable, return both the current element and a history of length n-1
def generate_ngrams(iterable, k, isWordBased):
    
    history = [None]*(k) # we represent our history (which has length k) as a list.
    if(isWordBased): # word-based n-grams
        try:
            iterable = iterable.split() # In case of a string
        except AttributeError:
            pass # In case of a list
        for word in iterable:
            yield history, word
            # create new history (drop first element and add current one)
            history = history[1:] + [word]
    else: # symbol-based n-grams
        for word in iterable:
            for symbol in word:
                yield history, symbol
                history = history[1:] + [symbol]
                
def accuracy(lang,fileName,mlm):
    fileHandler = open(fileName,"r")
    noOfTrue = 0
    noOfLines = 0
    
    for line in fileHandler:
        noOfLines = noOfLines + 1
        if (mlm.lang(line) == lang):
            noOfTrue = noOfTrue + 1
    
    fileHandler.close()
    return noOfTrue / noOfLines

class MLM():
    def __init__(self,lang,train_file,order=3,isWordBased=False):
        self.order = order
        self.isWordBased = isWordBased
        self.langModels = {}
        self.langModels[lang] = LM(train_file,self.order,self.isWordBased)
        
    def train(self, lang,train_file):
        self.langModels[lang] = LM(train_file,self.order,self.isWordBased)
        
    # Return language with smallest -log for a given sentence, e. g. "de"
    def lang(self,sentence):
        scorePerLang = {}
        for pair in self.langModels.items():
            scorePerLang[pair[0]] = pair[1].score(sentence)
        
        scorePerLang = sorted(scorePerLang.items(), key=itemgetter(1), reverse=False)
        return scorePerLang[0][0]

class LM():
    def __init__(self, train_file,order=3,isWordBased=False):
        self.order = order
        self.isWordBased = isWordBased
        self.lm  = self.train(train_file)

    def train(self, train_file):
        
        f = open(train_file,'r')
        freqs = defaultdict(lambda: defaultdict(int))
        
        for line in f:
            tokens = line.rstrip().split()
            for history, word in generate_ngrams(tokens, self.order-1,self.isWordBased):
                freqs[tuple(history)][word] += 1 # lists cannot be key, but tuples can
                
        lm = self.normalize(freqs)
        return lm
        
        
    #get conditional probabilities from frequency counts. Is called in train(), so you don't have to call it yourself.
    def normalize(self, freqs):
        
        lm = defaultdict(dict)
        for history in freqs:
            total = sum(freqs[history].values())
            for word in freqs[history]:
                # Aufg. 1.2
                lm[history][word] = -math.log(freqs[history][word] / total,2)
                
        return lm
        

    # get probability of a sentence
    # the loop/history mechanics are the same as in training. only difference:
    # instead of incrementing frequency counts, we look them up in language model and multiply
    def score(self, sentence):
        
        l = -math.log(1,2)
        tokens = sentence.split()
        for history,word in generate_ngrams(tokens, self.order-1,self.isWordBased):
            try:
                l += self.lm[tuple(history)][word]
            except KeyError:
                l += -math.log(0.00000001)
            
        return l
        
            
if __name__ == "__main__":

    m1600b1650 = "1600-1650"
    m1650b1700 = "1650-1700"
    m1700b1750 = "1700-1750"
    m1750b1800 = "1750-1800"
    m1800b1850 = "1800-1850"
    m1850b1900 = "1850-1900"
    
    """
    # Hiermit wird das Object-File kreiert, das die Sprachmodelle enthält.

    mlm = MLM(m1600b1650,"t1600_1650.txt")
    print m1600b1650 + " finished"
    mlm.train(m1650b1700,"t1650_1700.txt")
    print m1650b1700 + " finished"
    mlm.train(m1700b1750,"t1700_1750.txt")
    print m1700b1750 + " finished"
    mlm.train(m1750b1800,"t1750_1800.txt")
    print m1750b1800 + " finished"
    mlm.train(m1800b1850,"t1800_1850.txt")
    print m1800b1850 + " finished"
    mlm.train(m1850b1900,"t1850_1900.txt")
    print m1850b1900 + " finished"

    langModelsFile = open("langModels.pyObj","w")
    cpickle.dump(mlm,langModelsFile)
    langModelsFile.close()
    """

    # Hier wird das Sprachmodell aus einer Datei genutzt; Geschwindigkeit++
    langModelsFile = open("langModels.pyObj","r")
    mlm = cpickle.load(langModelsFile)
    langModelsFile.close()


    """
    # Testsatz
    sentence_de = "So gewiß es ist, daß sich die protestantischen Land- und Dorfpfarrer ehedessen in dem besten Wohlstande ihres Hauswesens befunden haben, eben so unwidersprechlich ist es im Gegentheil, daß die meisten dieser Herren gegenwärtig von ihrer Besoldung und mit ihren Einkünften die nothdürftigen Ausgaben nicht mehr bestreiten können."

    print(sentence_de)
    print(mlm.lang(sentence_de))
    """

   
    e100 = open("e100-1600_1650.txt","r")
    for s in e100:
	print mlm.lang(s)
    print("Accuracy, w/ symbol-n-gram order: 3") 
    print(accuracy(m1600b1650,"e100-1600_1650.txt",mlm))
    e100.close()
    
"""
    # symbol-based-n-grams
    print("Accuracy, w/ symbol-n-gram order: 3") 
    print(accuracy("de","TextBerg100DE.txt",mlm))
    print(accuracy("fr","TextBerg100FR.txt",mlm))
    
    mlm = MLM("de","TextBerg5000DE.txt",4)
    mlm.train("fr","TextBerg5000FR.txt")
    print("Accuracy, w/ symbol-n-gram order: 4") 
    print(accuracy("de","TextBerg100DE.txt",mlm))
    print(accuracy("fr","TextBerg100FR.txt",mlm))
    
    mlm = MLM("de","TextBerg5000DE.txt",5)
    mlm.train("fr","TextBerg5000FR.txt")
    print("Accuracy, w/ symbol-n-gram order: 5") 
    print(accuracy("de","TextBerg100DE.txt",mlm))
    print(accuracy("fr","TextBerg100FR.txt",mlm))
    
    mlm = MLM("de","TextBerg5000DE.txt",2)
    mlm.train("fr","TextBerg5000FR.txt")
    print("Accuracy, w/ symbol-n-gram order: 2") 
    print(accuracy("de","TextBerg100DE.txt",mlm))
    print(accuracy("fr","TextBerg100FR.txt",mlm))
    
    mlm = MLM("de","TextBerg5000DE.txt",1)
    mlm.train("fr","TextBerg5000FR.txt")
    print("Accuracy, w/ symbol-n-gram order: 1") 
    print(accuracy("de","TextBerg100DE.txt",mlm))
    print(accuracy("fr","TextBerg100FR.txt",mlm))
    
    # Word-based n-grams
    
    mlm = MLM("de","TextBerg5000DE.txt",True)
    mlm.train("fr","TextBerg5000FR.txt")
    print("Accuracy, w/ word-n-gram order: 3") 
    print(accuracy("de","TextBerg100DE.txt",mlm))
    print(accuracy("fr","TextBerg100FR.txt",mlm))
    
    mlm = MLM("de","TextBerg5000DE.txt",4,True)
    mlm.train("fr","TextBerg5000FR.txt")
    print("Accuracy, w/ word-n-gram order: 4") 
    print(accuracy("de","TextBerg100DE.txt",mlm))
    print(accuracy("fr","TextBerg100FR.txt",mlm))
    
    mlm = MLM("de","TextBerg5000DE.txt",5,True)
    mlm.train("fr","TextBerg5000FR.txt")
    print("Accuracy, w/ word-n-gram order: 5") 
    print(accuracy("de","TextBerg100DE.txt",mlm))
    print(accuracy("fr","TextBerg100FR.txt",mlm))
    
    mlm = MLM("de","TextBerg5000DE.txt",2,True)
    mlm.train("fr","TextBerg5000FR.txt")
    print("Accuracy, w/ word-n-gram order: 2") 
    print(accuracy("de","TextBerg100DE.txt",mlm))
    print(accuracy("fr","TextBerg100FR.txt",mlm))
    
    mlm = MLM("de","TextBerg5000DE.txt",1,True)
    mlm.train("fr","TextBerg5000FR.txt")
    print("Accuracy, w/ word-n-gram order: 1") 
    print(accuracy("de","TextBerg100DE.txt",mlm))
    print(accuracy("fr","TextBerg100FR.txt",mlm))
"""
