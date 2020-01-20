'''
This script converts burst event txt file to trigger xml file.
'''

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

args = parser.parse_args()

infile = args.infile
outfile = args.outfile
 
t = EventTable.read(infile, format = 'ascii.cwb')

#columns = ['time for J1 detector','duration','central frequency','bandwidth','hrss for J1 detector','sSNR for J1 detector','likelihood'])

t.keep_columns(['time for J1 detector','duration','central frequency','bandwidth','hrss for J1 detector','sSNR for J1 detector','likelihood','time shift'])
# Physically meaningful events.
#t = t.filter(('time shift', mylib.IsSame, 0))
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
peak_time = Column(name='peak_time',data=[ int(i)  for i in time.data])
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

t.write(outfile, format = 'ligolw', tablename = 'sngl_burst', overwrite = True)
