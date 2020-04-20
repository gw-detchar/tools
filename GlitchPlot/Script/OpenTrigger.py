from gwpy.table import EventTable
from mylib import mylib

inputfile = "/home/controls/triggers/K1/CAL_CS_PROC_DARM_DISPLACEMENT_DQ_OMICRON/12606/K1-CAL_CS_PROC_DARM_DISPLACEMENT_DQ_OMICRON-1260615498-60.xml.gz"
events = EventTable.read(inputfile, tablename='sngl_burst', columns = ['peak_time', 'peak_time_ns', 'start_time', 'start_time_ns', 'duration', 'peak_frequency', 'central_freq', 'bandwidth','snr'])

events=events.filter(('snr', mylib.Islarger,(100)))
events=events.filter(('peak_time', mylib.between,(1260615552,1260615558)))

events=events.filter(('peak_frequency', mylib.between,(900,1000)))

events.pprint(max_lines=500)
