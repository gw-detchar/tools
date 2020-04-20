from gwpy.table import EventTable

inputfile = "/home/controls/triggers/K1/CAL_CS_PROC_DARM_DISPLACEMENT_DQ_OMICRON/12607/K1-CAL_CS_PROC_DARM_DISPLACEMENT_DQ_OMICRON-1260747678-60.xml.gz"
events = EventTable.read(inputfile, tablename='sngl_burst')
print(events)
