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
    #SEGMENT_DIR = "/home/detchar/segment/UTC/"
    SEGMENT_DIR = "/home/detchar/Segments/"
    

test = False
if test:
    if getpass.getuser() == "controls":
        SEGMENT_DIR = "/users/DET/tools/Segments/Script/tmp/"
    else:
        SEGMENT_DIR = "/home/detchar/git/kagra-detchar/tools/Segments/Script/tmp/"


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

#keys = ['ScienceMode','NonScienceMode','IMC','FPMILocked','Silent','SilentFPMILocked']
#keys = ['K1-GRD_SCIENCE_MODE','K1-GRD_UNLOCKED','K1-GRD_LOCKED','K1-GRD_PEM_EARTHQUAKE']
keys = ['K1-GRD_LOCK_STATE_N_EQ_1000']
#utc_date = (datetime.now() + timedelta(hours=-9,minutes=-15)).strftime("%Y-%m-%d")
utc_date = "2020-04-15"
year = (datetime.now() + timedelta(hours=-9)).strftime("%Y")
filepath_txt = {}
filepath_xml = {}
    
if getpass.getuser() == "controls":
    tmp_DIR = "/users/DET/tools/Segments/Script/Partial/"
    
else:
    tmp_DIR = "/home/detchar/git/kagra-detchar/tools/Segments/Script/Partial/"

for key in keys:
    filepath_txt[key] = tmp_DIR +key+'_SEGMENT_UTC_' + utc_date + '.txt'
    filepath_xml[key] = tmp_DIR +key+'_SEGMENT_UTC_' + utc_date + '.xml'

def mkSegment(gst, get, utc_date, txt=True) :

    chGRDLOCK = 'K1:GRD-LSC_LOCK_STATE_N'
    #chGRDLSC = 'K1:GRD-IFO_STATE_N'
    #chGRDEQ = 'K1:GRD-PEM_EARTHQUAKE_STATE_N'
    #channels = [chGRDLSC,chGRDEQ]
    channels = [chGRDLOCK]
    
    if getpass.getuser() == "controls":
        #gwf_cache = '/users/DET/Cache/latest.cache'
        gwf_cache = '/users/DET/Cache/O3/latest.cache'
        with open(gwf_cache, 'r') as fobj:
            cache = Cache.fromfile(fobj)
    else:
        # add 1sec margin for locked segments contract.
        cache = GetFilelist(gst-1, get+1)

    #------------------------------------------------------------

    #print('Reading {0} timeseries data...'.format(date))
    # add 1sec margin for locked segments contract.
    channeldata = TimeSeriesDict.read(cache, channels, start=gst-1, end=get+1, format='gwf.lalframe', gap='pad')
    channeldataGRDLSC = channeldata[chGRDLSC]
    channeldataGRDEQ = channeldata[chGRDEQ]

    #------------------------------------------------------------
    #print('Checking PMC Locking status for K1...')

    sv={}
    #sv['K1-GRD_SCIENCE_MODE'] = channeldataGRDLSC == 1000
    sv['K1-GRD_LOCK_STATE_N_EQ_1000'] = channeldataGRDLOCK == 1000 

    # Unlocked will be defined by inverse of locked segments.
    #sv['K1-GRD_UNLOCKED'] = channeldataGRDLSC < 100
    
    #sv['K1-GRD_LOCKED'] = channeldataGRDLSC >= 100 
    #sv['K1-GRD_PEM_EARTHQUAKE'] = channeldataGRDEQ == 1000

    dqflag = {}
    for key in keys:
        if key == 'K1-GRD_UNLOCKED':
            continue
        dqflag[key] = sv[key].to_dqflag(round=True)

    # To omit fraction. round=True option is inclusive in default.         
    #dqflag['K1-GRD_SCIENCE_MODE'].active = dqflag['K1-GRD_SCIENCE_MODE'].active.contract(1.0)
    dqflag['K1-GRD_LOCK_STATE_N_EQ_1000'].active = dqflag['K1-GRD_LOCK_STATE_N_EQ_1000'].active.contract(1.0)
    #dqflag['K1-GRD_LOCKED'].active = dqflag['K1-GRD_LOCKED'].active.contract(1.0)

    #dqflag['K1-GRD_UNLOCKED'] = ~dqflag['K1-GRD_LOCKED']
    #dqflag['K1-GRD_UNLOCKED'].name = "K1:GRD-IFO_STATE_N < 100"
    
    #dqflag['K1-GRD_SCIENCE_MODE'].description = "Observation mode. K1:GRD-IFO_STATE_N == 1000"
    #dqflag['K1-GRD_UNLOCKED'].description = "Interferometer is not locked. K1:GRD-IFO_STATE_N < 100"
    #dqflag['K1-GRD_LOCKED'].description = "Interferometer is locked. K1:GRD-IFO_STATE_N >= 100"
    #dqflag['K1-GRD_LOCKED'].name = "K1:GRD-LSC_LOCK_STATE_N >= 300 & K1:GRD-LSC_LOCK_STATE_N <= 1000"

    for key in keys:

        # added 1sec margin for locked segments contract is removed.
        margin = DataQualityFlag(known=[(gst,get)],active=[(gst-1,gst),(get,get+1)])
        dqflag[key] -= margin

        # write down 15 min segments. 
        if txt:
            with open(filepath_txt[key], mode='w') as f:
                for seg in dqflag[key].active :
                    f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
        
        # if accumulated file exists, it is added. 
        if os.path.exists(filepath_xml[key]):
            tmp = DataQualityFlag.read(filepath_xml[key])        
            dqflag[key] = dqflag[key] + tmp

        dqflag[key].write(filepath_xml[key],overwrite=True)

