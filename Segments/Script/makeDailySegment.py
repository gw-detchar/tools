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
from gwpy.timeseries import TimeSeriesDict
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
    ch4 = 'K1:GRD-LSC_LOCK_STATE_N'
    ch5 = 'K1:MIF-WE_ARE_DOING_NOTHING'
    channels = [ch1,ch2,ch3,ch4,ch5]
    file_path1 = SEGMENT_DIR + 'SegmentList_PMC_UTC_' + utc_date + '.txt'
    file_path2 = SEGMENT_DIR + 'SegmentList_IMC_UTC_' + utc_date + '.txt'
    file_path3 = SEGMENT_DIR + 'SegmentList_LSC_UTC_' + utc_date + '.txt'
    file_path4 = SEGMENT_DIR + 'SegmentList_FPMI_UTC_' + utc_date + '.txt'
    file_path5 = SEGMENT_DIR + 'SegmentList_silent_UTC_' + utc_date + '.txt'
    file_path6 = SEGMENT_DIR + 'SegmentList_silentFPMI_UTC_' + utc_date + '.txt'
    file_path7 = SEGMENT_DIR + 'SegmentList_FPMI_UTC_' + utc_date + '.xml'
    if getpass.getuser() == "controls":
        gwf_cache = '/users/DET/Cache/latest.cache'
        with open(gwf_cache, 'r') as fobj:
            cache = Cache.fromfile(fobj)
    else:
        cache = GetFilelist(gst, get)

    #------------------------------------------------------------

    #print('Reading {0} timeseries data...'.format(date))

    channeldata = TimeSeriesDict.read(cache, channels, start=gst, end=get, format='gwf.lalframe', gap='pad')
    channeldata1 = channeldata[ch1]
    channeldata2 = channeldata[ch2]
    channeldata3 = channeldata[ch3]
    channeldata4 = channeldata[ch4]
    channeldata5 = channeldata[ch5]

    #------------------------------------------------------------
    #print('Checking PMC Locking status for K1...')

    highseismic1 = channeldata1 == 1
    highseismic2 = channeldata2 >= 100
    highseismic3 = channeldata3 >= 20
    highseismic4 = channeldata4 == 60
    highseismic5 = channeldata5 == 1
    
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

    segment4 = highseismic4.to_dqflag(round=True)
    with open(file_path4, mode='w') as f:
        for seg in segment4.active :
            f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))

    segment5 = highseismic5.to_dqflag(round=True)
    with open(file_path5, mode='w') as f:
        for seg in segment5.active :
            f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
            
    segment6 = segment4 & segment5
    with open(file_path6, mode='w') as f:
        for seg in segment6.active :
            f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
            
    segment7 = segment4
    with open(file_path7, mode='w') as f:
        for seg in segment7.active :
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
