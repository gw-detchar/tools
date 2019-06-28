#!/usr/bin/env python
usage       = "python LockingStatus.py"
description = "Checking KAGRA Locking status"
author      = "Shoichi Oshino, oshino@icrr.u-tokyo.ac.jp"

#-----------------------------------------------------------------------------#
import time
import sys
import os
import subprocess
from datetime import datetime, timedelta
from pytz import timezone

from gwpy.timeseries import TimeSeries
from gwpy.timeseries import StateTimeSeries
from gwpy.segments import DataQualityFlag

from glue.lal import Cache

import getpass
import glob
#------------------------------------------------------------

start_time = time.time()

#------------------------------------------------------------
# Set enviroment

if getpass.getuser() == "controls":
    SEGMENT_DIR = "/users/DET/Segments/"
else:
    SEGMENT_DIR = "/home/detchar/segment/UTC/"



#------------------------------------------------------------

def GetFilelist(gpsstart,gpsend):
    '''
    Kozapy Library
    This function gives full data frame file list.
    '''
    gpsstart=str(int(float(gpsstart)))
    gpsend=str(int(float(gpsend)))

    sources = []

    for i in range(int(gpsstart[0:5]),int(gpsend[0:5])+1):
        dir = '/data/full/' + str(i) + '/*'
        source = glob.glob(dir)
        sources.extend(source)

    sources.sort()

    removelist = []

    for x in sources:
        if int(x[24:34])<(int(gpsstart)-31):
            removelist.append(x)
        if int(x[24:34])>int(gpsend):
            removelist.append(x)

    for y in removelist:
        sources.remove(y)

    return sources

def mkSegment(gst, get, utc_date) :

    ch1 = 'K1:GRD-PMC_OK'
    ch2 = 'K1:GRD-IMC_STATE_N'
    ch3 = 'K1:GRD-LSC_LOCK_STATE_N'

    file_path1 = SEGMENT_DIR + 'SegmentList_UTC_' + utc_date + '.txt'
    file_path2 = SEGMENT_DIR + 'SegmentList_IMC_UTC_' + utc_date + '.txt'
    file_path3 = SEGMENT_DIR + 'SegmentList_LSC_UTC_' + utc_date + '.txt'
    if getpass.getuser() == "controls":
        gwf_cache = '/users/DET/Cache/latest.cache'
        with open(gwf_cache, 'r') as fobj:
            cache = Cache.fromfile(fobj)
    else:
        cache = GetFilelist(gst, get)

    #------------------------------------------------------------

    #print('Reading {0} timeseries data...'.format(date))
    channeldata1 = TimeSeries.read(cache, ch1, start=gst, end=get, format='gwf.lalframe', gap='pad')
    channeldata2 = TimeSeries.read(cache, ch2, start=gst, end=get, format='gwf.lalframe', gap='pad')
    channeldata3 = TimeSeries.read(cache, ch3, start=gst, end=get, format='gwf.lalframe', gap='pad')

    #------------------------------------------------------------
    #print('Checking PMC Locking status for K1...')

    highseismic1 = channeldata1 == 1
    highseismic2 = channeldata2 >= 134
    highseismic3 = channeldata3 >= 20

    segment1 = highseismic1.to_dqflag(round=True)
    with open(file_path1, mode='w') as f:
        for seg in segment1.active :
            f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))

    segment2 = highseismic2.to_dqflag(round=True)
    with open(file_path2, mode='w') as f:
        for seg in segment2.active :
            f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))

    segment3 = highseismic3.to_dqflag(round=True)
    with open(file_path3, mode='w') as f:
        for seg in segment3.active :
            f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))

#------------------------------------------------------------


utc_date = (datetime.now() + timedelta(days=-1)).strftime("%Y-%m-%d")
start_utc_time = utc_date + ' 09:00:00'

cmd = 'gpstime ' + start_utc_time + ' | awk \'NR == 3 {print $2}\''
start_gps_time = int (subprocess.check_output(cmd, shell = True) )
end_gps_time = int(start_gps_time) + 86400

try :
    mkSegment(start_gps_time, end_gps_time, utc_date)
    #print('    DQF segment file saved')
except ValueError :
    print('    Cannot append discontiguous TimeSeries')
    pass
#------------------------------------------------------------

print('\n--- Total {0}h {1}m ---'.format( int((time.time()-start_time)/3600), int(( (time.time()-start_time)/3600 - int((time.time()-start_time)/3600) )*60) ))