#------------------------------------------------------------

#utc_date = (datetime.now() + timedelta(days=-1)).strftime("%Y-%m-%d")


#if not os.path.exists(SEGMENT_DIR+'/K1-GRD_SCIENCE_MODE/'+year):
#    for key in keys:
for key in keys:
    if not os.path.exists(SEGMENT_DIR+'/'+key+'/'+year):
        os.makedirs(SEGMENT_DIR+'/'+key+'/'+year)

#if not os.path.exists(SEGMENT_DIR+'/Partial/'+year):
#    os.makedirs(SEGMENT_DIR+'/Partial/'+year)

# Set time every 15 min. 
if getpass.getuser() == "controls":
    end_gps_time = int (float(subprocess.check_output('/users/DET/tools/Segments/Script/periodictime.sh', shell = True)) )
else:
    end_gps_time = int (float(subprocess.check_output('/home/detchar/git/kagra-detchar/tools/Segments/Script/periodictime.sh', shell = True)) )
    
start_gps_time = int(end_gps_time) - 900

start_gps_time = 1270944018 
end_gps_time = 1271030418

# For locked segment contract, take 1sec margin.
#end_gps_time = end_gps_time + 1

#start_gps_time = start_gps_time - 1

try :
    mkSegment(start_gps_time, end_gps_time, utc_date)
    #print('    DQF segment file saved')
except ValueError :
    print('    Cannot append discontiguous TimeSeries')
    pass
#------------------------------------------------------------

print('\n--- Total {0}h {1}m ---'.format( int((time.time()-start_time)/3600), int(( (time.time()-start_time)/3600 - int((time.time()-start_time)/3600) )*60) ))


# whole day file should be produced at the end of the day.
end_time = (datetime.now() + timedelta(hours=-9)).strftime("%Y-%m-%d")
if utc_date != end_time:
    print("date changed.")
    for key in keys:

        tmp = DataQualityFlag.read(filepath_xml[key])
        tmp.write(SEGMENT_DIR +key+'/'+year+'/'+key+'_SEGMENT_UTC_' + utc_date + '.xml',overwrite=True)

        # Check if missing part exist
        day = DataQualityFlag(known=[(end_gps_time-86400,end_gps_time)],active=[(end_gps_time-86400,end_gps_time)],name=key)
        missing = day.known - tmp.known

        for seg in missing:
            mkSegment(seg[0], seg[1], utc_date, txt=False)
        tmp = DataQualityFlag.read(filepath_xml[key])

        tmp.write(SEGMENT_DIR +key+'/'+year+'/'+key+'_SEGMENT_UTC_' + utc_date + '.xml',overwrite=True)   
        with open(SEGMENT_DIR +key+'/'+year+'/'+key+'_SEGMENT_UTC_' + utc_date + '.txt', mode='w') as f:
            for seg in tmp.active :
                f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
        os.remove(filepath_xml[key])
        os.remove(filepath_txt[key])