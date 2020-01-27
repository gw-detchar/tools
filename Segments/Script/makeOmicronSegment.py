#!/usr/bin/env python
usage       = "python makeOmicronSrgment.py"
description = "Veto segments based on Omicron trigger."
author      = "Chihiro Kozakai, ckozakai@icrr.u-tokyo.ac.jp"

#-----------------------------------------------------------------------------#
import time
import sys
import os
import subprocess
from datetime import datetime, timedelta
from pytz import timezone

from astropy.table import vstack
from gwpy.timeseries import TimeSeries
from gwpy.timeseries import TimeSeriesDict
from gwpy.timeseries import StateTimeSeries
from gwpy.segments import DataQualityFlag
from gwpy.segments import Segment
from gwpy.table import EventTable
from glue.lal import Cache

import getpass
import glob

from mylib import mylib
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

def GetFilelist(gpsstart,gpsend,channel):
    '''
    This function gives omicron file list.
    '''
    gpsstart=str(int(float(gpsstart)))
    gpsend=str(int(float(gpsend)))

    sources = []

    for i in range(int(gpsstart[0:5]),int(gpsend[0:5])+1):
        #dir = '/data/full/' + str(i) + '/*'
        tmpdir = '/home/controls/triggers/K1/' + channel + '_OMICRON/' + str(i) + '/*'
        source = glob.glob(tmpdir)
        sources.extend(source)

    sources.sort()

    removelist = []

    for x in sources:
        tmptime = int(x.rsplit('-',2)[1])

        if tmptime<(int(gpsstart)-31):
            removelist.append(x)
        if tmptime>int(gpsend):
            removelist.append(x)

    for y in removelist:
        sources.remove(y)

    return sources


keys = ['CAL_CS_PROC_C00_STRAIN_DBL_DQ', 'PEM_SEIS_EXV_GND_X_OUT_DQ','PEM_SEIS_EXV_GND_Y_OUT_DQ','PEM_SEIS_EXV_GND_Z_OUT_DQ','PEM_SEIS_EYV_GND_X_OUT_DQ','PEM_SEIS_EYV_GND_Y_OUT_DQ','PEM_SEIS_EYV_GND_Z_OUT_DQ','PEM_SEIS_IXV_GND_X_OUT_DQ','PEM_SEIS_IXV_GND_Y_OUT_DQ','PEM_SEIS_IXV_GND_Z_OUT_DQ',]
snrs = {}
snrs['CAL_CS_PROC_C00_STRAIN_DBL_DQ'] = [20,100]
for key in keys:
    if "PEM_SEIS" in key:
        snrs[key] = [20]

utc_date = (datetime.now() + timedelta(hours=-9,minutes=-15)).strftime("%Y-%m-%d")
year = (datetime.now() + timedelta(hours=-9)).strftime("%Y")
filepath_txt = {}
filepath_xml = {}
    
if getpass.getuser() == "controls":
    tmp_DIR = "/users/DET/tools/Segments/Script/Partial/"
else:
    tmp_DIR = "/home/detchar/git/kagra-detchar/tools/Segments/Script/Partial/"

for key in keys:
    for snr in snrs[key]:
        filepath_txt[key+str(snr)] = tmp_DIR +'K1-'+key+'_SNR'+str(snr)+'_SEGMENT_UTC_' + utc_date + '.txt'
        filepath_xml[key+str(snr)] = tmp_DIR +'K1-'+key+'_SNR'+str(snr)+'_SEGMENT_UTC_' + utc_date + '.xml'
        if not os.path.exists(SEGMENT_DIR+'/K1-'+key+'_SNR'+str(snr)+'/'+year):
            os.makedirs(SEGMENT_DIR+'/K1-'+key+'_SNR'+str(snr)+'/'+year)

