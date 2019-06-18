#!/usr/bin/env python2

from os import listdir
from numpy import arange
from optparse import OptionParser

basedir = "/frame0/"
DT      = 100000
dt      = 32

parser=OptionParser(usage="",version="")
#parser.add_option("-c", "--cache-file", action="store", type="string", default=basedir+'K-K1_C.iKAGRA.cache', help="output LAL cache file path")
parser.add_option("-c", "--cache-path", action="store", type="string", default='.', help="cache directory which will be stored.")
parser.add_option("-i", "--ifo", action="store", type="string", default='K1', help="Observatory, K1, L1, ...")
parser.add_option("-s", "--gps-start-time", action="store", type="float", default=0., help="GPS start time")
parser.add_option("-e", "--gps-end-time", action="store", type="float", default=9999999999., help="GPS end time")

(opts,files)=parser.parse_args()

#cachefile = opts.cache_file
site=opts.ifo[0]
cachePath=opts.cache_path
startTimeDatafind=int(opts.gps_start_time)
endTimeDatafind=int(opts.gps_end_time)
cachefile = '{0}/{1}-{2}-{3}.cache'.format(cachePath,site,startTimeDatafind,endTimeDatafind)

ls_out = []

d = sorted(listdir(basedir+'full'))
for i in d:
    try: fivedigits=int(i)
    except: continue

    start = fivedigits * DT
    stop  = start + DT
    if int(i) < int(opts.gps_start_time // DT):
        continue
    elif int(i) > int(opts.gps_end_time // DT):
        break
    if int(i) == int(opts.gps_start_time // DT):
        a = arange(start, stop, dt)
        start = a[a>opts.gps_start_time-dt][0]
    if int(i) == int(opts.gps_end_time // DT):
        a = arange(start, stop, dt)
        stop = a[a<opts.gps_end_time][-1]
    l = sorted(listdir(basedir+'full/'+i))
    for j in l:
        if (j[0] == '.') or (j[-3:] != 'gwf'):
            continue
        if int(j.split('-')[-2]) < start:
            continue
        elif int(j.split('-')[-2]) > stop:
            break
        ls_out.append(' '.join(j.split('.')[0].split('-'))+' file://localhost'+basedir+'full/'+i+'/'+j)

f = open(cachefile, 'w')
f.write('\n'.join(ls_out)+'\n')
f.close()
