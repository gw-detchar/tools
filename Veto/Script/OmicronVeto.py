'''
This script will make basic plots from glitch information.
'''

from mylib import mylib 
import glob
from gwpy.table import EventTable
from astropy.table import vstack
from gwpy.segments import DataQualityFlag
from gwpy.segments import Segment
#import ROOT
from ROOT import gROOT, gDirectory, gPad, gSystem, gStyle
from ROOT import TH1D, TH2D, TH1I, TFile

import argparse

parser = argparse.ArgumentParser(description='Make trigger veto segments.')
parser.add_argument('-i','--inputfile',help='input trigger filename.',default='/home/controls/triggers/K1/CAL_CS_PROC_DARM_DISPLACEMENT_DQ_OMICRON/12613/K1-CAL_CS_PROC_DARM_DISPLACEMENT_DQ_OMICRON-1261368618-60.xml.gz')
parser.add_argument('-o','--outfile',help='Output veto segment file.',default='test.xml')
parser.add_argument('-s','--snr',help='Veto SNR threshold.',default=100)

args = parser.parse_args()
inputfile = args.inputfile
outfile = args.outfile
# force the outfile name to be xml.
if outfile[-4:] !=  '.xml':
    outfile = outfile + '.xml'

SNR = args.snr
# Open omicron file

# get the time of the input file.
tmp=inputfile.rsplit("-",2)
tfile=int(tmp[1])

gpsstart = tfile
length=int(tmp[2].split(".")[0])

gpsend = tfile+length

sources = [inputfile]

first = True

for source in sources:
    #events = EventTable.read('K1-IMC_CAV_ERR_OUT_DQ_OMICRON-1241900058-60.xml.gz', tablename='sngl_burst', columns=['peak_time', 'peak_time_ns', 'start_time', 'start_time_ns', 'duration', 'peak_frequency', 'central_freq', 'bandwidth', 'channel', 'amplitude', 'snr', 'confidence', 'chisq', 'chisq_dof', 'param_one_name', 'param_one_value'])
    events = EventTable.read(source, tablename='sngl_burst', columns=['peak_time', 'peak_time_ns', 'start_time', 'start_time_ns', 'duration', 'peak_frequency', 'central_freq', 'bandwidth', 'channel', 'amplitude', 'snr', 'confidence', 'chisq', 'chisq_dof', 'param_one_name', 'param_one_value'])
    col = events.get_column('peak_time')
    print(events)
    if first:
        if len(col) > 0 :
            mergedevents=events
            first=False
        else:
            pass
    else:
        mergedevents=vstack([mergedevents, events])

channel = (mergedevents.get_column('channel'))[0]

Triggered = DataQualityFlag(name = "Omicron", known=[(gpsstart,gpsend)],active=[], label = "Science-mode", description = "Science-mode")
Triggered.ifo = "K1"

# Tablename option
#'process', 'process_params', 'sngl_burst', 'segment_definer', 'segment_summary', 'segment'
# Column option
#ifo peak_time peak_time_ns start_time start_time_ns duration search process_id event_id peak_frequency central_freq bandwidth channel amplitude snr confidence chisq chisq_dof param_one_name param_one_value
    
# Apply filter. 
    
fevents = mergedevents.filter(('snr', mylib.Islargerequal, SNR))
        
peak_times = fevents.get_column('peak_time')
peak_time_nss = fevents.get_column('peak_time_ns')
durations = fevents.get_column('duration')
start_times = fevents.get_column('start_time')
start_time_nss = fevents.get_column('start_time_ns')

# col can be used like array. col[0] will give first value.
            
for peak_time,peak_time_ns,duration,start_time,start_time_ns in zip(peak_times,peak_time_nss,durations,start_times,start_time_nss):

    #tmpstart=start_time-tfile
    tmpstart=start_time
    tmpstart+=start_time_ns*1e-9
    tmpend=tmpstart+duration
    tmpstart=round(tmpstart,4)
    tmpend=round(tmpend,4)
    
    tmpTriggered = DataQualityFlag(known=[(gpsstart,gpsend)],active=[(tmpstart,tmpend)])
    Triggered |= tmpTriggered

#if kamioka:
#    fname='/users/.ckozakai/KashiwaAnalysis/analysis/code/gwpy/trigger/triggerStudy/condor/'+date+'/segment/'+date+'_segment_SNR' + str(SNR) + '_' + channel + '_' + str(tfile) +'_60.xml'
#else:
#    fname='/home/chihiro.kozakai/detchar/analysis/code/gwpy/trigger/triggerStudy/condor/'+date+'/segment/'+date+'_segment_SNR' + str(SNR) + '_' + channel + '_' + str(tfile) +'_60.xml'
        
#Triggered.write(fname,overwrite=True)
Triggered.write(outfile,overwrite=True)
print(Triggered)

txt = outfile.replace('.xml','.txt')
with open(txt, mode='w') as f:
    for seg in Triggered.active :
        #f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
        f.write('{0} {1}\n'.format(seg[0], seg[1]))
