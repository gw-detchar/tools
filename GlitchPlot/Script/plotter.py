'''
This script will make basic plots from glitch information.
'''

import matplotlib
matplotlib.use('Agg')  # this line is required for the batch job before importing other matplotlib modules.

import math
from gwpy.table import EventTable
from gwpy.segments import DataQualityFlag
from gwpy.table.filters import in_segmentlist
#import ROOT
from ROOT import gROOT, gDirectory, gPad, gSystem, gStyle
from ROOT import TH1D, TH2D, TH1I, TCanvas
from mylib import mylib
from astropy.table import vstack
# argument processing

import argparse

parser = argparse.ArgumentParser(description='Make basic plots.')
parser.add_argument('-o','--output',help='output text filename.',default='result.txt')
#parser.add_argument('-i','--inputfile',help='input trigger filename.',default='/home/controls/triggers/K1/LSC_CARM_SERVO_MIXER_DAQ_OUT_DQ_OMICRON/12440/K1-LSC_CARM_SERVO_MIXER_DAQ_OUT_DQ_OMICRON-1244013258-60.xml.gz')
parser.add_argument('-i','--inputfile',help='input trigger filename.',default='/home/controls/triggers/K1/LSC_CARM_SERVO_MIXER_DAQ_OUT_DQ_OMICRON/12440/K1-LSC_CARM_SERVO_MIXER_DAQ_OUT_DQ_OMICRON-1244004678-60.xml.gz')

args = parser.parse_args()
output = args.output
inputfile = args.inputfile

# Define parameters
omicron_interval = 60.

#triggertype
triggertype="Omicron"

#Default
snrthreshold=100.
#If night, use lower threshold.
snrdict = {"LSC-CARM_SERVO_MIXER_DAQ_OUT_DQ":10, "AOS-TMSX_IR_PD_OUT_DQ":10, "IMC-CAV_TRANS_OUT_DQ":20, "IMC-CAV_REFL_OUT_DQ":10, "PSL-PMC_MIXER_MON_OUT_DQ":10, "IMC-MCL_SERVO_OUT_DQ":30, "PSL-PMC_TRANS_DC_OUT_DQ":40, "IMC-SERVO_SLOW_DAQ_OUT_DQ":7, "PEM-ACC_MCF_TABLE_REFL_Z_OUT_DQ":40, "PEM-ACC_PSL_PERI_PSL1_Y_OUT_DQ":20, "PEM-MIC_PSL_TABLE_PSL4_Z_OUT_DQ":20, "LSC-REFL_PDA1_RF17_Q_ERR_DQ":30, "LSC-REFL_PDA1_RF45_I_ERR_DQ":30, "LSC-AS_PDA1_RF17_Q_ERR_DQ":30}

# get the time of the input file.
tmp=inputfile.rsplit("-",2)
tfile=int(tmp[1])

# Open omicron file

events = EventTable.read(inputfile, tablename='sngl_burst', columns=['peak_time', 'peak_time_ns', 'start_time', 'start_time_ns', 'duration', 'peak_frequency', 'central_freq', 'bandwidth', 'channel', 'amplitude', 'snr', 'confidence', 'chisq', 'chisq_dof', 'param_one_name', 'param_one_value'])
# Tablename option
#'process', 'process_params', 'sngl_burst', 'segment_definer', 'segment_summary', 'segment'
# Column option
#ifo peak_time peak_time_ns start_time start_time_ns duration search process_id event_id peak_frequency central_freq bandwidth channel amplitude snr confidence chisq chisq_dof param_one_name param_one_value
#events = EventTable.read('K1-IMC_CAV_ERR_OUT_DQ_OMICRON-1241900058-60.xml.gz', tablename='sngl_burst', columns=['peak_time', 'peak_time_ns', 'start_time', 'start_time_ns', 'duration', 'peak_frequency', 'central_freq', 'bandwidth', 'channel', 'amplitude', 'snr', 'confidence', 'chisq', 'chisq_dof', 'param_one_name', 'param_one_value'])

