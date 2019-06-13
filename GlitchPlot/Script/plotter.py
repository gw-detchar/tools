'''
This script will make basic plots from glitch information.
'''

import math
from gwpy.table import EventTable
from gwpy.segments import DataQualityFlag
from gwpy.table.filters import in_segmentlist
#import ROOT
from ROOT import gROOT, gDirectory, gPad, gSystem, gStyle
from ROOT import TH1D, TH2D, TH1I, TCanvas
from mylib import mylib
import matplotlib
matplotlib.use('Agg')  # this line is required for the batch job before importing other matplotlib modules.

# argument processing

import argparse

parser = argparse.ArgumentParser(description='Make basic plots.')
parser.add_argument('-o','--output',help='output text filename.',default='result.txt')
parser.add_argument('-i','--inputfile',help='input trigger filename.',default='/home/controls/triggers/K1/LSC_CARM_SERVO_MIXER_DAQ_OUT_DQ_OMICRON/12440/K1-LSC_CARM_SERVO_MIXER_DAQ_OUT_DQ_OMICRON-1244013258-60.xml.gz')

args = parser.parse_args()
output = args.output
inputfile = args.inputfile

# Open omicron file

#events = EventTable.read('K1-IMC_CAV_ERR_OUT_DQ_OMICRON-1241900058-60.xml.gz', tablename='sngl_burst', columns=['peak_time', 'peak_time_ns', 'start_time', 'start_time_ns', 'duration', 'peak_frequency', 'central_freq', 'bandwidth', 'channel', 'amplitude', 'snr', 'confidence', 'chisq', 'chisq_dof', 'param_one_name', 'param_one_value'])
events = EventTable.read(inputfile, tablename='sngl_burst', columns=['peak_time', 'peak_time_ns', 'start_time', 'start_time_ns', 'duration', 'peak_frequency', 'central_freq', 'bandwidth', 'channel', 'amplitude', 'snr', 'confidence', 'chisq', 'chisq_dof', 'param_one_name', 'param_one_value'])
# Tablename option
#'process', 'process_params', 'sngl_burst', 'segment_definer', 'segment_summary', 'segment'
# Column option
#ifo peak_time peak_time_ns start_time start_time_ns duration search process_id event_id peak_frequency central_freq bandwidth channel amplitude snr confidence chisq chisq_dof param_one_name param_one_value

# Apply filter. 

snrthreshold=100.    
fevents = events.filter(('snr', mylib.Islarger,  snrthreshold))
fevents.write('test.txt',format='ascii',overwrite=True)


# Makesegments of triggers. It will give information about interesting gps time. 

# Get trigger parameters
peak_times = fevents.get_column('peak_time')
peak_time_nss = fevents.get_column('peak_time_ns')
peak_frequencys = fevents.get_column('peak_frequency')
snrs = fevents.get_column('snr')
durations = fevents.get_column('duration')
starts = fevents.get_column('start_time')
starts_ns = fevents.get_column('start_time_ns')
# columns can be used like array. col[0] will give first value.

# get the time of the input file.
tmp=inputfile.rsplit("-",2)
tfile=int(tmp[1])

c = TCanvas()

# Initialize segments of trigger. t=0 is the start of the trigger file.
omicron_interval = 60.
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
    
# Find interesting bin from histogram.

# Get active segments. 
tmpactive=Triggered.active

# Setup output txtfile.
f = open(output, mode='w')

# Loop over active segments.
for segment in tmpactive:
    tmpstart=segment.start
    tmpend=segment.end

    # strtmp is parameter string to be passed to condor_jobfile_plotter.sh.
    # strtmp = [starttime in gps] [channel] [min_duration] [max_duration] [bandwidth] [maxSNR] [frequency_snr] [max_amp] [frequency_amp]
    strtmp=""
    time=tfile+tmpstart
    strtmp+=str(time)

    #print("time="+str(time))

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

    print(tmpevents)
    # Get trigger channel. Assumed that 1 omicron file contains only 1 channel.
    channel = (tmpevents.get_column('channel'))[0]
    #print(channel)
    strtmp+=" K1:"
    strtmp+=str(channel)
    
    #duration

    #initialize
    max_duration = tmpend-tmpstart
    min_duration=100
    
    durations = tmpevents.get_column('duration')

    for duration in durations:
        if min_duration > duration:
            min_duration = duration
            
    strtmp+=(" ")
    strtmp+=str(min_duration)
    strtmp+=(" ")
    strtmp+=str(max_duration)
    
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
    strtmp+=(" ")
    strtmp+=str(min_bandwidth)

    #SNR, frequency

    #initialize
    max_snr = 0
    snrs = tmpevents.get_column('snr')
    frequencys = tmpevents.get_column('peak_frequency')

    for snr,frequency in zip(snrs,frequencys):
        if max_snr < snr:
            max_snr = snr
            peakfrequency=frequency
    strtmp+=(" ")
    strtmp+=str(max_snr)
    strtmp+=(" ")
    strtmp+=str(peakfrequency)

    #Amplitude, frequency

    #initialize
    max_amp = 0
    amplitudes = tmpevents.get_column('amplitude')

    for amplitude,frequency in zip(amplitudes,frequencys):
        if max_amp < amplitude:
            max_amp = amplitude
            peakfrequency=frequency
    strtmp+=(" ")
    strtmp+=str(max_amp)
    strtmp+=(" ")
    strtmp+=str(peakfrequency)

    f.write(strtmp)
    f.write('\n')

f.close()
