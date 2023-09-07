#!/usr/bin/env python
usage       = "python LockingStatus.py"
description = "Checking KAGRA Locking status"
author      = "Shoichi Oshino, oshino@icrr.u-tokyo.ac.jp"

# Modified for the IGWN environment. N. Uchikata (2022.12.15)
# Summarize information of segements in an array of dictionaries.  N. Uchikata (2023.1.10)
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
import math

#------------------------------------------------------------
# Segments information

# segments=[{'name':'K1-GRD_SCIENCE_MODE','channel':'K1:GRD-IFO_STATE_N','condition':'equal','value':1000, 'description':"Observation mode. K1:GRD-IFO_STATE_N == 1000"},
#           {'name':'K1-GRD_UNLOCKED','channel':'K1:GRD-LSC_LOCK_STATE_N','condition':'not equal','value':10000,'description':"Interferometer is not locked. K1:GRD-LSC_LOCK_STATE_N != 10000"},
#           {'name':'K1-GRD_LOCKED','channel':'K1:GRD-LSC_LOCK_STATE_N','condition':'equal','value':10000,'description':"Interferometer is locked. K1:GRD-LSC_LOCK_STATE_N == 10000"},
#           {'name':'K1-OMC_OVERFLOW_OK','channel':'K1:FEC-32_ADC_OVERFLOW_0_0','condition':'equal','value':0,'description':"OMC overflow does not happened. K1:FEC-32_ADC_OVERFLOW_0_0 == 0"},
#           {'name':'K1-OMC_OVERFLOW_VETO','channel':'K1:FEC-32_ADC_OVERFLOW_0_0','condition':'not equal','value':0,'description':"OMC overflow happened. K1:FEC-32_ADC_OVERFLOW_0_0 != 0"},
#           {'name':'K1-GRD_PEM_EARTHQUAKE','channel':'K1:GRD-PEM_EARTHQUAKE_STATE_N','condition':'equal','value':1000,'description':"K1:GRD-PEM_EARTHQUAKE_STATE_N == 1000",'round_contract':False}
#          ]

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
    cache_DIR = "/users/DET/Cache/Cache_GPS/"
    sys.path.append(os.path.join(os.path.dirname(__file__), '/users/DET/tools/Segments/Script'))
    if output == None:
        SEGMENT_DIR = "/users/DET/Segments/"
    else:
        SEGMENT_DIR = output + "/"
else:
    cache_DIR = "/home/detchar/cache/Cache_GPS/"
    sys.path.append(os.path.join(os.path.dirname(__file__), '/home/detchar/git/kagra-detchar/tools/Segments/Script'))
    if output == None:
        SEGMENT_DIR = "/home/detchar/Segments/"
    else:
        SEGMENT_DIR = output + "/"

import DAQ_IPC_ERROR
import OVERFLOW_ADC_DAC
import frame_available
import LOCK_GRD
import PEM_EARTHQUAKE
import SCIENCE_MODE

filepath_txt = {}
filepath_xml = {}

# Note: 'to_dqflag().round(contract=round)' is used for the round option
# 'True' for good data segments, 'False' for bad data segments.