channels = events.get_column('channel')

if len(channels) == 0:
    print("No event.")
    print("Successfully finished!")
    exit()
else:
    channel = channels[0]


# If 0am-8am, threshold is lowered.
if 54018 < tfile%86400 and tfile%86400 < 82818:
    snrthreshold=snrdict[channel]
elif 1247022018 < tfile and tfile < 1247043618:
    snrthreshold=snrdict[channel]
else:
    print("Day time file. skip. ")
    exit()

# Setup output txtfile.
f = open(output, mode='w')

# Apply filter. 

fevents = events.filter(('snr', mylib.Islarger,  snrthreshold))
#fevents.write('test.txt',format='ascii',overwrite=True)

# Makesegments of triggers. It will give information about interesting gps time. 

# Get trigger parameters
channels = fevents.get_column('channel')
peak_times = fevents.get_column('peak_time')
peak_time_nss = fevents.get_column('peak_time_ns')
peak_frequencys = fevents.get_column('peak_frequency')
snrs = fevents.get_column('snr')
durations = fevents.get_column('duration')
starts = fevents.get_column('start_time')
starts_ns = fevents.get_column('start_time_ns')
# columns can be used like array. columns[0] will give first value.

if len(channels) == 0:
    print("No filtered event.")
    print("Successfully finished!")
    exit()
    
# Initialize segments of trigger. t=0 is the start of the trigger file.
Triggered = DataQualityFlag(known=[(0,omicron_interval)],active=[])

# loop over triggers.
for peak_time,peak_time_ns,peak_frequency,snr,duration,start,startns in zip(peak_times,peak_time_nss,peak_frequencys,snrs,durations,starts,starts_ns):

    # Time is converted to the time from the start time of the file.
    tmpstart=start-tfile
    tmpstart+=1e-9*startns
    tmpend=tmpstart+duration

    # segments of this trigger. 
    tmpTriggered = DataQualityFlag(known=[(0,omicron_interval)],active=[(tmpstart,tmpend)])

    # Added to the segments of this file.
    Triggered |= tmpTriggered
    
    
    
# Get active segments. 
tmpactive=Triggered.active

# Get trigger channel. Assumed that 1 omicron file contains only 1 channel.
#print(channel)

# Get DQflag.
#safety is contracting time.
safety=1

#locked=mylib.GetDQFlag(tfile-safety, tfile+omicron_interval+safety, config="IMC",min_len=safety*3,kamioka=True)
locked=mylib.GetDQFlag(tfile-safety, tfile+omicron_interval+safety, config="MICH",min_len=safety*3,kamioka=True)
locked_contract=locked.copy()
locked=locked.active
locked_contract=locked_contract.contract(1)
unlocked_contract=~locked_contract

print("locked")
print(locked)
print("unlocked_contract")
print(unlocked_contract)

# Loop over active segments.
for segment in tmpactive:
    tmpstart=segment.start
    tmpend=segment.end

    # strtmp is parameter string to be passed to condor_jobfile_plotter.sh.
    # strtmp = [starttime in gps] [channel] [min_duration] [max_duration] [bandwidth] [maxSNR] [frequency_snr] [max_amp] [frequency_amp]

    time=tfile+tmpstart

    segment_shift=segment.shift(tfile)

    # Discriminate glitch and lock loss if not PEM channel.

    
    Islocked=locked.intersects_segment(segment_shift)
    if not Islocked:
        eventtype="plotter"
        continue
    else:    
        Islockloss=unlocked_contract.intersects_segment(segment_shift)
        if Islockloss:
            eventtype="lockloss"
        else:
            eventtype="glitch"


