#******************************************#
#     File Name: LOCKLOSS.py
#        Author: Hirotaka Yuzurihara
# Last Modified: 2024/09/04
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
def _make_lsc_lock_loss_flag(sigs:TimeSeriesDict, round:bool=False) -> DataQualityFlag:
    '''
    Core function for making DataQualityFlag about lockloss of LSC_LOCK guardian
    '''
    ### [NOTE] Definition of this flag.
    dqflag = DataQualityFlag(name='K1:GRD-LSC_LOCK_LOSS',
                             label='LSC_LOCK_LOSS',
                             category=None,
                             description='lock loss of LSC_LOCK guardian',
                             isgood=False)

    threshold = TimeSeries([-10.0], unit='V', name='threshold:-10.0')
    state = sigs['K1:GRD-LSC_LOCK_STATE_N'] == threshold
    dqflag |= state.to_dqflag().round(contract=round) # Modified by Uchikata 2023/06/23

    return dqflag


def make_lock_loss_flag(t0:float, t1:float, round:bool=False, host:str='k1nds1', port:int=8088) -> DataQualityFlag:
    '''
    User interface for making DataQualityFlag about lockloss of LSC_LOCK guardian.
    '''
    ### [NOTE] Channels checked in this flag.
    ###        Though all ~100 models should be checked,
    ###          only DARM related models are checked due to comuting time.
    chans = [
        'K1:GRD-LSC_LOCK_STATE_N'
    ]
    sigs = TimeSeriesDict.fetch(chans, t0, t1, host=host, port=port)
    return _make_lsc_lock_loss_flag(sigs, round=round)
    
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
        description='make SegmentList of lock loss.',
        epilog='> python3 test.py --gps0 1366163577 --gps1 1366175207')
    parser.add_argument('--gps0', required=True, type=float, help='start gpstime')
    parser.add_argument('--gps1', required=True, type=float, help='end gpstime')
    parser.add_argument('--round', action='store_true', help='round integer GPS')
    parser.add_argument('--output', action='store_true', help='output xml and txt file')
    parser.add_argument('--only-nevent', action='store_true', help='output only number of events')
    args = parser.parse_args()

    t0 = min(args.gps0, args.gps1)
    t1 = max(args.gps0, args.gps1)
    round = args.round

    x = make_lock_loss_flag(t0, t1, round=round, host='k1nds2')
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
