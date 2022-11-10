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

keys = ['K1-GRD_SCIENCE_MODE','K1-GRD_UNLOCKED','K1-GRD_LOCKED','K1-GRD_PEM_EARTHQUAKE','K1-OMC_OVERFLOW_VETO','K1-OMC_OVERFLOW_OK']

import argparse

parser = argparse.ArgumentParser(description='Make segment files.')
parser.add_argument('-m','--manual',help='Manual run flag.',action='store_true')
parser.add_argument('-t','--test',help='Test run flag. Output will be in test directory.',action='store_true')
parser.add_argument('-d','--date',help='date for manual run.',default = "2020-04-15")

args = parser.parse_args()
manual = args.manual
date = args.date
test = args.test

if manual:
    utc_date = date
    year = date.split("-")[0]

else:
    utc_date = (datetime.now() + timedelta(hours=-9,minutes=-15)).strftime("%Y-%m-%d")
    year = (datetime.now() + timedelta(hours=-9)).strftime("%Y")


start_time = time.time()

#------------------------------------------------------------
# Set enviroment

    
if test:
    if getpass.getuser() == "controls":
        SEGMENT_DIR = "/users/DET/tools/Segments/Script/tmp/"
    else:
        SEGMENT_DIR = "/home/detchar/git/kagra-detchar/tools/Segments/Script/tmp/"

else:
    if getpass.getuser() == "controls":
        SEGMENT_DIR = "/users/DET/Segments/"
    
    else:
        SEGMENT_DIR = "/home/detchar/Segments/"


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

filepath_txt = {}
filepath_xml = {}

if test:    
    if getpass.getuser() == "controls":
        tmp_DIR = "/users/DET/tools/Segments/Script/tmp/Partial/"
    else:
        tmp_DIR = "/home/detchar/git/kagra-detchar/tools/Segments/Script/tmp/Partial/"
else:
    if getpass.getuser() == "controls":
        tmp_DIR = "/users/DET/tools/Segments/Script/Partial/"
    else:
        tmp_DIR = "/home/detchar/git/kagra-detchar/tools/Segments/Script/Partial/"

for key in keys:
    if manual:
        filepath_xml[key] = SEGMENT_DIR +key+'/'+year+'/'+key+'_SEGMENT_UTC_' + utc_date + '.xml'
        filepath_txt[key] = SEGMENT_DIR +key+'/'+year+'/'+key+'_SEGMENT_UTC_' + utc_date + '.txt'
    else:
        filepath_txt[key] = tmp_DIR +key+'_SEGMENT_UTC_' + utc_date + '.txt'
        filepath_xml[key] = tmp_DIR +key+'_SEGMENT_UTC_' + utc_date + '.xml'

def mkSegment(gst, get, utc_date, txt=True) :

    chGRDLSC = 'K1:GRD-LSC_LOCK_STATE_N'
    chGRDIFO = 'K1:GRD-IFO_STATE_N'
    chGRDEQ = 'K1:GRD-PEM_EARTHQUAKE_STATE_N'
    chOMCADC    = 'K1:FEC-32_ADC_OVERFLOW_0_0'

    channels = [chGRDLSC,chGRDIFO,chGRDEQ,chOMCADC]
    
    if getpass.getuser() == "controls":
        gwf_cache = '/users/DET/Cache/latest.cache'
        with open(gwf_cache, 'r') as fobj:
            cache = Cache.fromfile(fobj)
    else:
        # add 1sec margin for locked segments contract.
        cache = GetFilelist(gst-1, get+1)

    #------------------------------------------------------------

   # print('Reading {0} timeseries data...'.format(date))
    # add 1sec margin for locked segments contract.
    channeldata = TimeSeriesDict.read(cache, channels, start=gst-1, end=get+1, format='gwf.lalframe', gap='pad')
    channeldataGRDIFO = channeldata[chGRDIFO]
    channeldataGRDLSC = channeldata[chGRDLSC]
    channeldataGRDEQ = channeldata[chGRDEQ]
    channeldataOMCADC = channeldata[chOMCADC]

    sv={}
    sv['K1-GRD_SCIENCE_MODE'] = channeldataGRDIFO == 1000 
    # Locked will be defined by inverse of unlocked segments for technical reason.    
    sv['K1-GRD_LOCKED'] = channeldataGRDLSC == 10000 
    sv['K1-GRD_UNLOCKED'] = channeldataGRDLSC != 10000
    sv['K1-GRD_PEM_EARTHQUAKE'] = channeldataGRDEQ == 1000
    sv['K1-OMC_OVERFLOW_VETO'] = channeldataOMCADC != 0
    # OMC_OVERFLOW_OK will be defined by inverse of veto segments for technical reason.
    #sv['K1-OMC_OVERFLOW_OK'] = channeldataOMCADC == 0

    print(sv['K1-GRD_LOCKED'])

    dqflag = {}
    for key in keys:
        if key == 'K1-GRD_LOCKED' or key == 'K1-OMC_OVERFLOW_OK':
            continue
        dqflag[key] = sv[key].to_dqflag(round=True)

    # To omit fraction. round=True option is inclusive in default.         

    dqflag['K1-GRD_SCIENCE_MODE'].active = dqflag['K1-GRD_SCIENCE_MODE'].active.contract(1.0)

    dqflag['K1-GRD_LOCKED'] = ~dqflag['K1-GRD_UNLOCKED']
    dqflag['K1-GRD_LOCKED'].name = "K1:GRD-LSC_LOCK_STATE_N == 10000"

    dqflag['K1-OMC_OVERFLOW_OK'] = ~dqflag['K1-OMC_OVERFLOW_VETO']
    dqflag['K1-OMC_OVERFLOW_OK'].name = "K1:FEC-32_ADC_OVERFLOW_0_0 == 0"
    
    dqflag['K1-GRD_SCIENCE_MODE'].description = "Observation mode. K1:GRD-IFO_STATE_N == 1000"
    dqflag['K1-GRD_UNLOCKED'].description = "Interferometer is not locked. K1:GRD-LSC_LOCK_STATE_N != 10000"
    dqflag['K1-GRD_LOCKED'].description = "Interferometer is locked. K1:GRD-LSC_LOCK_STATE_N == 10000"
    dqflag['K1-OMC_OVERFLOW_VETO'].description = "OMC overflow happened. K1:FEC-32_ADC_OVERFLOW_0_0 != 0"
    dqflag['K1-OMC_OVERFLOW_OK'].description = "OMC overflow does not happened. K1:FEC-32_ADC_OVERFLOW_0_0 == 0"

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
if manual:
    if getpass.getuser() == "controls":
        start_gps_time = int (float(subprocess.check_output('/users/DET/tools/Segments/Script/date_to_gps.sh '+utc_date, shell = True)) )
    else:
        start_gps_time = int (float(subprocess.check_output('/home/detchar/git/kagra-detchar/tools/Segments/Script/date_to_gps.sh '+utc_date, shell = True)) )

    end_gps_time = start_gps_time + 86400 


    try :
        mkSegment(start_gps_time, end_gps_time, utc_date)
        #print('    DQF segment file saved')
    except ValueError :
        print('    Cannot append discontiguous TimeSeries')
        pass

    exit()
    
else:
    if getpass.getuser() == "controls":
        end_gps_time = int (float(subprocess.check_output('/users/DET/tools/Segments/Script/periodictime.sh', shell = True)) )
    else:
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
    for key in keys:
        tmp = DataQualityFlag.read(filepath_xml[key])
        #tmp.write(SEGMENT_DIR +key+'/'+year+'/'+key+'_SEGMENT_UTC_' + utc_date + '.xml',overwrite=True)

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
