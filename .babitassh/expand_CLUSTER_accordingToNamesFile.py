#!/usr/bin/python

import re
import os

#input names file
fail = open("derep_no_singletones.names", "r")
names = []
for line in fail:
	names = names + [line.strip().split("\t")]
fail.close()

#input cluster file
fail2 = open("Dereplicate_Clusters.cluster", "r")
cluster = []
for line in fail2:
	cluster = cluster + [line.strip().split("\t")]
fail.close()


### expand clusters based on names file
redundant_cluster = []
l = len(names)
i = 0
while i < l:
	for el in names:
		matcher = el[0]
		
		j = 0
		for el in cluster:
			result = re.findall('\\b'+matcher+'\\b', str(cluster[j]), flags=re.IGNORECASE) #find exact match
			if len(result) > 0: #if match found then expand corresponding cluster
				cluster[j] += names[i][1:]
				
				if cluster[j] not in redundant_cluster: #prevent writing duplicate clusters
					redundant_cluster.append("\n")
					redundant_cluster.append(cluster[j])
			j += 1
		i += 1


#Write also cluster that were not expanded
for el in cluster:
	matcher = el[0]
	result = re.findall('\\b'+matcher+'\\b', str(redundant_cluster), flags=re.IGNORECASE)
	if len(result) <= 0:
		redundant_cluster.append("\n")
		redundant_cluster.append(el)

#convert list to string
finalcluster_str = "".join(str(x) for x in redundant_cluster)

#delete some characters and format as cluster file
finalcluster_str = finalcluster_str.replace("[", "")
finalcluster_str = finalcluster_str.replace("]", "")
finalcluster_str = finalcluster_str.replace("\'", "")
finalcluster_str = finalcluster_str.replace(", ", "\t")

#first line is empty, delete it 
finalcluster_str = os.linesep.join([s for s in finalcluster_str.splitlines() if s]) 

#Write output
failout = open("Swarm_cluster.cluster", "w")
failout.write(str(finalcluster_str))
failout.close()