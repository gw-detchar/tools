#******************************************#
#     File Name: frame_available.py
#        Author: Hirotaka Yuzurihara
# Last Modified: 2023/06/04
#******************************************#

#######################################
### Modules
#######################################
import os
import numpy as np
from gwpy.timeseries import TimeSeries, TimeSeriesDict
from gwpy.segments import DataQualityFlag
from gwpy.time import from_gps, to_gps
from datetime import datetime, timedelta

#######################################
### Parameters (hard code)
#######################################
if os.uname()[1] == 'm31-01.kagra.icrr.u-tokyo.ac.jp' or 'm31-02.kagra.icrr.u-tokyo.ac.jp':
    dirname='/home/ryuki.kawamoto/data/test/'
else:
    dirname='/home/ryuki.kawamoto/data/test/'

#######################################
### Functions
#######################################
def _make_frame_available_flag(sigs:TimeSeriesDict, filepath_xml, filepath_txt, segment_dir, round:bool=False) -> DataQualityFlag:
    '''
    Core function for making DataQualityFlag about frame-available.
    
    The segment is contracted from the list of missing/broken frame provided by DMG
    '''
    dqflag = DataQualityFlag(name='K1:DET-FRAME_AVAILABLE:1',
                             label='FRAME_AVAILABLE',
                             category=None,
                             description='frame file is available, which means frame files are not missing or not broken',
                             isgood=True)    
   
    ch_tmp  = list(sigs.keys())[0]
    gps_beg = sigs[ch_tmp].t0.value
    gps_end = sigs[ch_tmp].times[-1].value
    utc_beg = from_gps(gps_beg) # 5/31 0:00 UTC
    yesterday = utc_beg + timedelta(days=-1) # 5/30 0:00 UTC
    yesterday_date = yesterday.strftime('%Y-%m-%d') # '2023-05-30'
    
    ### [NOTE] Definition of this flag.
    ### [HACK] This flag should be included in category 1.
    
    fname="%s/frame_available_UTC_%s.txt" % (dirname, yesterday_date)
    #print(fname)
    if os.path.isfile(fname):
        frames = np.loadtxt(fname, dtype=str, unpack=True, usecols=[0, 2, 3])
        gps  = frames[0].astype(int)
        duration = gps[1] - gps[0]

        flag = frames[1].astype(int) + frames[2].astype(int) # if flag == 2, data is OK.
        gps_baddata = gps[flag != 2]

        yesterday = yesterday.replace(hour=0, minute=0, second=0)
        gps_yesterday = int(to_gps(yesterday))  # int is necessary to avoid lal error
        today = utc_beg.replace(hour=0, minute=0, second=0)
        gps_today = int(to_gps(today))  # int is necessary to avoid lal error
        
        dqflag.known = [(gps_yesterday, gps_today)]
        dqflag.active = [(gps_yesterday, gps_today)]
        
        year = yesterday.strftime('%Y')
        key  = "K1-DET_FRAME_AVAILABLE"
        #global filepath_xml, filepath_txt
        # xml = filepath_xml[key]
        # txt = filepath_txt[key]
        #print(filepath_xml[key])
        #print(segment_dir +key+'/'+year+'/'+key+'_SEGMENT_UTC_' + yesterday_date + '.xml')
        filepath_xml[key] = segment_dir +key+'/'+year+'/'+key+'_SEGMENT_UTC_' + yesterday_date + '.xml'
        filepath_txt[key] = segment_dir +key+'/'+year+'/'+key+'_SEGMENT_UTC_' + yesterday_date + '.txt'
        #print(filepath_xml[key])        
        
        for x in gps_baddata:
            dqflag_tmp = dqflag.copy()
            dqflag_tmp.known = [(gps_yesterday, gps_today)]
            dqflag_tmp.active = [(int(x), int(x+duration))] # int is necessary to avoid lal error
            dqflag -= dqflag_tmp
    #print(dqflag)
    return dqflag

# def make_ipc_glitch_flag(t0:float, t1:float, round:bool=False, host:str='k1nds1', port:int=8088) -> DataQualityFlag:
#     '''
#     User interface for making DataQualityFlag about IPC glitches.
#     '''
#     ### [NOTE] Channels checked in this flag.
#     ###        Though all ~100 models should be checked,
#     ###          only DARM related models are checked due to comuting time.
#     chans = [
#         'K1:FEC-8_TIME_DIAG',   ### k1lsc
#         'K1:FEC-11_TIME_DIAG',  ### k1calcs
#         'K1:FEC-83_TIME_DIAG',  ### k1omc
#         'K1:FEC-103_TIME_DIAG', ### k1visetmxp
#     ]
#     sigs = TimeSeriesDict.fetch(chans, t0, t1, host=host, port=port)
#     return _make_ipc_glitch_flag(sigs, round=round)
    
# def write_dqflag(dqflag:DataQualityFlag, name:str):
#     '''
#     '''
#     xmlfile = '{0}.xml'.format(name)
#     ### [NOTE] If file already exists, new dqflag is merged.
#     if os.path.exists(xmlfile):
#         old = DataQualityFlag.read(xmlfile)
#         dqflag = old + dqflag
#     dqflag.write(xmlfile, overwrite=True, format='ligolw')
#     np.savetxt('{0}.txt'.format(name), dqflag.active, fmt = "%.4f")


# #######################################
# ### sample code
# #######################################
# if __name__ == '__main__':
#     import gpstime
#     import argparse
#     parser = argparse.ArgumentParser(
#         description='make SegmentList of IPC glitches.',
#         epilog='> python3 test.py --gps0 1366163577 --gps1 1366175207')
#     parser.add_argument('--gps0', required=True, type=float, help='start gpstime')
#     parser.add_argument('--gps1', required=True, type=float, help='end gpstime')
#     parser.add_argument('--round', action='store_true', help='round integer GPS')
#     parser.add_argument('--output', action='store_true', help='round integer GPS')
#     parser.add_argument('--only-nevent', action='store_true', help='round integer GPS')
#     args = parser.parse_args()

#     t0 = min(args.gps0, args.gps1)
#     t1 = max(args.gps0, args.gps1)
#     round = args.round

#     x = make_ipc_glitch_flag(t0, t1, round=round)
#     if args.only_nevent:
#         print('{0}'.format(len(x.active)))
#     else:
#         print('       name: {0}'.format(x.name))
#         print('      label: {0}'.format(x.label))
#         print('   category: {0}'.format(x.category))
#         print('description: {0}'.format(x.description))
#         print('     isgood: {0}'.format(x.isgood))
#         print('    segment: {0}'.format(x.known))
#         print('     active: {0}'.format(len(x.active)))
#         for seg in x.active:
#             print('        {0}'.format(seg))
        
#     if args.output:
#         date = gpstime.parse(t0)
#         write_dqflag(x, '{0:4d}-{1:02d}-{2:02d}'.format(date.year, date.month, date.day))

# #######################################
# ### EOF
# #######################################
