#!/usr/bin/env python
usage       = "python LockingStatus.py"
description = "Checking KAGRA Locking status"
author      = "Shoichi Oshino, oshino@icrr.u-tokyo.ac.jp"

# Modified for the IGWN environment. N. Uchikata (2022.12.15)
# Summarize information of segements in an array of dictionaries.  N. Uchikata (2023.1.10)
# Note: 'equal' conditions use 'to_dqflag().round(contract=True)', while 'not equal' conditions 'to_dqflag().round(contract=False)'.
# Added parsers for choice of clusters and the output directory. N. Uchikata (2023.1.10)
# remove the manual mode. --> make24hourSegment.py  N. Uchikata (2023.1.16)

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
from gwpy.time import from_gps
from glue.lal import Cache

import numpy as np
import getpass
import glob

#------------------------------------------------------------
# Segments information

segments=[{'name':'K1-GRD_SCIENCE_MODE','channel':'K1:GRD-IFO_STATE_N','condition':'equal','value':1000, 'description':"Observation mode. K1:GRD-IFO_STATE_N == 1000"},
          {'name':'K1-GRD_UNLOCKED','channel':'K1:GRD-LSC_LOCK_STATE_N','condition':'not equal','value':10000,'description':"Interferometer is not locked. K1:GRD-LSC_LOCK_STATE_N != 10000"},
          {'name':'K1-GRD_LOCKED','channel':'K1:GRD-LSC_LOCK_STATE_N','condition':'equal','value':10000,'description':"Interferometer is locked. K1:GRD-LSC_LOCK_STATE_N == 10000"},
          {'name':'K1-OMC_OVERFLOW_OK','channel':'K1:FEC-32_ADC_OVERFLOW_0_0','condition':'equal','value':0,'description':"OMC overflow does not happened. K1:FEC-32_ADC_OVERFLOW_0_0 == 0"},
          {'name':'K1-OMC_OVERFLOW_VETO','channel':'K1:FEC-32_ADC_OVERFLOW_0_0','condition':'not equal','value':0,'description':"OMC overflow happened. K1:FEC-32_ADC_OVERFLOW_0_0 != 0"},
          {'name':'K1-GRD_PEM_EARTHQUAKE','channel':'K1:GRD-PEM_EARTHQUAKE_STATE_N','condition':'equal','value':1000,'description':"K1:GRD-PEM_EARTHQUAKE_STATE_N == 1000"}
         ]

import argparse

parser = argparse.ArgumentParser(description='Make segment files.')
parser.add_argument('-c','--cluster',help='Choose Kamioka or Kashiwa', required = True, choices=['Kamioka','Kashiwa'])
parser.add_argument('-o','--output',help='Specify output directory. Default:/users/DET/Segments/ for Kamioka, /home/detchar/Segments/ for Kashiwa')

args = parser.parse_args()
cluster = args.cluster
output = args.output

start_time = time.time()

#------------------------------------------------------------
# Set enviroment

    
if cluster == "Kamioka":
    cache_DIR = "later"
    if output == None:
        SEGMENT_DIR = "/users/DET/Segments/"
    else:
        SEGMENT_DIR = output
else:
    cache_DIR = "/home/detchar/cache/Cache_GPS/"
    if output == None:
        SEGMENT_DIR = "/home/detchar/Segments/"
    else:
        SEGMENT_DIR = output
        
#------------------------------
# define output file path

def Filepath(utc_data, year):
   
    for d in segments:
        key = d['name']
        if not os.path.exists(SEGMENT_DIR+'/'+key+'/'+year):
            os.makedirs(SEGMENT_DIR+'/'+key+'/'+year)
        filepath_xml[key] = SEGMENT_DIR +key+'/'+year+'/'+key+'_SEGMENT_UTC_' + utc_date + '.xml'
        filepath_txt[key] = SEGMENT_DIR +key+'/'+year+'/'+key+'_SEGMENT_UTC_' + utc_date + '.txt'
        print(filepath_xml[key])


#------------------------------------------------------------

def GetFilelist(gpsstart,gpsend): # by H. Yuzurihara
    gps_beg_head = int(gpsstart/100000)
    gps_end_head = int(gpsend/100000)

    if gps_beg_head == gps_end_head:
        cache_file = cache_DIR+"%s.ffl" % gps_beg_head
    else:
        # merge two cache files
        cache1 = cache_DIR+"%s.ffl" % gps_beg_head
        cache2 = cache_DIR+"%s.ffl"% gps_end_head
        cache_file="/tmp/%s_%s.ffl" % (gpsstart, gpsend)

        with open(cache_file, 'w') as outfile:
          for i in [cache1, cache2]:
             with open(i) as infile:
                outfile.write(infile.read())
                
    return cache_file


