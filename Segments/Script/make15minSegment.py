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
    

test = True
if test:
    #SEGMENT_DIR = "/tmp/"
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

keys = ['ScienceMode','NonScienceMode','IMC','FPMILocked','Silent','SilentFPMILocked']
utc_date = (datetime.now() + timedelta(hours=-9,minutes=-15)).strftime("%Y-%m-%d")
year = (datetime.now() + timedelta(hours=-9)).strftime("%Y")
filepath_txt = {}
filepath_xml = {}
    
for key in keys:
    filepath_txt[key] = SEGMENT_DIR + '/Partial/'+year+'/K1-SegmentList_'+key+'_UTC_' + utc_date + '.txt'
    filepath_xml[key] = SEGMENT_DIR + '/Partial/'+year+'/K1-SegmentList_'+key+'_UTC_' + utc_date + '.xml'

def mkSegment(gst, get, utc_date) :

    chIMC = 'K1:GRD-IMC_STATE_N'
    chGRDLSC = 'K1:GRD-LSC_LOCK_STATE_N'
    chSilent = 'K1:MIF-WE_ARE_DOING_NOTHING'
    channels = [chIMC, chGRDLSC, chSilent]
    
    if getpass.getuser() == "controls":
        gwf_cache = '/users/DET/Cache/latest.cache'
        with open(gwf_cache, 'r') as fobj:
            cache = Cache.fromfile(fobj)
    else:
        # add 1sec margin for locked segments contract.
        cache = GetFilelist(gst-1, get+1)

    #------------------------------------------------------------

    #print('Reading {0} timeseries data...'.format(date))
    # add 1sec margin for locked segments contract.
    channeldata = TimeSeriesDict.read(cache, channels, start=gst-1, end=get+1, format='gwf.lalframe', gap='pad')
    channeldataIMC = channeldata[chIMC]
    channeldataGRDLSC = channeldata[chGRDLSC]
    channeldataSilent = channeldata[chSilent]

    #------------------------------------------------------------
    #print('Checking PMC Locking status for K1...')

    sv={}
    sv['ScienceMode'] = channeldataGRDLSC == 1000 
    sv['NonScienceMode'] = channeldataGRDLSC != 1000 
    sv['IMC'] = channeldataIMC >= 100
    sv['FPMILocked'] =  channeldataGRDLSC >= 300 
    sv['Silent'] = channeldataSilent == 1

    dqflag = {}
    for key in keys:
        if key != 'SilentFPMILocked':
            dqflag[key] = sv[key].to_dqflag(round=True)

    # To omit fraction. round=True option is inclusive in default.         
    dqflag['ScienceMode'].active = dqflag['ScienceMode'].active.contract(1.0)
    dqflag['FPMILocked'].active = dqflag['FPMILocked'].active.contract(1.0)

    dqflag['SilentFPMILocked'] = dqflag['Silent'] & dqflag['FPMILocked']

    for key in keys:

        # added 1sec margin for locked segments contract is removed.
        margin = DataQualityFlag(known=[(gst,get)],active=[(gst-1,gst),(get,get+1)])
        dqflag[key] -= margin

        # write down 15 min segments. 
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


if not os.path.exists(SEGMENT_DIR+'/ScienceMode/'+year):
    os.makedirs(SEGMENT_DIR+'/ScienceMode/'+year)
    os.makedirs(SEGMENT_DIR+'/NonScienceMode/'+year)
    os.makedirs(SEGMENT_DIR+'/FPMILocked/'+year)
    os.makedirs(SEGMENT_DIR+'/IMC/'+year)
    os.makedirs(SEGMENT_DIR+'/SilentFPMILocked/'+year)
    os.makedirs(SEGMENT_DIR+'/Silent/'+year)
    os.makedirs(SEGMENT_DIR+'/Partial/'+year)

# Set time every 15 min. 
end_gps_time = int (float(subprocess.check_output('/home/detchar/git/kagra-detchar/tools/Segments/Script/periodictime.sh', shell = True)) )
start_gps_time = int(end_gps_time) - 900

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
        tmp.write(SEGMENT_DIR +key+'/'+year+'/K1-SegmentList_'+key+'_UTC_' + utc_date + '.xml',overwrite=True)

        with open(SEGMENT_DIR +key+'/'+year+'/K1-SegmentList_'+key+'_UTC_' + utc_date + '.txt', mode='w') as f:
            for seg in tmp.active :
                f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))

else:
    print("Not")