#        Islockloss=unlocked_contract.intersects_segment(segment_shift)
#        if Islockloss:
#            eventtype="lockloss"
#        else:


    # From all trigger, extract those in the segmants.
    # sec. order
    tmpevents=events.filter(('peak_time', mylib.between,(int(tmpstart)+tfile,int(tmpend+1)+tfile)))

    # nsec. order
    tmpstartns=(tmpstart-math.floor(tmpstart))*1e9
    tmpendns=(tmpend-math.floor(tmpend))*1e9
    #    tmpevents=tmpevents.filter(('peak_time_ns', mylib.between,(tmpstartns,tmpendns)))

    # if events are in a same gps sec.
    if int(tmpstart) == int(tmpend):
        tmpevents=tmpevents.filter(('peak_time_ns', mylib.between,(tmpstartns,tmpendns)))
    # if events are not in a same gps sec.
    # first and last sec need nsec filter.
    else:
        # sec. order filter
        tmpevents2=tmpevents.filter(('peak_time', mylib.IsSame,int(tmpstart)+tfile))
        # nsec. order filter
        tmptmpevents=tmpevents2.filter(('peak_time_ns', mylib.Islarger,int(tmpstartns)))

        # Loop over sec. that is fully included in the segment.
        for peak_time in range(int(tmpstart)+tfile+1,int(tmpend)+tfile):
            tmpevents3=tmpevents.filter(('peak_time', mylib.IsSame,peak_time))
            tmptmpevents=vstack([tmptmpevents,tmpevents3])
        tmpevents2=tmpevents.filter(('peak_time', mylib.IsSame,int(tmpend)+tfile))
        tmpevents2=tmpevents2.filter(('peak_time_ns', mylib.Issmaller,int(tmpendns)))
        # final result
        tmpevents=vstack([tmptmpevents,tmpevents2])


    #duration

    #initialize
    max_duration = tmpend-tmpstart
    min_duration=100
    
    durations = tmpevents.get_column('duration')

    for duration in durations:
        if min_duration > duration:
            min_duration = duration
                
    #bandwidth
    
    bandwidths = tmpevents.get_column('bandwidth')
    #initialize
    min_bandwidth=10000
    max_bandwidth=0
    i=0.
    mean_bandwidth=0
    for bandwidth in bandwidths:
        mean_bandwidth+=bandwidth
        i+=1.
        if min_bandwidth > bandwidth:
            min_bandwidth = bandwidth
        if max_bandwidth < bandwidth:
            max_bandwidth = bandwidth

    mean_bandwidth=mean_bandwidth/i

    #SNR, frequency

    #initialize
    max_snr = 0
    snrs = tmpevents.get_column('snr')
    frequencys = tmpevents.get_column('peak_frequency')

    for snr,frequency in zip(snrs,frequencys):
        if max_snr < snr:
            max_snr = snr
            peakfrequency=frequency

    #Amplitude, frequency

    #initialize
    max_amp = 0
    amplitudes = tmpevents.get_column('amplitude')

    for amplitude,frequency in zip(amplitudes,frequencys):
        if max_amp < amplitude:
            max_amp = amplitude
            peakfrequency_amp=frequency
    
    strtmp=""
    strtmp+=str(time)
    
    strtmp+=" K1:"
    strtmp+=str(channel)

    strtmp+=(" ")
    strtmp+=str(min_duration)
    strtmp+=(" ")
    strtmp+=str(max_duration)

    strtmp+=(" ")
    strtmp+=str(min_bandwidth)

    strtmp+=(" ")
    strtmp+=str(max_snr)
    strtmp+=(" ")
    strtmp+=str(peakfrequency)
    
    strtmp+=(" ")
    strtmp+=str(max_amp)
    strtmp+=(" ")
    strtmp+=str(peakfrequency_amp)

    strtmp+=(" ")
    strtmp+=str(eventtype)

    strtmp+=(" ")
    strtmp+=str(triggertype)

    f.write(strtmp)
    f.write('\n')

f.close()