def mkSegment(gst, get, utc_date, txt=True) :

    for key in keys:
        sources = GetFilelist(gst,get,key)

        first=True
        for source in sources:
            events = EventTable.read(source, tablename='sngl_burst',columns=['start_time', 'start_time_ns', 'duration',  'snr'])
            #events = EventTable.read(source, tablename='sngl_burst',columns=['peak_time', 'peak_time_ns','start_time', 'start_time_ns', 'duration', 'peak_frequency', 'central_freq', 'bandwidth', 'channel', 'amplitude', 'snr', 'confidence', 'chisq', 'chisq_dof', 'param_one_name', 'param_one_value'])
            col = events.get_column('start_time')
            if first:
                if len(col) > 0 :
                    mergedevents=events
                    first=False
                else:
                    pass
            else:
                mergedevents=vstack([mergedevents, events])

        if first:
            continue
        
        for snr in snrs[key]:
            Triggered = DataQualityFlag(name = "K1:"+key, known=[(gst,get)],active=[], label = "Glitch", description = "Glitch veto segment K1:"+key+ " >= SNR"+str(snr))
            #Triggered.ifo = "K1"

            fevents = mergedevents.filter(('snr', mylib.Islargerequal, snr))
            durations = fevents.get_column('duration')
            start_times = fevents.get_column('start_time')
            for start_time, duration in zip(start_times, durations):
                tmpstart = int(start_time)
                #tmpend = start_time + duration
                tmpend = int(start_time + 1)
                tmpsegment = Segment(tmpstart,tmpend)

                tmpTriggered = DataQualityFlag(known=[(gst,get)],active=[(tmpstart,tmpend)])
                Triggered |= tmpTriggered
                        
                #dqflag['K1-GRD_SCIENCE_MODE'].description = "Observation mode. K1:GRD-IFO_STATE_N == 1000"
                #dqflag['K1-GRD_LOCKED'].name = "K1:GRD-LSC_LOCK_STATE_N >= 300 & K1:GRD-LSC_LOCK_STATE_N <= 1000"

            # write down 15 min segments. 
            if txt:
                with open(filepath_txt[key+str(snr)], mode='w') as f:
                    for seg in Triggered.active :
                        f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
        
            # if accumulated file exists, it is added. 
            if os.path.exists(filepath_xml[key+str(snr)]):
                tmp = DataQualityFlag.read(filepath_xml[key+str(snr)])        
                Triggered = Triggered + tmp

            Triggered.write(filepath_xml[key+str(snr)],overwrite=True)

#------------------------------------------------------------

# Set time every 15 min. 
if getpass.getuser() == "controls":
    end_gps_time = int (float(subprocess.check_output('/users/DET/tools/Segments/Script/periodictime.sh', shell = True)) )
else:
    end_gps_time = int (float(subprocess.check_output('/home/detchar/git/kagra-detchar/tools/Segments/Script/periodictime.sh', shell = True)) )

end_gps_time = int(end_gps_time) - 900
start_gps_time = int(end_gps_time) - 900

# For locked segment contract, take 1sec margin.
#end_gps_time = end_gps_time + 1

#start_gps_time = start_gps_time - 1

#start_gps_time = 1261080418
#end_gps_time = 1261081318
try :
    mkSegment(start_gps_time, end_gps_time, utc_date)
    #print('    DQF segment file saved')
except ValueError :
    print('    Cannot append discontiguous TimeSeries')
    pass
#------------------------------------------------------------

print('\n--- Total {0}h {1}m ---'.format( int((time.time()-start_time)/3600), int(( (time.time()-start_time)/3600 - int((time.time()-start_time)/3600) )*60) ))


# whole day file should be produced at the end of the day.
end_time = (datetime.now() + timedelta(hours=-9) + timedelta(minutes=-15)).strftime("%Y-%m-%d")

#if utc_date != end_time:
if False:
    print("date changed.")
    for key in keys:
        for snr in snrs[key]:

            tmp = DataQualityFlag.read(filepath_xml[key+str(snr)])
            tmp.write(SEGMENT_DIR +'K1-'+key+'_SNR'+str(snr)+'/'+year+'/'+'K1-'+key+'_SNR'+str(snr)+'_SEGMENT_UTC_' + utc_date + '.xml',overwrite=True)

            # Check if missing part exist
            day = DataQualityFlag(known=[(end_gps_time-86400,end_gps_time)],active=[(end_gps_time-86400,end_gps_time)],name=key+str(snr))
            missing = day.known - tmp.known

            for seg in missing:
                mkSegment(seg[0], seg[1], utc_date, txt=False)
            tmp = DataQualityFlag.read(filepath_xml[key+str(snr)])

            tmp.write(SEGMENT_DIR +'K1-'+key+'_SNR'+str(snr)+'/'+year+'/'+'K1-'+key+'_SNR'+str(snr)+'_SEGMENT_UTC_' + utc_date + '.xml',overwrite=True)   
            with open(SEGMENT_DIR +'K1-'+key+'_SNR'+str(snr)+'/'+year+'/'+'K1-'+key+'_SNR'+str(snr)+'_SEGMENT_UTC_' + utc_date + '.txt', mode='w') as f:
                for seg in tmp.active :
                    f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
            os.remove(filepath_xml[key+str(snr)])
            os.remove(filepath_txt[key+str(snr)])