segments = [{'name':'K1-DAQ-IPC_ERROR',
             'function':DAQ_IPC_ERROR._make_ipc_glitch_flag,
             'option':[False],
             'channel':['K1:FEC-8_TIME_DIAG',   ### k1lsc
                        'K1:FEC-11_TIME_DIAG',  ### k1calcs
                        'K1:FEC-83_TIME_DIAG',  ### k1omc
                        'K1:FEC-103_TIME_DIAG', ### k1visetmxp              
                    ]},
            {'name':'K1-DET_FRAME_AVAILABLE',
             'function':frame_available._make_frame_available_flag,
             'option':[filepath_xml, filepath_txt, SEGMENT_DIR, True],
             'channel':["K1:GRD-IFO_STATE_N"]
                    },
            {'name':'K1-OMC_OVERFLOW_VETO',
             'function':OVERFLOW_ADC_DAC._make_overflow_flag,
             'option':['OMC',False],
             'channel':['K1:FEC-79_ADC_OVERFLOW_0_0',  ### DCPD_A                             
                        'K1:FEC-79_ADC_OVERFLOW_0_1'   ### DCPD_B 
                    ]}, 
             {'name':'K1-OMC_OVERFLOW_OK',
             'function':OVERFLOW_ADC_DAC._make_overflow_ok_flag,
             'option':['OMC',True],
             'channel':['K1:FEC-79_ADC_OVERFLOW_0_0',  ### DCPD_A                             
                        'K1:FEC-79_ADC_OVERFLOW_0_1'   ### DCPD_B 
                    ]}, 
            {'name':'K1-ETMX_OVERFLOW_VETO',
             'function':OVERFLOW_ADC_DAC._make_overflow_flag,
             'option':['ETMX',False],
             'channel':['K1:FEC-103_DAC_OVERFLOW_1_0',   ### MN_V3
                      'K1:FEC-103_DAC_OVERFLOW_1_1',   ### MN_H1
                      'K1:FEC-103_DAC_OVERFLOW_1_2',   ### MN_H2
                      'K1:FEC-103_DAC_OVERFLOW_1_3',   ### MN_H3
                      'K1:FEC-103_DAC_OVERFLOW_1_4',   ### MN_V1
                      'K1:FEC-103_DAC_OVERFLOW_1_5',   ### MN_V2
                      'K1:FEC-103_DAC_OVERFLOW_1_6',   ### IM_V1
                      'K1:FEC-103_DAC_OVERFLOW_1_7',   ### IM_V2
                      'K1:FEC-103_DAC_OVERFLOW_1_8',   ### IM_V3
                      'K1:FEC-103_DAC_OVERFLOW_1_9',   ### IM_H1
                      'K1:FEC-103_DAC_OVERFLOW_1_10',  ### IM_H2
                      'K1:FEC-103_DAC_OVERFLOW_1_11',  ### IM_H3
                      'K1:FEC-103_DAC_OVERFLOW_1_12',  ### TM_H1
                      'K1:FEC-103_DAC_OVERFLOW_1_13',  ### TM_H2
                      'K1:FEC-103_DAC_OVERFLOW_1_14',  ### TM_H3
                      'K1:FEC-103_DAC_OVERFLOW_1_15']  ### TM_H4
             },
            {'name':'K1-ETMX_OVERFLOW_OK',
             'function':OVERFLOW_ADC_DAC._make_overflow_ok_flag,
             'option':['ETMX',True],
             'channel':['K1:FEC-103_DAC_OVERFLOW_1_0',   ### MN_V3
                      'K1:FEC-103_DAC_OVERFLOW_1_1',   ### MN_H1
                      'K1:FEC-103_DAC_OVERFLOW_1_2',   ### MN_H2
                      'K1:FEC-103_DAC_OVERFLOW_1_3',   ### MN_H3
                      'K1:FEC-103_DAC_OVERFLOW_1_4',   ### MN_V1
                      'K1:FEC-103_DAC_OVERFLOW_1_5',   ### MN_V2
                      'K1:FEC-103_DAC_OVERFLOW_1_6',   ### IM_V1
                      'K1:FEC-103_DAC_OVERFLOW_1_7',   ### IM_V2
                      'K1:FEC-103_DAC_OVERFLOW_1_8',   ### IM_V3
                      'K1:FEC-103_DAC_OVERFLOW_1_9',   ### IM_H1
                      'K1:FEC-103_DAC_OVERFLOW_1_10',  ### IM_H2
                      'K1:FEC-103_DAC_OVERFLOW_1_11',  ### IM_H3
                      'K1:FEC-103_DAC_OVERFLOW_1_12',  ### TM_H1
                      'K1:FEC-103_DAC_OVERFLOW_1_13',  ### TM_H2
                      'K1:FEC-103_DAC_OVERFLOW_1_14',  ### TM_H3
                      'K1:FEC-103_DAC_OVERFLOW_1_15']  ### TM_H4
             },
            {'name':'K1-ETMY_OVERFLOW_VETO',
             'function':OVERFLOW_ADC_DAC._make_overflow_flag,
             'option':['ETMY',False],
             'channel':['K1:FEC-108_DAC_OVERFLOW_1_0',   ### MN_V3
                      'K1:FEC-108_DAC_OVERFLOW_1_1',   ### MN_H1
                      'K1:FEC-108_DAC_OVERFLOW_1_2',   ### MN_H2
                      'K1:FEC-108_DAC_OVERFLOW_1_3',   ### MN_H3
                      'K1:FEC-108_DAC_OVERFLOW_1_4',   ### MN_V1
                      'K1:FEC-108_DAC_OVERFLOW_1_5',   ### MN_V2
                      'K1:FEC-108_DAC_OVERFLOW_1_6',   ### IM_V1
                      'K1:FEC-108_DAC_OVERFLOW_1_7',   ### IM_V2
                      'K1:FEC-108_DAC_OVERFLOW_1_8',   ### IM_V3
                      'K1:FEC-108_DAC_OVERFLOW_1_9',   ### IM_H1
                      'K1:FEC-108_DAC_OVERFLOW_1_10',  ### IM_H2
                      'K1:FEC-108_DAC_OVERFLOW_1_11',  ### IM_H3
                      'K1:FEC-108_DAC_OVERFLOW_1_12',  ### TM_H1
                      'K1:FEC-108_DAC_OVERFLOW_1_13',  ### TM_H2
                      'K1:FEC-108_DAC_OVERFLOW_1_14',  ### TM_H3
                      'K1:FEC-108_DAC_OVERFLOW_1_15']  ### TM_H4
             },
            {'name':'K1-ETMY_OVERFLOW_OK',
             'function':OVERFLOW_ADC_DAC._make_overflow_ok_flag,
             'option':['ETMY',True],
             'channel':['K1:FEC-108_DAC_OVERFLOW_1_0',   ### MN_V3
                      'K1:FEC-108_DAC_OVERFLOW_1_1',   ### MN_H1
                      'K1:FEC-108_DAC_OVERFLOW_1_2',   ### MN_H2
                      'K1:FEC-108_DAC_OVERFLOW_1_3',   ### MN_H3
                      'K1:FEC-108_DAC_OVERFLOW_1_4',   ### MN_V1
                      'K1:FEC-108_DAC_OVERFLOW_1_5',   ### MN_V2
                      'K1:FEC-108_DAC_OVERFLOW_1_6',   ### IM_V1
                      'K1:FEC-108_DAC_OVERFLOW_1_7',   ### IM_V2
                      'K1:FEC-108_DAC_OVERFLOW_1_8',   ### IM_V3
                      'K1:FEC-108_DAC_OVERFLOW_1_9',   ### IM_H1
                      'K1:FEC-108_DAC_OVERFLOW_1_10',  ### IM_H2
                      'K1:FEC-108_DAC_OVERFLOW_1_11',  ### IM_H3
                      'K1:FEC-108_DAC_OVERFLOW_1_12',  ### TM_H1
                      'K1:FEC-108_DAC_OVERFLOW_1_13',  ### TM_H2
                      'K1:FEC-108_DAC_OVERFLOW_1_14',  ### TM_H3
                      'K1:FEC-108_DAC_OVERFLOW_1_15']  ### TM_H4
             },
             {'name':'K1-GRD_PEM_EARTHQUAKE',
             'function':PEM_EARTHQUAKE._make_earthquake_flag,
             'option':[False],
             'channel':['K1:GRD-PEM_EARTHQUAKE_STATE_N']
                    },
            {'name':'K1-GRD_LOCKED',
             'function':LOCK_GRD._make_locked_flag,
             'option':[True],
             'channel':['K1:GRD-IFO_STATE_N' ]                           
                    },
            {'name':'K1-GRD_UNLOCKED',
            'function':LOCK_GRD._make_unlocked_flag,
            'option':[False],
            'channel':['K1:GRD-IFO_STATE_N']                            
                   },
            {'name':'K1-GRD_SCIENCE_MODE',
             'function':SCIENCE_MODE._make_science_flag,
             'option':[True],
             'channel':['K1:GRD-IFO_STATE_N',
                  'K1:GRD-LSC_LOCK_STATE_N']
            },
            ]


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
        cache_file="%s/%s_%s.ffl" % (cache_DIR, gpsstart, gpsend)

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

    channel_list = [d['channel'] for d in segments] # make a list of channels
    channel_list = sum(channel_list, [])
    channel_list = set(channel_list)  # remove duplicate channel name    
       
    # channeldata = TimeSeriesDict.read(cache, channel_list, start=gst-1, end=get+1, format='gwf', gap='pad')
    # channeldata = TimeSeriesDict.read(cache, channel_list, start=gst-1, end=get+1, format='gwf')
    channeldata = TimeSeriesDict.read(cache, channel_list, start=gst, end=get, format='gwf', gap='pad')
    
    sv={}
    dqflag={}
    for d in segments:
        key = d['name']

        channeldata_p = {k: v for k, v in channeldata.items() if k in d["channel"]}        
        dqflag[key] = d['function'](channeldata_p, *d['option'])
        print(dqflag[key])

        print(filepath_xml[key])
        print(filepath_txt[key])
        
        # if accumulated file exists, it is added. 
        if os.path.exists(filepath_xml[key]):
            tmp = DataQualityFlag.read(filepath_xml[key])        
            dqflag[key] = dqflag[key] + tmp

        dqflag[key].write(filepath_xml[key],overwrite=True,format="ligolw")
        #np.savetxt(filepath_txt[key], dqflag[key].active, fmt = '%d')
        file = open(filepath_txt[key], "w")
        for dq in dqflag[key].active:
            file.write("%d %d\n" % (math.floor(dq[0]), math.ceil(dq[1])))
            print("%d %d" % (math.floor(dq[0]), math.ceil(dq[1])))
        file.close()        

        # file = open(filepath_txt[key], "w")
        # for i in range(len(dqflag[key])):
        #     file.write("%d %d\n" % (dqflag[key][i].active[0], dqflag[key][i].active[1]))
        # file.close()

        
