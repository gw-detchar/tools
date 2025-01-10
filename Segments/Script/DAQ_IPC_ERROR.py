#******************************************#
#     File Name: DAQ_IPC_ERROR.py
#        Author: Takahiro Yamamoto
# Last Modified: 2023/06/22 13:15:06
#******************************************#

#######################################
### Modules
#######################################
import os
import numpy as np
from gwpy.timeseries import TimeSeries, TimeSeriesDict
from gwpy.segments import DataQualityFlag

#######################################
### Functions
#######################################
def _make_ipc_glitch_flag(sigs:TimeSeriesDict, round:bool=False) -> DataQualityFlag:
    '''
    Core function for making DataQualityFlag about IPC glitches.

    When IPC glitches occur on DARM, a jump can be seen on K1:FEC-*_TIME_DIAG.
    This channel records an integer number of GPS time in 16Hz as
       x(t_i) = [t_{i-1}]
    So when glitches presence,
       x(t_i) - t_i >= -1.0.
    On the other hand, absence cases,
       x(t_i) - t_i < -1.0.
    '''
    ### [NOTE] Definition of this flag.
    ### [HACK] This flag should be included in category 1.
    dqflag = DataQualityFlag(name='K1:DAQ_IPC_ERROR:1',
                             label='IPC_ERROR',
                             category=None,
                             description='A timing delay related to machine power makes DARM glitches',
                             isgood=False)

    threshold = TimeSeries([-1.0], unit='s', name='threshold:-1.0')
    for sig in sigs.values():
        sig.override_unit('s')

        ### [NOTE] x(t_i) - t_i < -1.0
        state = (sig - sig.xindex < threshold)

        ### [NOTE] Flag is enabled when a timing jump is detected
        ###            on at least one model.
       # dqflag |= state.to_dqflag(round=round)
        dqflag |= state.to_dqflag().round(contract=round) # Modified by Uchikata 2023/06/23

    return dqflag

def make_ipc_glitch_flag(t0:float, t1:float, round:bool=False, host:str='k1nds1', port:int=8088) -> DataQualityFlag:
    '''
    User interface for making DataQualityFlag about IPC glitches.
    '''
    ### [NOTE] Channels checked in this flag.
    ###        Though all ~100 models should be checked,
    ###          only DARM related models are checked due to comuting time.
    chans = [
        'K1:FEC-8_TIME_DIAG',   ### k1lsc
        'K1:FEC-11_TIME_DIAG',  ### k1calcs
        'K1:FEC-83_TIME_DIAG',  ### k1omc
        'K1:FEC-103_TIME_DIAG', ### k1visetmxp
    ]
    sigs = TimeSeriesDict.fetch(chans, t0, t1, host=host, port=port)
    return _make_ipc_glitch_flag(sigs, round=round)
    
def write_dqflag(dqflag:DataQualityFlag, name:str):
    '''
    '''
    xmlfile = '{0}.xml'.format(name)
    ### [NOTE] If file already exists, new dqflag is merged.
    if os.path.exists(xmlfile):
        old = DataQualityFlag.read(xmlfile)
        dqflag = old + dqflag
    dqflag.write(xmlfile, overwrite=True, format='ligolw')
    np.savetxt('{0}.txt'.format(name), dqflag.active, fmt = "%.4f")


#######################################
### sample code
#######################################
if __name__ == '__main__':
    import gpstime
    import argparse
    parser = argparse.ArgumentParser(
        description='make SegmentList of IPC glitches.',
        epilog='> python3 test.py --gps0 1366163577 --gps1 1366175207')
    parser.add_argument('--gps0', required=True, type=float, help='start gpstime')
    parser.add_argument('--gps1', required=True, type=float, help='end gpstime')
    parser.add_argument('--round', action='store_true', help='round integer GPS')
    parser.add_argument('--output', action='store_true', help='round integer GPS')
    parser.add_argument('--only-nevent', action='store_true', help='round integer GPS')
    args = parser.parse_args()

    t0 = min(args.gps0, args.gps1)
    t1 = max(args.gps0, args.gps1)
    round = args.round

    x = make_ipc_glitch_flag(t0, t1, round=round, host='k1nds2')
    if args.only_nevent:
        print('{0}'.format(len(x.active)))
    else:
        print('       name: {0}'.format(x.name))
        print('      label: {0}'.format(x.label))
        print('   category: {0}'.format(x.category))
        print('description: {0}'.format(x.description))
        print('     isgood: {0}'.format(x.isgood))
        print('    segment: {0}'.format(x.known))
        print('     active: {0}'.format(len(x.active)))
        for seg in x.active:
            print('        {0}'.format(seg))
        
    if args.output:
        date = gpstime.parse(t0)
        write_dqflag(x, '{0:4d}-{1:02d}-{2:02d}'.format(date.year, date.month, date.day))


#######################################
### EOF
#######################################
