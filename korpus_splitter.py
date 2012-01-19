#!/usr/bin/python3
# -*- coding: utf-8 -*-
# NLP für historische Dokumente, HS2011
# Reto Baumgartner

import sys
import glob, os

# Ordner mit Quelldateien
ROOT = "./"

# Anzahl der Korpora für Kreuzvalidierung; default: 2
corpora = 2

if (len(sys.argv) > 1):
	corpora = int(sys.argv[1])

# Zähler der Sätze
counter = 0

# Schreibt die Zeile in das Testkorpus, wenn es das x-te ist,
# sonst ins Trainingskorpus
def writeLine(line, test, train):
    global counter
    for x in range(corpora):
        if counter % corpora == x:
            test[x].write(line)
        else:
            train[x].write(line)
    counter += 1
    
# Verarbeitet eine Epochendatei
def processFile(filename):
    epoch = filename.split(".")[2]
    thisfile = open(filename, "r")
    lines = thisfile.readlines()
    thisfile.close()
    test = []
    train = []
    for x in range(corpora):
        test.append(open("test_" + str(x) + "." + epoch, "w"))
        train.append(open("train_" + str(x) + "." + epoch, "w"))
    for line in lines:
        writeLine(line, test, train)
    for x in range(corpora):
        test[x].close()
        train[x].close()

for filename in glob.glob("%s/rawcorp.*" % ROOT):
    print(filename)
    processFile(filename)
    
#print("Anzahl Sätze: " + str(counter))