def mkSegment(gst, get, utc_date, txt=True) :

    # add 1sec margin for locked segments contract.
    cache = GetFilelist(gst-1, get+1)

    #------------------------------------------------------------

   # print('Reading {0} timeseries data...'.format(date))
    # add 1sec margin for locked segments contract.
    
    channel_list0 = [d['channel'] for d in segments] # make a list of channels
    channel_list = set(channel_list0)  # remove duplicate channel name
   # channeldata = TimeSeriesDict.read(cache, channel_list, start=gst-1, end=get+1, format='gwf', gap='pad')
    channeldata = TimeSeriesDict.read(cache, channel_list, start=gst-1, end=get+1, format='gwf')

    sv={}
    dqflag={}
    for d in segments:
        key = d['name']
        channel_name = d['channel']
        condition = d['condition']
        value = d['value']
        description = d['description']
  
        if(condition == 'equal'):
            sv[key] = StateTimeSeries(channeldata[channel_name].value == value, t0=channeldata[channel_name].t0, dt=channeldata[channel_name].dt)
            dqflag[key] = sv[key].to_dqflag().round(contract=True)
            dqflag[key].name = channel_name + ':' + str(value)
        else:
            sv[key] = StateTimeSeries(channeldata[channel_name].value != value, t0=channeldata[channel_name].t0, dt=channeldata[channel_name].dt)
            dqflag[key] = sv[key].to_dqflag().round(contract=False)
            dqflag[key].name = channel_name + '!:' + str(value)
        dqflag[key].description = description
        if(key == 'K1-GRD_SCIENCE_MODE'):
            dqflag[key].active = dqflag[key].active.contract(1.0)
    print(channeldata['K1:FEC-32_ADC_OVERFLOW_0_0'])
    print(sv)    
    print(dqflag)
    
    #for key in conditions.keys():
    for d in segments:
        key = d['name']
        # added 1sec margin for locked segments contract is removed.
        margin = DataQualityFlag(known=[(gst,get)],active=[(gst-1,gst),(get,get+1)])
        dqflag[key] -= margin
        
        # if accumulated file exists, it is added. 
        if os.path.exists(filepath_xml[key]):
            tmp = DataQualityFlag.read(filepath_xml[key])        
            dqflag[key] = dqflag[key] + tmp

        dqflag[key].write(filepath_xml[key],overwrite=True,format="ligolw")
        np.savetxt(filepath_txt[key], dqflag[key].active, fmt = '%d')
        
# Create missing segments for each segment name
def reSegment(gst, get, utc_date, key, channel_name, condition, value, description, txt=True) :

    # add 1sec margin for locked segments contract.
    cache = GetFilelist(gst-1, get+1)

    #------------------------------------------------------------
   # print('Reading {0} timeseries data...'.format(date))
    # add 1sec margin for locked segments contract.
    #channeldata = TimeSeriesDict.read(cache, channel_list, start=gst-1, end=get+1, format='gwf', gap='pad')
    channeldata = TimeSeriesDict.read(cache, channel_list, start=gst-1, end=get+1, format='gwf')

    sv={}
    dqflag={}

    if(condition == 'equal'):
        sv[key] = StateTimeSeries(channeldata[channel_name].value == value, t0=channeldata[channel_name].t0, dt=channeldata[channel_name].dt)
        dqflag[key] = sv[key].to_dqflag().round(contract=True)
        dqflag[key].name = channel_name + ':' + str(value)
    else:
        sv[key] = StateTimeSeries(channeldata[channel_name].value != value, t0=channeldata[channel_name].t0, dt=channeldata[channel_name].dt)
        dqflag[key] = sv[key].to_dqflag().round(contract=False)
        dqflag[key].name = channel_name + '!:' + str(value)
    dqflag[key].description = description
    if(key == 'K1-GRD_SCIENCE_MODE'):
        dqflag[key].active = dqflag[key].active.contract(1.0)
        
    print(dqflag)
    # added 1sec margin for locked segments contract is removed.
    margin = DataQualityFlag(known=[(gst,get)],active=[(gst-1,gst),(get,get+1)])
    dqflag[key] -= margin

    # write down 
    if os.path.exists(filepath_xml[key]):
        tmp = DataQualityFlag.read(filepath_xml[key])        
        dqflag[key] = dqflag[key] + tmp
    print(dqflag[key])
    
    dqflag[key].write(filepath_xml[key],overwrite=True,format="ligolw")
    np.savetxt(filepath_txt[key], dqflag[key].active, fmt = '%d')
        
    
#------------------------------------------------------------
# main
#------------------------------------------------------------
# Set time every 15 min. 
    
if getpass.getuser() == "controls":
    end_gps_time = int (float(subprocess.check_output('/users/DET/tools/Segments/Script/periodictime.sh', shell = True)) )
else:
    end_gps_time = int (float(subprocess.check_output('/home/detchar/git/kagra-detchar/tools/Segments/Script/periodictime.sh', shell = True)) )

start_gps_time = int(end_gps_time) - 900

start_date = from_gps(start_gps_time)
year = start_date.strftime('%Y')
utc_date = start_date.strftime('%Y-%m-%d')
end_date = from_gps(end_gps_time)
end_time = end_date.strftime('%Y-%m-%d')
print(utc_date)

filepath_txt = {}
filepath_xml = {}

Filepath(utc_date, year) 

try :
    mkSegment(start_gps_time, end_gps_time, utc_date)
#print('    DQF segment file saved')
except ValueError :
    print('    Cannot append discontiguous TimeSeries')
pass
#------------------------------------------------------------

print('\n--- Total {0}h {1}m ---'.format( int((time.time()-start_time)/3600), int(( (time.time()-start_time)/3600 - int((time.time()-start_time)/3600) )*60) ))


# whole day file should be produced at the end of the day.

if utc_date != end_time:
    for d in segments:
        key = d['name']
        channel_name = d['channel']
        condition = d['condition']
        value = d['value']
        description = d['description']
        tmp = DataQualityFlag.read(filepath_xml[key])

        # Check if missing part exist
        day = DataQualityFlag(known=[(end_gps_time-86400,end_gps_time)],active=[(end_gps_time-86400,end_gps_time)],name=key)
        missing = day.known - tmp.known

        for seg in missing:
            reSegment(seg[0], seg[1], utc_date, key, channel_name, condition, value, description, txt=False)