# Create missing segments for each segment name
def reSegment(gst, get, utc_date, key, channel_name, condition, value, description, txt=True) :

    # add 1sec margin for locked segments contract.
    cache = GetFilelist(gst-1, get+1)

    #------------------------------------------------------------
    # print('Reading {0} timeseries data...'.format(date))
    # add 1sec margin for locked segments contract.
    #channeldata = TimeSeriesDict.read(cache, channel_list, start=gst-1, end=get+1, format='gwf', gap='pad')
    channeldata = TimeSeriesDict.read(cache, channel_list, start=gst, end=get, format='gwf', gap='pad')

    #sv={}
    dqflag={}

    channeldata_p = {k: v for k, v in channeldata.items() if k in d["channel"]}        
    dqflag[key] = d['function'](channeldata_p, d['option'])
    print(dqflag)

    # added 1sec margin for locked segments contract is removed.
    #margin = DataQualityFlag(known=[(gst,get)],active=[(gst-1,gst),(get,get+1)])
    #dqflag[key] -= margin

    # write down 
    if os.path.exists(filepath_xml[key]):
        tmp = DataQualityFlag.read(filepath_xml[key])        
        dqflag[key] = dqflag[key] + tmp
    print(dqflag[key])
    
    dqflag[key].write(filepath_xml[key],overwrite=True,format="ligolw")
    #np.savetxt(filepath_txt[key], dqflag[key].active, fmt = '%d')
    file = open(filepath_txt[key], "w")
    for dq in dqflag[key].active:
        file.write("%d %d\n" % (math.floor(dq[0]), math.ceil(dq[1])))
        print("%d %d" % (math.floor(dq[0]), math.ceil(dq[1])))
    file.close()        
        
    
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


# Remove a combined cache file if exists                                                                        
combined_cache = "%s/%s_%s.ffl" % (cache_DIR,start_gps_time-1, end_gps_time+1)
print(combined_cache)
if(os.path.isfile(combined_cache)):
    os.remove(combined_cache)
