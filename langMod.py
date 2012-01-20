#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import division
'''
Created on Nov 17, 2011

@author: hernani
'''
"Based upon PCL3 material (Rico Sennrich)"
from collections import defaultdict
from operator import itemgetter
import math 
import cPickle as cpickle
import sys

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
    def __init__(self,order=3,isWordBased=False):
        self.order = order
        self.isWordBased = isWordBased
        self.langModels = {}
        
    def train(self,lang,train_file):
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
        self.lm, self.total  = self.train(train_file)

    def train(self, train_file):
        
        f = open(train_file,'r')
        freqs = defaultdict(lambda: defaultdict(int))
        
        for line in f:
            tokens = line.rstrip().split()
            for history, word in generate_ngrams(tokens, self.order-1,self.isWordBased):
                freqs[tuple(history)][word] += 1 # lists cannot be key, but tuples can
                
	total = sum(freqs[history].values())
        lm = self.normalize(freqs)
        return lm, total
        
        
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
		l += -math.log(sys.float_info[3]) # Verwende tiefste W'keit, wenn nicht gefunden
        return l
            
if __name__ == "__main__":

	timeRanges = [ "1600_1650", "1650_1700", "1700_1750", "1750_1800", "1800_1850", "1850_1900", "1900_2010"]
	gramTypes = ["Z"] # Z = symbol-based (Z) and word-based (W)
	gramOrders = range(2,4) # for n-gram order 1-6
        setNumbers = range(0,2) # defaults to 10-fold cross-validation

	if (len(sys.argv) > 1): 
		for setNumber in setNumbers:
			for gramType in gramTypes:
				isWordBased = False
				if gramType == "W":
					isWordBased = True
				for gramOrder in gramOrders:
					print "-"*72
					mlm = MLM(gramOrder,isWordBased)
					langModelsFileName = "langModels"+"-set"+str(setNumber)+gramType+str(gramOrder)+".pyObj"
					for timeRange in timeRanges:
						print "Creating language model (set no., n-gram-Type, n-gram-order, time range): " + str(setNumber) + " " + gramType + " " + str(gramOrder) + " " + timeRange
						corpusFileName = "train_"+str(setNumber)+"."+timeRange
						mlm.train(timeRange, corpusFileName)
					print "-- Writing language model in file (set no., n-gram-Type, n-gram-Order, no of time ranges): " + str(setNumber) + " " + gramType + " " + str(gramOrder) + " " + str(len(timeRanges))
					langModelsFile = open(langModelsFileName,"w")
					cpickle.dump(mlm,langModelsFile,-1)
					langModelsFile.close()
					print "---- written"
	else:
    	# Hier wird das Sprachmodell aus einer Datei genutzt; Geschwindigkeit++
		fileNamePrefix = "test_"
		for setNumber in setNumbers:
			for gramType in gramTypes:
				for gramOrder in gramOrders:
					print 72*"-"
					langModelsFileName = "langModels"+"-set"+str(setNumber)+gramType+str(gramOrder)+".pyObj"
					langModelsFile = open(langModelsFileName,"r")
					print "Loading file: " + langModelsFileName
					mlm = cpickle.load(langModelsFile)
					langModelsFile.close()
					for yb in timeRanges:
						fileName = fileNamePrefix+str(setNumber)+"."+yb
						testFile = open(fileName,"r")
						print(yb+": Accuracy (set no., gram type, gram order): " + str(setNumber) + " " + gramType + " " + str(gramOrder))
						print(accuracy(yb,fileName,mlm))
						testFile.close()
"""
# Testsatz
sentence_de = "So gewiß es ist, daß sich die protestantischen Land- und Dorfpfarrer ehedessen in dem besten Wohlstande ihres Hauswesens befunden haben, eben so unwidersprechlich ist es im Gegentheil, daß die meisten dieser Herren gegenwärtig von ihrer Besoldung und mit ihren Einkünften die nothdürftigen Ausgaben nicht mehr bestreiten können."

print(sentence_de)
print(mlm.lang(sentence_de))
"""
