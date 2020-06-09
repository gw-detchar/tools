import glob
from gwpy.segments import DataQualityFlag
from gwpy.segments import SegmentList

import argparse

parser = argparse.ArgumentParser(description='Check Omicron output file.')
parser.add_argument('-f','--freq',help='sampling frequency. 256 or 512 or 1024 or 2048 or 4096.',default='4096')
parser.add_argument('-y','--year',help='year.',default='2020')
parser.add_argument('-m','--month',help='month.',default='04')
parser.add_argument('-d','--day',help='day.',default='07')

args = parser.parse_args()

freq = args.freq
year = args.year
month = args.month
day = args.day

if len(month) < 2:
    month = "0"+month
if len(day) < 2:
    day = "0"+day

#=============Get locked segments=============
#locked = DataQualityFlag.read("/users/DET/Segments/K1-GRD_LOCKED/2020/K1-GRD_LOCKED_SEGMENT_UTC_2020-04-17.xml")
#locked = DataQualityFlag.read("/users/DET/Segments/K1-GRD_LOCK_STATE_N_EQ_1000/2020/K1-GRD_LOCK_STATE_N_EQ_1000_SEGMENT_UTC_2020-04-15.xml")
locked = DataQualityFlag.read("/users/DET/Segments/K1-GRD_SCIENCE_MODE/"+year+"/K1-GRD_SCIENCE_MODE_SEGMENT_UTC_"+year+"-"+month+"-"+day+".xml")

# Remove segments shorter than 94 sec

act = SegmentList()
for seg in locked.active:
    duration = seg[1]-seg[0]
    if duration >= 94:
        act.append(seg)

# Remove last 30 sec and margin 2 sec
act = act.contract(17)
act=act.shift(-15)
locked.active = act

#=============Get omicron succeeded segments=============

omicron = DataQualityFlag(known = locked.known,)
gpsstart = locked.known[0][0]
gpsend = locked.known[0][1]
#gpsstart = 1270944018
#gpsend = 1271030418
#omicron = DataQualityFlag(name="Omicron",known = [(gpsstart,gpsend)])

channels = []
with open("/users/DET/tools/Omicron/Parameter/O3rerun_"+freq+".txt") as f:
    lines = f.readlines()
    for line in lines:
        if "DATA CHANNELS " in line:
            channel=line.split()[-1]
            channels.extend([channel])

for channel in channels:

    tmpchannel = channel.replace("K1:","")
    tmpchannel = tmpchannel.replace("-","_")
    files = []

    for i in range(int(gpsstart/100000),int(gpsend/100000)+1):
        #tmp = glob.glob("/home/controls/triggers/K1/CAL_CS_PROC_DARM_DISPLACEMENT_DQ_OMICRON/"+str(i)+"/K1-CAL_CS_PROC_DARM_DISPLACEMENT_DQ_OMICRON-*")
        tmp = glob.glob("/home/controls/triggers/K1/"+tmpchannel+"_OMICRON/"+str(i)+"/*")
        files.extend(tmp)

    files.sort()
    
    for fname in files:
        start = int(fname.rsplit('-',2)[1])
        duration = fname.rsplit('-',2)[2]
        duration = int(duration.split('.')[0])
        tmp = DataQualityFlag(known = omicron.known, active = [(start, start+duration)])
        omicron += tmp

    #=============Get omicron failed segments=============

    failed = DataQualityFlag(name="Failed",known = [(gpsstart,gpsend)])

    #with open("/users/DET/tools/Omicron/Script/log200428.dat") as f:  # for 4/14-20
    #with open("/users/DET/tools/Omicron/Script/log200519_4096.dat") as f:  # for 4/15
    #with open("/users/DET/tools/Omicron/Script/log200519_256-1024.dat") as f:  # for 4/15
    #with open("/users/DET/tools/Omicron/Script/log200521_2048.dat") as f:  # for 4/15
    with open("/users/DET/tools/Omicron/Script/log200602_20"+month+""+day+"_"+freq+".dat") as f:  # for O3GK
    #with open("/users/DET/tools/Omicron/Script/log200504.dat") as f:  # for 4/7-12
        lines = f.readlines()
        for line in lines:
            if "Omicron::ExtractTriggers: the maximum trigger rate (5000.00000 Hz) is exceeded ("+channel+" " in line:
                time=line.split()[-1]
                tmpstart = int(time.split("-")[0])
                tmpend = int(time.split("-")[1][0:10])
                tmp = DataQualityFlag(known = failed.known, active = [(tmpstart, tmpend)])
                failed += tmp

    unknown = locked - omicron
    unknown -= failed

    if len(failed.active) > 0 or len(unknown.active) > 0:
        print(channel)
        print("Locked segments")
        print(locked)
        print("Omicron succeeded")
        print(omicron)
        print("Omicron failed")
        print(failed)
        
        print("Unknown segments")
        print(unknown)

    with open("unknownSegments0602_"+year+month+day+"_"+freq+"_"+channel+".txt", mode='w') as f:
        for seg in unknown.active :
            f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
    with open("failedSegments0602_"+year+month+day+"_"+freq+"_"+channel+".txt", mode='w') as f:
        for seg in failed.active :
            f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
    with open("succeededSegments0602_"+year+month+day+"_"+freq+"_"+channel+".txt", mode='w') as f:
        for seg in omicron.active :
            f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))

