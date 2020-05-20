import glob
from gwpy.segments import DataQualityFlag

#=============Get locked segments=============
#locked = DataQualityFlag.read("/users/DET/Segments/K1-GRD_LOCKED/2020/K1-GRD_LOCKED_SEGMENT_UTC_2020-04-17.xml")
locked = DataQualityFlag.read("/users/DET/Segments/K1-GRD_LOCK_STATE_N_EQ_1000/2020/K1-GRD_LOCK_STATE_N_EQ_1000_SEGMENT_UTC_2020-04-15.xml")

#print(locked)

#=============Get omicron succeeded segments=============

omicron = DataQualityFlag(known = locked.known,)
gpsstart = locked.known[0][0]
gpsend = locked.known[0][1]
#gpsstart = 1270944018
#gpsend = 1271030418
#omicron = DataQualityFlag(name="Omicron",known = [(gpsstart,gpsend)])

channels = []
with open("/users/DET/tools/Omicron/Parameter/O3rerun_1024.txt") as f:
    lines = f.readlines()
    for line in lines:
        if "DATA CHANNELS " in line:
            channel=line.split()[-1]
            channels.extend([channel])



files = []

for i in range(int(gpsstart/100000),int(gpsend/100000)+1):
    #tmp = glob.glob("/home/controls/triggers/K1/CAL_CS_PROC_DARM_DISPLACEMENT_DQ_OMICRON/"+str(i)+"/K1-CAL_CS_PROC_DARM_DISPLACEMENT_DQ_OMICRON-*")
    tmp = glob.glob("/home/controls/triggers/K1/*_OMICRON/"+str(i)+"/*")
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
with open("/users/DET/tools/Omicron/Script/log200519_4096.dat") as f:  # for 4/14-20
#with open("/users/DET/tools/Omicron/Script/log200504.dat") as f:  # for 4/7-12
    lines = f.readlines()
    for line in lines:
        if "Omicron::ExtractTriggers: the maximum trigger rate (5000.00000 Hz) is exceeded (K1:CAL-CS_PROC_DARM_DISPLACEMENT_DQ " in line:
            time=line.split()[-1]
            tmpstart = int(time.split("-")[0])
            tmpend = int(time.split("-")[1][0:10])
            tmp = DataQualityFlag(known = failed.known, active = [(tmpstart, tmpend)])
            failed += tmp

unknown = locked - omicron
unknown -= failed

print("Locked segments")
print(locked)
print("Omicron succeeded")
print(omicron)
print("Omicron failed")
print(failed)

print("Unknown segments")
print(unknown)

with open("unknownSegments0519_1024.txt", mode='w') as f:
    for seg in unknown.active :
        f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
with open("failedSegments0519_1024.txt", mode='w') as f:
    for seg in failed.active :
        f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
with open("succeededSegments0519_1024.txt", mode='w') as f:
    for seg in omicron.active :
        f.write('{0} {1}\n'.format(int(seg[0]), int(seg[1])))
