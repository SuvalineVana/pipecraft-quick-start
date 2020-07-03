#!/usr/bin/python


from sys import argv

script, filename = argv

from glob import glob
 
reader1 = open('mothur.list', 'rb')
filenam = glob(filename)


d={}
N= []
M = []
seq = ''
K=''
l=''
n=0
for groups in filenam:
        F = open(groups)
        for row in F:
           print row
           row=row.rstrip()           
           K=row.split()[0]
           d[K]=row.split()[1]
        


with open('Final.groups', 'w') as output:
  with open('group_problematics.txt', 'w') as output2:     
   for j in reader1:
      for k in j.split(","):
         k=k.split()
         for i in k:
            n+=1

            if i in d:
               
               output.write(str(i)+'\t'+ str(d[i])+'\n')
            else:
               output2.write(str(i)+'\n')    


print n

