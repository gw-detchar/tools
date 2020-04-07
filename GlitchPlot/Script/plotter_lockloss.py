'''
This script will make basic plots from lock loss information.
'''

import os
import subprocess
from gwpy.segments import DataQualityFlag

# Set parameters
import argparse

parser = argparse.ArgumentParser(description='Make basic plots.')
#parser.add_argument('-o','--output',help='output text filename.',default='result.txt')
parser.add_argument('-i','--inputfile',help='input xml segment filename.',default='/home/detchar/Segments/K1-GRD_LOCKED/2020/K1-GRD_LOCKED_SEGMENT_UTC_2020-04-05.xml')
parser.add_argument('-c','--channel',help='Main channel name.',default='K1:CAL-CS_PROC_DARM_DISPLACEMENT_DQ')
parser.add_argument('-s','--start',help='Starting GPS time.',type=int,default=1270141394)
parser.add_argument('-e','--end',help='Ending GPS time. Please specify either -e or -l.',type=int,default=0)
parser.add_argument('-d','--duration',help='Data length from start. Please specify either -e or -l.',type=int,default=4000)
parser.add_argument('-l','--llabel',help='Lock state label.',default='IFO')
parser.add_argument('-n','--nmax',help='Maximum number of events to process. If -1 is given, all the events are processed.',type=int,default=1)

args = parser.parse_args()
inputfile = args.inputfile
mainchannel = args.channel
start = args.start
end = args.end
duration = args.duration
nmax = args.nmax
llabel = args.llabel

# Get channel list
f = open('/home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/'+mainchannel+".dat")
allchannels = f.read().split()
f.close()

# Get lock segments
DQflag = DataQualityFlag.read(inputfile)

if end == 0:
    end = start+duration

Valid = DataQualityFlag(known=[(start,end)],active=[(start,end)])

DQflag = DQflag & Valid
if nmax < 0:
    nmax = len(DQflag.active)

# Get date 
cmd = "gpstime "+str(start)
info = subprocess.check_output(cmd.split())
date = info.split()[1].replace("-","")

# Make header of condor sdf files
suggestionsdf = "job_lockloss_suggestion.sdf"
locksdf = "job_lockloss_lock.sdf"
timesdf = "job_lockloss_time.sdf"
spectrumsdf = "job_lockloss_spectrum.sdf"
spectrogramsdf = "job_lockloss_spectrogram.sdf"
coherencegramsdf = "job_lockloss_coherencegram.sdf"
qtransformsdf = "job_lockloss_qtransform.sdf"

with open(suggestionsdf,mode="w") as f:
    string = '\
PWD = (SUBMIT_FILE)\n\
transfer_input_files = rm_if_empty.sh\n\
+PostCmd = "rm_if_empty.sh"\n\
+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"\n\
Executable = /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/run_suggestion.sh\n\
Universe   = vanilla\n\
Notification = never\n\
request_memory = 10 GB\n\
Getenv  = True\n\
\n\
should_transfer_files = YES\n\
when_to_transfer_output = ON_EXIT\n\
\n\
Output       = log/'+date+'/$(Cluster).$(Process).out\n\
Error       = log/'+date+'/$(Cluster).$(Process).err\n\
'
    f.write(string)

with open(locksdf,mode="w") as f:
    string = '\
PWD = (SUBMIT_FILE)\n\
transfer_input_files = rm_if_empty.sh\n\
+PostCmd = "rm_if_empty.sh"\n\
+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"\n\
Executable = /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/run_locksegments.sh\n\
Universe   = vanilla\n\
Notification = never\n\
request_memory = 10 GB\n\
Getenv  = True\n\
\n\
should_transfer_files = YES\n\
when_to_transfer_output = ON_EXIT\n\
\n\
Output       = log/'+date+'/$(Cluster).$(Process).out\n\
Error       = log/'+date+'/$(Cluster).$(Process).err\n\
'
    f.write(string)

with open(timesdf,mode="w") as f:
    string = '\
PWD = (SUBMIT_FILE)\n\
transfer_input_files = rm_if_empty.sh\n\
+PostCmd = "rm_if_empty.sh"\n\
+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"\n\
Executable = /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/run_timeseries.sh\n\
Universe   = vanilla\n\
Notification = never\n\
request_memory = 10 GB\n\
Getenv  = True\n\
\n\
should_transfer_files = YES\n\
when_to_transfer_output = ON_EXIT\n\
\n\
Output       = log/'+date+'/$(Cluster).$(Process).out\n\
Error       = log/'+date+'/$(Cluster).$(Process).err\n\
'
    f.write(string)

with open(spectrumsdf,mode="w") as f:
    string = '\
PWD = (SUBMIT_FILE)\n\
transfer_input_files = rm_if_empty.sh\n\
+PostCmd = "rm_if_empty.sh"\n\
+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"\n\
Executable = /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/run_spectrum.sh\n\
Universe   = vanilla\n\
Notification = never\n\
request_memory = 10 GB\n\
Getenv  = True\n\
\n\
should_transfer_files = YES\n\
when_to_transfer_output = ON_EXIT\n\
\n\
Output       = log/'+date+'/$(Cluster).$(Process).out\n\
Error       = log/'+date+'/$(Cluster).$(Process).err\n\
'
    f.write(string)

