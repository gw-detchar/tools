#******************************************#
#     File Name: OVERFLOW_ADC_DAC.py
#        Author: Takahiro Yamamoto
# Last Modified: 2025/08/02 17:24:00
#******************************************#

#######################################
### Modules
#######################################
import os
import numpy as np
from gwpy.timeseries import TimeSeries, TimeSeriesDict
from gwpy.segments import DataQualityFlag

SEGMENT_WITNESS = {
    'OMC': {
        'default': ['K1:FEC-79_ADC_OVERFLOW_0_0',  ### DCPD_A
                    'K1:FEC-79_ADC_OVERFLOW_0_1'], ### DCPD_B
    },
    'ETMX': {
        'default': [
            'K1:FEC-104_DAC_OVERFLOW_1_0',   ### MN_V3
            'K1:FEC-104_DAC_OVERFLOW_1_1',   ### MN_H1
            'K1:FEC-104_DAC_OVERFLOW_1_2',   ### MN_H2
            'K1:FEC-104_DAC_OVERFLOW_1_3',   ### MN_H3
            'K1:FEC-104_DAC_OVERFLOW_1_4',   ### MN_V1
            'K1:FEC-104_DAC_OVERFLOW_1_5',   ### MN_V2
            'K1:FEC-104_DAC_OVERFLOW_1_6',   ### IM_V1
            'K1:FEC-104_DAC_OVERFLOW_1_7',   ### IM_V2
            'K1:FEC-104_DAC_OVERFLOW_1_8',   ### IM_V3
            'K1:FEC-104_DAC_OVERFLOW_1_9',   ### IM_H1
            'K1:FEC-104_DAC_OVERFLOW_1_10',  ### IM_H2
            'K1:FEC-104_DAC_OVERFLOW_1_11',  ### IM_H3
            'K1:FEC-104_DAC_OVERFLOW_1_12',  ### TM_H1
            'K1:FEC-104_DAC_OVERFLOW_1_13',  ### TM_H2
            'K1:FEC-104_DAC_OVERFLOW_1_14',  ### TM_H3
            'K1:FEC-104_DAC_OVERFLOW_1_15',  ### TM_H4
            'K1:FEC-104_DAC_OVERFLOW_2_12',  ### TM_LP
            'K1:FEC-104_DAC_OVERFLOW_2_13',  ### TM_LP
            'K1:FEC-104_DAC_OVERFLOW_2_14',  ### TM_LP
            'K1:FEC-104_DAC_OVERFLOW_2_15',  ### TM_LP
        ],
        'O4a': ['K1:FEC-103_DAC_OVERFLOW_1_{0}'.format(ii) for ii in range(0, 16)], ### MN_6,IM_6,TM_4
    },
    'ETMY': {
        'default': ['K1:FEC-109_DAC_OVERFLOW_1_{0}'.format(ii) for ii in range(0, 16)], ### MN_6,IM_6,TM_4
        'O4a': ['K1:FEC-108_DAC_OVERFLOW_1_{0}'.format(ii) for ii in range(0, 16)], ### MN_6,IM_6,TM_4
    },
}

#######################################
### Functions
#######################################
def _make_overflow_flag(sigs:TimeSeriesDict, name:str, round:bool=False) -> DataQualityFlag:
    '''
    Core function for making DataQualityFlag about ADC/DAC Overflows.

    name:str
        'OMC', 'ETMX', or 'ETMY'
    '''
    ### [NOTE] Definition of this flag.
    ### [HACK] This flag should be included in category 1.
    dqflag = DataQualityFlag(name='K1:{0}_OVF:1'.format(name),
                             label='Overflows on {0}'.format(name),
                             category=None,
                             description='Overflows on {0}'.format(name),
                             isgood=False)

    threshold = TimeSeries([0.0], unit='NONE', name='threshold:0.0')
    for sig in sigs.values():
        state = sig != threshold
        #dqflag |= state.to_dqflag(round=round)
        dqflag |= state.to_dqflag().round(contract=round) # Modified by Uchikata 2023/06/23

    return dqflag

#Added by Uchikata 2023/06/23 #
def _make_overflow_ok_flag(sigs:TimeSeriesDict, name:str, round:bool=False) -> DataQualityFlag:
    '''
    Core function for making DataQualityFlag about No ADC/DAC Overflows.

    name:str
        'OMC', 'ETMX', or 'ETMY'
    '''
    temp = DataQualityFlag(name='K1:{0}_OVF_OK:1'.format(name),
                           label='No overflows on {0}'.format(name),
                           category=None,
                           description='No overflows on {0}'.format(name),
                           isgood=True)
    threshold = TimeSeries([0.0], unit='NONE', name='threshold:0.0')
    sigN = 1
    for sig in sigs.values():
        state = sig == threshold
        #print(state)
        if sigN == 1:
            temp = state.to_dqflag().round(contract=round)
        else:
            temp &= state.to_dqflag().round(contract=round)
        sigN = sigN + 1
        
    ### [NOTE] Definition of this flag.
    dqflag = DataQualityFlag(name='K1:{0}_OVF_OK:1'.format(name),
                             label='No overflows on {0}'.format(name),
                             category=None,
                             description='No overflows on {0}'.format(name),
                             isgood=True)
    dqflag |= temp

    return dqflag

