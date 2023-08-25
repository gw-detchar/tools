#******************************************#
#     File Name: SCIENCE_MODE2.py
#        Author: Nami Uchikata
# Last Modified: 2023/08/25 
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
def _make_science_flag(sigs:TimeSeriesDict, round:bool=False) -> DataQualityFlag:
    '''
    Core function for making DataQualityFlag about GRD_SCIENCE_MODE segments.
    
    '''
    ### [NOTE] Definition of this flag.
    
    dqflag = DataQualityFlag(name='K1:GRD_SCIENCE_MODE:1',
                             label='K1-GRD_SCIENCE_MODE',
                             category=None,
                             description='Observation mode.',
                             isgood=True)
    
    # Modified to refer two channels. (2023/08/25 N. Uchikata)
    # Check the LOCK state
    threshold = TimeSeries([10000.0], unit='V', name='threshold:10000.0')
    state = sigs['K1:GRD-LSC_LOCK_STATE_N'] == threshold
    dqflag |= state.to_dqflag().round(contract=round)
    
    # Check the IFO state
    threshold = TimeSeries([1000.0], unit='V', name='threshold:1000.0')
    state = sigs['K1:GRD-IFO_STATE_N'] == threshold
    dqflag &= state.to_dqflag().round(contract=round)
    
    """
    threshold = TimeSeries([1000.0], unit='V', name='threshold:1000.0')
    for sig in sigs.values():
        state = sig == threshold
        dqflag |= state.to_dqflag().round(contract=round)
    """
    return dqflag


"""
def make_locked_flag(t0:float, t1:float, round:bool=False, host:str='k1nds1', port:int=8088) -> DataQualityFlag:
    '''
    User interface for making DataQualityFlag about IPC glitches.
    '''
    ### [NOTE] Channels checked in this flag.
    ###        Though all ~100 models should be checked,
    ###          only DARM related models are checked due to comuting time.
    chans = [
        'K1:GRD-LSC_LOCK_STATE_N'
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

"""
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

    x = make_ipc_glitch_flag(t0, t1, round=round)
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