with open(spectrogramsdf,mode="w") as f:
    string = '\
PWD = (SUBMIT_FILE)\n\
transfer_input_files = rm_if_empty.sh\n\
+PostCmd = "rm_if_empty.sh"\n\
+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"\n\
Executable = /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/run_whitening_spectrogram.sh\n\
Universe   = vanilla\n\
Notification = never\n\
request_memory = 10 GB\n\
Getenv  = True\n\
\n\
should_transfer_files = YES\n\
when_to_transfer_output = ON_EXIT\n\
\n\
Output       = log/'+date+'/$(Cluster).$(Process).out\n\
Error       = log/'+date+'/$(Cluster).$(Process).err\n\
'
    f.write(string)

with open(coherencegramsdf,mode="w") as f:
    string = '\
PWD = (SUBMIT_FILE)\n\
transfer_input_files = rm_if_empty.sh\n\
+PostCmd = "rm_if_empty.sh"\n\
+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"\n\
Executable = /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/run_coherencegram.sh\n\
Universe   = vanilla\n\
Notification = never\n\
request_memory = 10 GB\n\
Getenv  = True\n\
\n\
should_transfer_files = YES\n\
when_to_transfer_output = ON_EXIT\n\
\n\
Output       = log/'+date+'/$(Cluster).$(Process).out\n\
Error       = log/'+date+'/$(Cluster).$(Process).err\n\
'
    f.write(string)

with open(qtransformsdf,mode="w") as f:
    string = '\
PWD = (SUBMIT_FILE)\n\
transfer_input_files = rm_if_empty.sh\n\
+PostCmd = "rm_if_empty.sh"\n\
+PostArguments = "_condor_stderr _condor_stdout $(PWD)/$(Output) $(PWD)/$(Error) $(PWD)/$(Log)"\n\
Executable = /home/chihiro.kozakai/detchar/KamiokaTool/tools/GlitchPlot/Script/run_qtransform.sh\n\
Universe   = vanilla\n\
Notification = never\n\
request_memory = 10 GB\n\
Getenv  = True\n\
\n\
should_transfer_files = YES\n\
when_to_transfer_output = ON_EXIT\n\
\n\
Output       = log/'+date+'/$(Cluster).$(Process).out\n\
Error       = log/'+date+'/$(Cluster).$(Process).err\n\
'
    f.write(string)

# Fill condor submission file for each events
for i in range(0,nmax):
    # Get lock loss GPS time.
    tLL = int(DQflag.active[i][1])

    # skip if end of segment is end of segment file.
    if tLL == DQflag.known[-1][1]:
        break

    # Plot setting

    # time for plots with time axis
    tstart = tLL - 10
    tend = tLL + 1

    # time for spectrum
    sstart = tLL - 42
    send = tLL - 10

    # Output directory
    eventname = "lockloss_"+str(tLL)+"_"+mainchannel
    outdir = "/home/chihiro.kozakai/public_html/KAGRA/GlitchPlot/"+date+"/"+eventname+"/"
    if not os.path.isdir(outdir):
        os.makedirs(outdir)

    # Make condor submission files
    
    # Suggestion
    with open(suggestionsdf,mode="a") as f:
        string = '\
Arguments = -st '+str(tLL-1)+' -et '+str(tLL)+' -sq '+str(tstart)+' -eq '+str(tend)+' -o '+outdir+' -r '+mainchannel+' --Qonly \n\
Queue\n'
        f.write(string)
    
    # Lock segments
    with open(locksdf,mode="a") as f:
        string = '\
Arguments = -s '+str(tstart)+' -e '+str(tend)+' -t '+str(tLL)+' -d 1 -o '+outdir+' -i '+mainchannel+' \n\
Queue\n'
        f.write(string)
    
    # Timeseries

    with open(timesdf,mode="a") as f:
        for channel in allchannels:
            string = '\
Arguments = -s '+str(tstart)+' -e '+str(tend)+' --llabel '+llabel+' -d full -o '+outdir+' -c '+channel+' -i '+mainchannel+' --nolegend --dpi 50\n\
Queue\n'
            f.write(string)

    # Spectrum

    with open(spectrumsdf,mode="a") as f:
        for channel in allchannels:
            string = '\
Arguments = -s '+str(sstart)+' -e '+str(send)+' -o '+outdir+' -c '+channel+' -i '+mainchannel+' -f 1 -t time --title Before --dpi 50\n\
Queue\n'
            f.write(string)
    
    # Spectrogram

    with open(spectrogramsdf,mode="a") as f:
        for channel in allchannels:
            string = '\
Arguments = -s '+str(tstart)+' -e '+str(tend)+' --llabel '+llabel+' -o '+outdir+' -c '+channel+' -i '+mainchannel+' -f 0.125 --stride 0.25 --dpi 50\n\
Queue\n\
Arguments = -s '+str(tstart)+' -e '+str(tend)+' --llabel '+llabel+' -o '+outdir+' -c '+channel+' -i '+mainchannel+' -f 0.125 --stride 0.25 --dpi 50 -w \n\
Queue\n'
            f.write(string)

    # Coherencegram

    with open(coherencegramsdf,mode="a") as f:
        for channel in allchannels:
            string = '\
Arguments = -s '+str(tstart)+' -e '+str(tend)+' --llabel '+llabel+' -o '+outdir+' -c '+channel+' -r '+mainchannel+' -i '+mainchannel+' -f 0.125 --stride 0.25 --dpi 50\n\
Queue\n'
            f.write(string)

    # Q-transform

    with open(qtransformsdf,mode="a") as f:
        for channel in allchannels:
            string = '\
Arguments = -s '+str(tstart)+' -e '+str(tend)+' --llabel '+llabel+' -o '+outdir+' -c '+channel+' -i '+mainchannel+' --dpi 50\n\
Queue\n'
            f.write(string)

