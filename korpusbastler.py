#!/usr/bin/python3
# -*- coding: utf-8 -*-
# NLP für historische Dokumente, HS2011
# Reto Baumgartner
# ONLY USE PYTHON 3.2+ -- FOR YOUR OWN SAFETY (MENTALLY)

from xml.etree import cElementTree as ET
from collections import defaultdict
import re
import glob, os

tei = ".//{http://www.tei-c.org/ns/1.0}TEI"                 #tei
teiHeader = ".//{http://www.tei-c.org/ns/1.0}teiHeader"     #tei/teiheader
profileDesc = ".//{http://www.tei-c.org/ns/1.0}profileDesc" #tei/teiheader/profileDesc
textClass = ".//{http://www.tei-c.org/ns/1.0}textClass"     #tei/teiheader/profileDesc/textClass
keywords = ".//{http://www.tei-c.org/ns/1.0}keywords"       #tei/teiheader/profileDesc/textClass/keywords
term = ".//{http://www.tei-c.org/ns/1.0}term"               #tei/teiheader/profileDesc/textClass/keywords/term
creation = ".//{http://www.tei-c.org/ns/1.0}creation"       #tei/teiheader/profileDesc/creation   
date = ".//{http://www.tei-c.org/ns/1.0}date"               #tei/teiheader/profileDesc/creation/date
text = ".//{http://www.tei-c.org/ns/1.0}text"               #tei/text

usablegenres = ["prose", "drama"]

# Gibt das Jahr eines Werkes (ein TEI) zurück, bzw. die Mitte der möglichen Erscheinungszeit
def getYear(theTei):
    theTeiHeader = theTei.find(teiHeader)
    theProfileDesc = theTeiHeader.find(profileDesc)
    theCreation = theProfileDesc.find(creation)
    theDate = theCreation.find(date)
    notBefore = theDate.get("notBefore")
    notAfter = theDate.get("notAfter")
    y = (int(notBefore) + int(notAfter)) / 2
    return y

# Gibt das Literaturgenre eines Werkes (ein TEI) zurück
def getGenre(theTei):
    theTeiHeader = theTei.find(teiHeader)
    theProfileDesc = theTeiHeader.find(profileDesc)
    theTextClass = theProfileDesc.find(textClass)  
    theKeywords = theTextClass.find(keywords)
    theTerm = theKeywords.find(term)
    g = theTerm.text
    return g

# Extrahiert den Text eines Werkes (ein TEI) auf allen tieferen Ebenen
def extractText(theTei):
    theText = theTei.find(text)
    ts = theText.itertext()
    t = "\n".join([e.strip() for e in ts])
    t = re.sub(r'\n\n+', '\n', t)
    #t = "platzhalter"
    return t

# Schreibt den Inhalt eines Werkes (ein TEI) in das entsprechende Korpus
def writeIntoCorpus(year, genre, corpus):
        if year < 1600:
            pass
        elif 1600 <= year and year < 1650:
            t1600_1650.write(corpus)
        elif 1650 <= year and year < 1700:
            t1650_1700.write(corpus)
        elif 1700 <= year and year < 1750:
            t1700_1750.write(corpus)
        elif 1750 <= year and year < 1800:
            t1750_1800.write(corpus)
        elif 1800 <= year and year < 1850:
            t1800_1850.write(corpus)
        elif 1850 <= year and year < 1900:
            t1850_1900.write(corpus)
            #unpickled_corpus = pickle.load(corpus)
#pickle.dump(unpickled_corpus,t1850_1900)
        else:
            t1900_2010.write(corpus)
        
# Verarbeitet die verschiedenen Werke (TEI-Subbäume) in einer XML-Datei
def processFile(file):
    doc = ET.parse(file)
    alltei = doc.findall(tei)
    for theTei in alltei:
        try:
            year = getYear(theTei)
            genre = getGenre(theTei)
            if genre in usablegenres:
                corpus = extractText(theTei)
                writeIntoCorpus(year, genre, corpus)
        except:
            pass
    
    
# Epochenspezifische Korpora:
t1600_1650 = open('rawcorp.1600_1650','a')
t1650_1700 = open('rawcorp.1650_1700','a')
t1700_1750 = open('rawcorp.1700_1750','a')
t1750_1800 = open('rawcorp.1750_1800','a')
t1800_1850 = open('rawcorp.1800_1850','a')
t1850_1900 = open('rawcorp.1850_1900','a')
t1900_2010 = open('rawcorp.1900_2010','a')

ROOT = "../daten/Digitale-Bibliothek-Literatur" # zu setzen!!!

for filename in glob.glob("%s/*.xml" % ROOT):
    print(filename)
    processFile(filename)

#processFile(ROOT+"Literatur-Heyse,-Paul.xml")

t1600_1650.close()
t1650_1700.close()
t1700_1750.close()
t1750_1800.close()
t1800_1850.close()
t1850_1900.close()
t1900_2010.close()
