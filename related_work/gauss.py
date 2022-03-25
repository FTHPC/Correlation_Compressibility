#!/usr/bin/env python

import numpy as np
from scipy.stats import norm
import sys
#from statistics import mode

data1 = []
with open(sys.argv[1]) as f:
    for line in f:
        data1.append(int(line))

print('data len', len(data1))

print(len(set(data1)))

dic = dict()
for i in data1:
    if i not in dic:
        dic[i] = 1
    else:
        dic[i] += 1

print(len(dic))

if len(dic) < 100:
    for i in sorted(list(dic.items()), key=lambda x: (-x[1], x[0])):
        print(i, 1.0 * i[1] / len(data1))


singular = 0
for i in dic:
    if dic[i] == 1:
        singular += 1

dup = 0
for i in dic:
    if dic[i] == 2:
        dup += 1

print('singular rate', singular * 1.0 / len(data1))
print('singular rate prediction node #', singular * 1.0 / len(data1) * int(sys.argv[2]))


print('geometric progression')
r1 = singular * 1.0 / len(data1)
r2 = dup * 1.0 / len(data1)
print('r1, r2', r1, r2)
est = len(dic) + len(data1) * (1 - pow(r1-r2, 99)/(1-r1+r2))
print('est', est)


#mid = 0
#for i in data:
#    if i == 10000:
#        mid += 1
#
#print mid
#
#for i in range(100):
#    data.remove(10000)
#
#print 'data len', len(data)

# gaussian distribution model based on samples
mu, std = norm.fit(data1)    
print('center, std fit', mu, std)
#print 'center point', mode(data1)
mu, std = np.mean(data1), np.std(data1)
print('mu, std', mu, std)


# use the 'mu' and 'std' parameters, and the size specified in arg2 to generate data and use the generated data to 
# build the another gauss model to verify the accuracy of the derived 'mu' and 'std' parameters  
data = np.random.normal(loc=mu, scale=std, size=int(sys.argv[2]))
#print data
mu, std = norm.fit(data)    
print(mu, std)

s = set()
for i in data:
    if int(i) in s:
        continue
    else:
        s.add(int(i))

print('NodeCnt', max(len(s), len(set(data1))+1))


# the below commented code is used to estimate the 'NodeCnt'
# sigma is related to 'QuantIntv'

#mu, sigma = 10000, 438
#sample = 9700 * 4
#gaussVal = np.random.normal(mu, sigma, sample)
#s = set()
#
#for i in gaussVal:
#    if int(i) in s:
#        continue
#    else:
#        s.add(int(i))
#
#print len(s)