def make_overflow_flag(t0:float, t1:float, name:str, round:bool=False, host:str='k1nds1', port:int=8088) -> DataQualityFlag:
    '''
    User interface for making DataQualityFlag about ADC/DAC Overflows.

    name:str
        'OMC', 'ETMX', or 'ETMY'
    '''
    ### [NOTE] Channels checked in this flag.
    chans = {'OMC': ['K1:FEC-79_ADC_OVERFLOW_0_0',     ### DCPD_A
                     'K1:FEC-79_ADC_OVERFLOW_0_1'],    ### DCPD_B
             'ETMX': ['K1:FEC-103_DAC_OVERFLOW_1_0',   ### MN_V3
                      'K1:FEC-103_DAC_OVERFLOW_1_1',   ### MN_H1
                      'K1:FEC-103_DAC_OVERFLOW_1_2',   ### MN_H2
                      'K1:FEC-103_DAC_OVERFLOW_1_3',   ### MN_H3
                      'K1:FEC-103_DAC_OVERFLOW_1_4',   ### MN_V1
                      'K1:FEC-103_DAC_OVERFLOW_1_5',   ### MN_V2
                      'K1:FEC-103_DAC_OVERFLOW_1_6',   ### IM_V1
                      'K1:FEC-103_DAC_OVERFLOW_1_7',   ### IM_V2
                      'K1:FEC-103_DAC_OVERFLOW_1_8',   ### IM_V3
                      'K1:FEC-103_DAC_OVERFLOW_1_9',   ### IM_H1
                      'K1:FEC-103_DAC_OVERFLOW_1_10',  ### IM_H2
                      'K1:FEC-103_DAC_OVERFLOW_1_11',  ### IM_H3
                      'K1:FEC-103_DAC_OVERFLOW_1_12',  ### TM_H1
                      'K1:FEC-103_DAC_OVERFLOW_1_13',  ### TM_H2
                      'K1:FEC-103_DAC_OVERFLOW_1_14',  ### TM_H3
                      'K1:FEC-103_DAC_OVERFLOW_1_15'], ### TM_H4
             'ETMY': ['K1:FEC-108_DAC_OVERFLOW_1_0',   ### MN_V3
                      'K1:FEC-108_DAC_OVERFLOW_1_1',   ### MN_H1
                      'K1:FEC-108_DAC_OVERFLOW_1_2',   ### MN_H2
                      'K1:FEC-108_DAC_OVERFLOW_1_3',   ### MN_H3
                      'K1:FEC-108_DAC_OVERFLOW_1_4',   ### MN_V1
                      'K1:FEC-108_DAC_OVERFLOW_1_5',   ### MN_V2
                      'K1:FEC-108_DAC_OVERFLOW_1_6',   ### IM_V1
                      'K1:FEC-108_DAC_OVERFLOW_1_7',   ### IM_V2
                      'K1:FEC-108_DAC_OVERFLOW_1_8',   ### IM_V3
                      'K1:FEC-108_DAC_OVERFLOW_1_9',   ### IM_H1
                      'K1:FEC-108_DAC_OVERFLOW_1_10',  ### IM_H2
                      'K1:FEC-108_DAC_OVERFLOW_1_11',  ### IM_H3
                      'K1:FEC-108_DAC_OVERFLOW_1_12',  ### TM_H1
                      'K1:FEC-108_DAC_OVERFLOW_1_13',  ### TM_H2
                      'K1:FEC-108_DAC_OVERFLOW_1_14',  ### TM_H3
                      'K1:FEC-108_DAC_OVERFLOW_1_15'], ### TM_H4
    }[name]
    sigs = TimeSeriesDict.fetch(chans, t0, t1, host=host, port=port)
    return _make_overflow_flag(sigs, name, round=round)

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
        description='make SegmentList of Overflows.',
        epilog='> python3 test.py --gps0 1369843000 --gps1 1369846000')
    parser.add_argument('--gps0', required=True, type=float, help='start gpstime')
    parser.add_argument('--gps1', required=True, type=float, help='end gpstime')
    parser.add_argument('--name', required=True, type=str, choices=['OMC', 'ETMX', 'ETMY'],  help='end gpstime')
    parser.add_argument('--round', action='store_true', help='round integer GPS')
    parser.add_argument('--output', action='store_true', help='round integer GPS')
    parser.add_argument('--only-nevent', action='store_true', help='round integer GPS')
    args = parser.parse_args()

    t0 = min(args.gps0, args.gps1)
    t1 = max(args.gps0, args.gps1)
    round = args.round

    x = make_overflow_flag(t0, t1, name=args.name, round=round)
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
