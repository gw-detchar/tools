#!/usr/bin/env python
usage       = "python makeConfigSegment.py"
description = "Make configuration flag."
author      = "Chihiro Kozakai, ckozakai@icrr.u-tokyo.ac.jp"

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
keys = ['K1-DET_CONFIG_COMMISSIONING','K1-DET_CONFIG_O3_V1']

# Period of each configuration
period = {}
# Before O3 start, JST 2020/1/8 ~ 2020/1/29 9:00:00
period['K1-DET_CONFIG_COMMISIONING'] = (1262500000, 1264291218)
# during O3, JST 2020/1/29 9:00:00 ~ 2020/5/1 9:00:00
period['K1-DET_CONFIG_O3_V1'] = (1264291218, 1272326418)

utc_date = (datetime.now() + timedelta(hours=-9,minutes=-15)).strftime("%Y-%m-%d")
year = (datetime.now() + timedelta(hours=-9)).strftime("%Y")
filepath_txt = {}
filepath_xml = {}
    
for key in keys:
    filepath_txt[key] = SEGMENT_DIR + '/'+key+'/'+year+'/'+key+'_SEGMENT_UTC_' + utc_date + '.txt'
    filepath_xml[key] = SEGMENT_DIR + '/'+key+'/'+year+'/'+key+'_SEGMENT_UTC_' + utc_date + '.xml'

def mkSegment(gst, get, utc_date) :

    
    dqflag = {}
    for key in keys:
        #if key != 'K1-DET_SILENT_LOCKED':
        #    dqflag[key] = sv[key].to_dqflag(round=True)
        dqflag[key] = DataQualityFlag(known=[(gst,get)],active=[(gst,get)],name=key)
        valid = DataQualityFlag(known=[(gst,get)],active=[period[key]],name=key)
        dqflag[key] = dqflag[key] & valid

    #dqflag['K1-GRD_SCIENCE_MODE'].description = "Observation mode. K1:GRD-LSC_LOCK_STATE_N == 1000"

    for key in keys:
        # write down 1-day segments. 
        with open(filepath_txt[key], mode='w') as f:
            for seg in dqflag[key].active :
                f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))

        dqflag[key].write(filepath_xml[key],overwrite=True)
            
#------------------------------------------------------------

#utc_date = (datetime.now() + timedelta(days=-1)).strftime("%Y-%m-%d")


#if not os.path.exists(SEGMENT_DIR+'/K1-GRD_SCIENCE_MODE/'+year):
#    for key in keys:
for key in keys:
    if not os.path.exists(SEGMENT_DIR+'/'+key+'/'+year):
        os.makedirs(SEGMENT_DIR+'/'+key+'/'+year)

utc_date = (datetime.now() + timedelta(days=-1)).strftime("%Y-%m-%d")
start_utc_time = utc_date + ' 09:00:00'

cmd = 'gpstime ' + start_utc_time + ' | awk \'NR == 3 {print $2}\''
start_gps_time = int (float(subprocess.check_output(cmd, shell = True)) )
end_gps_time = int(start_gps_time) + 86400

try :
    mkSegment(start_gps_time, end_gps_time, utc_date)
    #print('    DQF segment file saved')
except ValueError :
    print('    Cannot append discontiguous TimeSeries')
    pass
#------------------------------------------------------------

print('\n--- Total {0}h {1}m ---'.format( int((time.time()-start_time)/3600), int(( (time.time()-start_time)/3600 - int((time.time()-start_time)/3600) )*60) ))


