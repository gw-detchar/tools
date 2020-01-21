'''
This script converts burst event txt file to trigger xml file.
'''

import os
import math
from gwpy.table import EventTable
from gwpy.table import Column
from gwpy.table.filters import in_segmentlist
from mylib import mylib
#  argument processing
import argparse

parser = argparse.ArgumentParser(description='Make trigger file from burst event txt file.')
parser.add_argument('-i','--infile',help='input burst event txt file.',default='/users/DET/tools/Hveto/Script/Burst/EVENTS_LHVK_20191219.txt')
parser.add_argument('-o','--outfile',help='output xml file.',default='test.xml')
parser.add_argument('-n','--noise',help='Noise investigation.',action='store_true')
parser.add_argument('-f','--force',help='All events are processed.',action='store_true')

args = parser.parse_args()

infile = args.infile
outfile = args.outfile
noise = args.noise
force = args.force

t = EventTable.read(infile, format = 'ascii.cwb')

#columns = ['time for J1 detector','duration','central frequency','bandwidth','hrss for J1 detector','sSNR for J1 detector','likelihood'])

t.keep_columns(['time for J1 detector','duration','central frequency','bandwidth','hrss for J1 detector','sSNR for J1 detector','likelihood','time shift'])

if force:
    print("================= All events ================")
    pass
elif noise:
    # Significant event in KAGRA data
    print("================= Significant events in KAGRA data ================")
    t = t.filter(('sSNR for J1 detector', mylib.Islarger, 0.1 ))
else:
    # Physically meaningful events.
    print("================= GW candidate ================")
    t = t.filter(('time shift', mylib.IsSame, 0))
print("Filtered")
print(t)

t.rename_column('central frequency','peak_frequency')
t.rename_column('hrss for J1 detector','amplitude')
#t.rename_column('sSNR for J1 detector','snr')
t.rename_column('likelihood','confidence')
t.rename_column('time shift','param_one_value')
#t.rename_column('time for J1 detector','peak_time')

time = t.get_column('time for J1 detector')

print(time.data)
channel = Column(name='channel',data=['BURST_DUMMY' for i in time.data])
peaktimedata = [ int(i)  for i in time.data]
#peak_time = Column(name='peak_time',data=[ int(i)  for i in time.data])
peak_time = Column(name='peak_time',data=peaktimedata)
peak_time_ns = Column(name='peak_time_ns',data=[ int((i - int(i))*1e9)  for i in time.data])
snr = Column(name='snr',data=[ 10 for i in time.data])

t.remove_column('time for J1 detector')
t.remove_column('sSNR for J1 detector')

t.add_column(channel)
t.add_column(snr)
t.add_column(peak_time)
t.add_column(peak_time_ns)
print(t)
# peak_time peak_time_ns start_time start_time_ns duration peak_frequency central_freq bandwidth channel amplitude snr 'confidence', 'chisq', 'chisq_dof', 'param_one_name', 'param_one_value'

#t.write(outfile, format = 'ligolw', tablename = 'sngl_burst', overwrite = True)

if noise:
    t.write(outfile, format = 'ligolw', tablename = 'sngl_burst', overwrite = True)
    
else:
    # Want to modify for multiple events to be filed one by one.
    with open("events.txt", mode='w') as f:
        for i in range(0, len(t)):
            print(i)
            print(t[i])
            time=peaktimedata[i]-30
            if not os.path.exists("/home/controls/triggers/K1/BURST_DUMMY_OMICRON/"+str(int(float(time)))[0:5]):
                os.makedirs("/home/controls/triggers/K1/BURST_DUMMY_OMICRON/"+str(int(float(time)))[0:5])
            outfile = "/home/controls/triggers/K1/BURST_DUMMY_OMICRON/"+str(int(float(time)))[0:5]+"/K1-BURST_DUMMY_OMICRON-" + str(time)+ "-60.xml.gz"

            t.write(outfile, format = 'ligolw', tablename = 'sngl_burst', overwrite = True)

            f.write(str(peaktimedata[i])+'\n')
