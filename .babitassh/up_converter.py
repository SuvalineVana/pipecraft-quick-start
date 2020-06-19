#!/usr/bin/python

from sys import argv
script, filename, fileout = argv

fail = open(filename,'r') 

read = []
for rida in fail:
        read = read + [rida.strip("\n").split("\t")]
fail.close() 

otu = []
match = []
chimera = []
mingimuu = []

for i in read: 
    if i[1]=="otu":
        otu += [i]
    elif i[1]=="match":
        match += [i]
    elif i[1]=="chimera": 
        chimera += [i]
    else:
        mingimuu += [i]
if len(mingimuu) > 0:
    print("ERROR, NO otu/match/chimera string in 2nd COLUMN in", len(mingimuu), "line(s)")

V2ljund = []
for e in range(0, len(otu)):
    esindussekvents = [otu[e][0].split(";size=")[0]]
    for f in match:
        if f[-1]==esindussekvents[0]:
            esindussekvents += [f[0].split(";size=")[0]] 
    V2ljund += [esindussekvents]


fail = open(fileout, 'w')
for i in V2ljund:
    for j in range(len(i)):
        fail.write(str(i[j])+"\t")
    fail.write("\n")
fail.close()
