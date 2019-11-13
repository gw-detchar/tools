'''
This is to extract interesting channel in GlitchPlot. 
The requirement is
* The coherence is usually small, <0.2
* The coherence increases during glitch, >0.5

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
parser.add_argument('-q','--q',help='Q range.',default=-1,type=float )
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

qmin = 4
qmax = 100

if args.q > 0:
    qmin = args.q
    qmax = args.q

# Make coherence before trigger
# Get data from frame files                                                                                        
if kamioka:
    sources = mylib.GetFilelist_Kamioka(gpsstart,gpsend)
else:
    sources = mylib.GetFilelist(gpsstart,gpsend)

f = open('/home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/'+refchannel+".dat")
channels = f.read().split()
f.close()
#channels=['K1:CAL-CS_PROC_C00_STRAIN_DBL_DQ','K1:CAL-CS_PROC_DARM_DELTA_CTRL_MN_DBL_DQ']

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

detectedc = []
detectedq = []
notdetected = []

ref = data[refchannel]
refT = dataT[refchannel]
for channel in channels:

    lowSRflag=False

    if 'K1:LSC' in channel or 'K1:CAL' in channel:
        notdetected.append(channel)
        continue

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
        lowSRflag=True
        print("Given fft/stride was bad against the sampling rate. Automatically set to:")
        print("fft="+str(fft))
        print("ol="+str(ol))

    cohbefore = ref.coherence(com,fftlength=fft,overlap=ol)

    # Make coherence for trigger time

    comT = dataT[channel]

    cohtrigger = refT.coherence(comT,fftlength=fft,overlap=ol)

    # Get nearest frequency bin index of the glitch
    diff=np.abs(np.asarray(cohbefore.frequencies)-frequency).argmin()
    
    if cohbefore.value[diff] < 0.2 and cohtrigger.value[diff] > 0.5:
        detectedc.append(channel)
        continue

    # Using Qtransform

    if loaSRflag:
        notdetected.append(channel)
        continue

    comQ = dataQ[channel]

    qgram = comQ.q_gram(qrange=(qmin,qmax),snrthresh=5.5)

    qgram = qgram.filter(('time', mylib.between,  (float(gpsstartT)-1.,float(gpsendT))))

    if len(qgram) > 0: 
        detectedq.append(channel)
        continue

    notdetected.append(channel)

print(detectedc)
print(detectedq)
with open(outdir+"/suggestion1.txt", mode='w') as f:
    f.write('\n'.join(detectedc))
with open(outdir+"/suggestion2.txt", mode='w') as f:
    f.write('\n'.join(detectedq))
with open(outdir+"/notsuggestion.txt", mode='w') as f:
    f.write('\n'.join(notdetected))

print(outdir+"suggestion1.txt")
print(outdir+"suggestion2.txt")
