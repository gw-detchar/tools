from gwpy.table import EventTable

inputfile = "/home/detchar/triggers/K1/AOS_TMSX_IR_PDA1_OUT_DQ_OMICRON/12709/K1-AOS_TMSX_IR_PDA1_OUT_DQ_OMICRON-1270976190-60.xml.gz"
events = EventTable.read(inputfile, tablename='sngl_burst')
print(events)
