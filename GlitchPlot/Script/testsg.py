'''
This is to extract interesting channel in GlitchPlot. 
The requirement is
* The coherence is usually small
* The coherence increases during glitch

Author: Chihiro Kozakai
'''

__author__ = "Chihiro Kozakai"

import numpy as np

import matplotlib
matplotlib.use('Agg')  # this line is required for the batch job before importing other matplotlib modules.

from gwpy.timeseries import TimeSeries
from gwpy.timeseries import TimeSeriesDict

from mylib import mylib

from matplotlib import pylab as pl
pl.rcParams['font.size'] = 16
pl.rcParams['font.family'] = 'Verdana'

#  argument processing                                                                                             
import argparse

parser = argparse.ArgumentParser(description='Make coherencegram.')
parser.add_argument('-o','--outdir',help='output directory.',default='/tmp')
parser.add_argument('-r','--refchannel',help='main reference channel.',required=True)
#parser.add_argument('-c','--channel',help='compared channel.',default='K1:PEM-SEIS_IXV_GND_UD_IN1_DQ')#required=True)
parser.add_argument('-s','--gpsstartbefore',help='GPS starting time for before trigger.',required=True)
parser.add_argument('-e','--gpsendbefore',help='GPS ending time for before trigger.',required=True)
parser.add_argument('-st','--gpsstarttrigger',help='GPS starting time for during trigger.',required=True)
parser.add_argument('-et','--gpsendtrigger',help='GPS ending time for during trigger.',required=True)
parser.add_argument('-sq','--gpsstartqgram',help='GPS starting time for GlitchPlot.',required=True)
parser.add_argument('-eq','--gpsendqgram',help='GPS ending time for GlitchPlot.',required=True)
parser.add_argument('-f','--fftlength',help='FFT length.',type=float,default=1.)
parser.add_argument('-ft','--frequency',help='Frequency of the trigger.',type=float,default=100)
parser.add_argument('-k','--kamioka',help='Flag to run on Kamioka server.',action='store_true')

# define variables                                                                                                 
args = parser.parse_args()

kamioka = args.kamioka

outdir=args.outdir

refchannel=args.refchannel

gpsstart=args.gpsstartbefore
gpsend=args.gpsendbefore

gpsstartT=args.gpsstarttrigger
gpsendT=args.gpsendtrigger

gpsstartQ=args.gpsstartqgram
gpsendQ=args.gpsendqgram

frequency = args.frequency

fft=args.fftlength
ol=fft/2.  #  overlap in FFTs.

# Make coherence before trigger
# Get data from frame files                                                                                        
if kamioka:
    sources = mylib.GetFilelist_Kamioka(gpsstart,gpsend)
else:
    sources = mylib.GetFilelist(gpsstart,gpsend)

f = open('/home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/'+refchannel+".dat")
channels = f.read().split()
f.close()

data = TimeSeriesDict.read(sources,channels,format='gwf.lalframe',start=float(gpsstart),end=float(gpsend))

if kamioka:
    sources = mylib.GetFilelist_Kamioka(gpsstartT,gpsendT)
else:
    sources = mylib.GetFilelist(gpsstartT,gpsendT)

dataT = TimeSeriesDict.read(sources,channels,format='gwf.lalframe',start=float(gpsstartT),end=float(gpsendT))

margin=4

gpsstartmargin=float(gpsstartQ)-margin
gpsendmargin=float(gpsendQ)+margin

if kamioka:
    sources = mylib.GetFilelist_Kamioka(gpsstartmargin,gpsendmargin)
else:
    sources = mylib.GetFilelist(gpsstartmargin,gpsendmargin)

dataQ = TimeSeriesDict.read(sources,channels,format='gwf.lalframe',start=float(gpsstartmargin),end=float(gpsendmargin))

# Loop over channel. 

detected = []
for channel in channels:

    ref = data[refchannel]
    com = data[channel]

    if fft < ref.dt.value:
        fft=2*ref.dt.value
        ol=fft/2.  #  overlap in FFTs.                                                                                 
        print("Given fft/stride was bad against the sampling rate. Automatically set to:")
        print("fft="+str(fft))
        print("ol="+str(ol))

    if fft < com.dt.value:
        fft=2*com.dt.value
        ol=fft/2.  #  overlap in FFTs.                                                                                 
        print("Given fft/stride was bad against the sampling rate. Automatically set to:")
        print("fft="+str(fft))
        print("ol="+str(ol))

    cohbefore = ref.coherence(com,fftlength=fft,overlap=ol)

    # Make coherence for trigger time

    refT = dataT[refchannel]
    comT = dataT[channel]

    cohtrigger = refT.coherence(comT,fftlength=fft,overlap=ol)

    # Get nearest frequency bin index of the glitch
    diff=np.abs(np.asarray(cohbefore.frequencies)-frequency).argmin()
    
    if cohbefore.value[diff] < 0.2 and cohtrigger.value[diff] > 0.5:
        print("Detected ! "+channel)
        detected.append(channel)

    # Using Qtransform

    data = dataQ[channel]
    qgram = data.q_transform(outseg=[float(gpsstartQ),float(gpsendQ)],qrange=(qmin,qmax),gps=float(gpsstartQ)/2.+float(gpsendQ)/2.,logf=True)

    break

print(detected)
with open(outdir+"suggestion.txt", mode='w') as f:
    f.write('\n'.join(detected))