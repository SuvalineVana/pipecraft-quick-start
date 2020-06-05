#!/usr/bin/python

import os

fail = open('Clusters.uc', 'r') 
read = []
for rida in fail:
        read = read + [rida.strip("\n").split("\t")]
fail.close()

H = []
a = {} 
for i in read:
    if i[0]=="H":
        H += [i]

    elif i[0]=="C":
        a[i[1]]= i[8]+"\t" 



for i in range(len(a)):
    i = str(i)
    for j in H:
        if i==j[1]:
            a[i]+=(j[8]+ "\t") 


b = []
for i in a:
    b += [a[i].strip("\t").split("\t")]
    

sorted_b = []
while len(b)>0:
    sorted_b += [max(b, key=len)]
    b.remove(max(b, key=len))
    

fail = open('Converted_Clusters.cluster', 'w') 
for i in sorted_b:
    for j in range(len(i)):
        fail.write(str(i[j])+"\t") 
    fail.write("\n") 
fail.close()
