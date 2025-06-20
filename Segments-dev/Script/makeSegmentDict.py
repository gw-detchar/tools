#!/usr/bin/env python
#******************************************#
#     File Name: makeSegmentDict.py
#        Author: Takahiro Yamamoto
# Last Modified: 2025/06/20 23:02:55
#******************************************#

import os
import re
import glob
import time
import numpy as np

### [REMOVE] for too old astropy
###          related to leap-secs in future
try:
    try:
        from erfa import ErfaWarning
    except:
        from astropy._erfa.core import ErfaWarning 
    import warnings 
    warnings.filterwarnings('ignore', category=ErfaWarning)
except:
    pass

import gpstime
from gwpy.timeseries import TimeSeriesDict
from gwpy.segments import DataQualityDict

from compareSegmentDict import compareSegmentDict

import DAQ_IPC_ERROR as IPC
import OVERFLOW_ADC_DAC as OVF
import PEM_EARTHQUAKE as PEM
import SCIENCE_MODE as SCI
import LOCK_GRD as LOCK
import LOCK_LOSS as LOSS

#########################################
###  rw params
#########################################
SEGDIR = {
    'Kamioka': '/users/DET/test-Segments',
    'Kashiwa': '/home/detchar/test-Segments',
}
SEGPREF = {
    'DQSEGDB': 'K-K1_SEG',
    'LOCAL': 'K-K1_TST',
}
SEGLEN = 800
CACHEDIR = {
    'Kamioka': '/users/DET/Cache/Cache_GPS',
    'Kashiwa': '/home/detchar/cache/Cache_GPS'
}
GWFMARGIN = {
    ### ceil( (GWF_size + Cache_Interval + Transfer_latency) / GWF_size)
    'Kamioka': 3, ### ceil( (32s + 60s + 0s?) / 32s)
    'Kashiwa': 5, ### ceil( (32s + 60s + 60s?) / 32s)
}

#########################################
###  ro params
#########################################
GWFLEN = 32

#########################################
###  Segment List
#########################################
SEGLIST = { ### 'name' is no longer used
    1: {
        'name': 'K1-DAQ_IPC_ERROR',
        'function': IPC._make_ipc_glitch_flag,
        'option': [False],
        'channel': IPC.SEGMENT_WITNESS,
    },
    2: {
        'name': 'K1-OMC_OVERFLOW_VETO',
        'function': OVF._make_overflow_flag,
        'option': ['OMC',False],
        'channel': OVF.SEGMENT_WITNESS['OMC'],
    },
    3: {
        'name': 'K1-OMC_OVERFLOW_OK',
        'function': OVF._make_overflow_ok_flag,
        'option': ['OMC',True],
        'channel': OVF.SEGMENT_WITNESS['OMC'],
    },
    4: {
        'name': 'K1-ETMX_OVERFLOW_VETO',
        'function': OVF._make_overflow_flag,
        'option': ['ETMX',False],
        'channel': OVF.SEGMENT_WITNESS['ETMX'],
    },
    5: {
        'name': 'K1-ETMX_OVERFLOW_OK',
        'function': OVF._make_overflow_ok_flag,
        'option': ['ETMX',True],
        'channel': OVF.SEGMENT_WITNESS['ETMX'],
    },
    6: {
        'name': 'K1-ETMY_OVERFLOW_VETO',
        'function': OVF._make_overflow_flag,
        'option': ['ETMY',False],
        'channel': OVF.SEGMENT_WITNESS['ETMY'],
    },
    7: {
        'name': 'K1-ETMY_OVERFLOW_OK',
        'function': OVF._make_overflow_ok_flag,
        'option': ['ETMY',True],
        'channel': OVF.SEGMENT_WITNESS['ETMY'],
    },
    8: {
        'name': 'K1-GRD_PEM_EARTHQUAKE',
        'function': PEM._make_earthquake_flag,
        'option': [False],
        'channel': PEM.SEGMENT_WITNESS,
    },
    9: {
        'name': 'K1-GRD_LOCKED',
        'function': LOCK._make_locked_flag,
        'option': [True],
        'channel': LOCK.SEGMENT_WITNESS,
    },
    10: {
        'name':'K1-GRD_UNLOCKED',
        'function': LOCK._make_unlocked_flag,
        'option':[False],
        'channel': LOCK.SEGMENT_WITNESS,
    },
    11: {
        'name': 'K1-GRD_SCIENCE_MODE',
        'function': SCI._make_science_flag,
        'option': [True],
        'channel': SCI.SEGMENT_WITNESS,
    },
    -12: {
        'name':'K1-GRD_LSC_LOCK_LOSS',
        'function': LOSS._make_lsc_lock_loss_flag,
        'option': [True],
        'channel': LOSS.SEGMENT_WITNESS,
    },
}

#########################################
###  Helper function
#########################################
def _get_next_segment_start(rootdir):
    dirs = sorted(glob.glob('{0}/[0-9][0-9][0-9][0-9][0-9]'.format(rootdir)), reverse=True)
    if len(dirs) == 0:
        return -1, 0

    xmls = sorted(glob.glob('{0}/*.xml'.format(dirs[0])), reverse=True)
    if len(xmls) == 0:
        return -2, 0

    splitname = os.path.splitext(os.path.basename(xmls[0]))[0].split('-')
    try:
        segment_length = int(splitname[-1])
        next_start_gps = int(splitname[-2]) + segment_length
    except:
        return -3, 0
    
    return next_start_gps, segment_length

def _get_gwf_list(start_gps, stop_gps, cachedir):
    cachefiles = sorted({ '{0}/{1}.ffl'.format(cachedir, int(t/100000))
                          for t in [start_gps, stop_gps]
                          if os.path.exists('{0}/{1}.ffl'.format(cachedir, int(t/100000)))
                         })
    gwffiles = [l[0] for c in cachefiles for l in np.loadtxt(c, dtype=str) if start_gps <= int(l[1]) < stop_gps]
    return gwffiles

def _compare_dqd(dqd, dqd_ref):
    diff = False
    if dqd.keys() != dqd_ref.keys():
        print(' missing segments: {0}'.format(dqd_ref.keys() - dqd.keys()) )
        print('addional segments: {0}'.format(dqd.keys() - dqd_ref.keys()) )
        diff |= True
    
    for kk in dqd.keys() & dqd_ref.keys():
        msg = []
        if dqd[kk].name != dqd_ref[kk].name:
            msg = ['     name: {0} => {1}'.format(dqd_ref[kk].name, dqd[kk].name)]
        if dqd[kk].known != dqd_ref[kk].known:
            msg += ['    known: {0} => {1}'.format(dqd_ref[kk].known, dqd[kk].known)]
        if dqd[kk].active != dqd_ref[kk].active:
            msg += ['   active: {0} => {1}'.format(dqd_ref[kk].active, dqd[kk].active)]
            
        if msg != []:
            print('\n[{0}]'.format(kk))
            print('\n'.join(msg))
            diff |= True
    return diff


#########################################
###  Main
#########################################
if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        description='make segment files containing SegmentListDict',
        # epilog='> python3 makeSegmentDict.py'
    )
    parser.add_argument('--cluster', type=str, default=None, required=True, choices=SEGDIR.keys(), metavar='NODE',
                        help='choose from [{0}]\n\n'.format(', '.join(SEGDIR.keys())))
    parser.add_argument('--online', action='store_true',
                        help='\n'.join(['operation: online-mode']))
    parser.add_argument('--fill', nargs=2, type=int, metavar=('T0', 'T1'),
                        help='\n'.join(['operation: fill-mode',
                                        '  pair of start (T0) & end (T1) gpstime',
                                        ' ']))
    parser.add_argument('--seglength', type=int, default=SEGLEN, metavar='SEC',
                        help='\n'.join(['fill-mode option',
                                        '  segment file length in the unit of second [default={0}]'.format(SEGLEN),
                                        '  used only when no segment file is found']))
    parser.add_argument('--overwrite', action='store_true',
                        help='\n'.join(['fill-mode option [default=False]',
                                        ' ']))
    parser.add_argument('--prefix', type=str, default=None, metavar='PREF',
                        help='\n'.join(['common option',
                                        '  prefix of file name [default={0}]'.format(SEGPREF['DQSEGDB'])]))
    parser.add_argument('--output', type=str, default=None, metavar='DIR',
                        help='\n'.join(['common option', '  output segments directory']
                                       + ['   * {0}: {1}'.format(k,v) for k,v in SEGDIR.items()]))
    parser.add_argument('--nmargin', type=int, default=None, metavar='N',
                        help='\n'.join(['common option',
                                        '  number of file margin for a delay of gwf file creation']
                                       + ['   * {0}: {1}'.format(k,v) for k,v in GWFMARGIN.items()]))
    parser.add_argument('--cachedir', type=str, default=None, metavar='DIR',
                        help='\n'.join(['common option', '  cache directory']
                                       + ['   * {0}: {1}'.format(k,v) for k,v in CACHEDIR.items()]
                                       + [' ']))
    parser.add_argument('--nds', type=str, default=None, metavar='NDS',
                        help='\n'.join(['debug option',
                                        '  gwf reading: NDS-mode [default=None (Cache-mode)]']))
    parser.add_argument('--private', action='store_true',
                        help='\n'.join(['debug option [default=False]',
                                        '  enable also negative keys in segment list',
                                        '  default prefix is override as {0}'.format(SEGPREF['LOCAL'])]))
    parser.add_argument('--dry-run', action='store_true',
                        help='\n'.join(['debug option [default=False]',
                                        '  skip writing segments']))
    parser.add_argument('--no-read', action='store_true',
                        help='\n'.join(['debug option [default=False]',
                                        '  skip reading gwf',
                                        '  used only in dry-run mode']))

    args = parser.parse_args()

    ### Choose directory
    if args.output == None:
        segment_dir = SEGDIR[args.cluster]
    else:
        segment_dir = args.output
    if args.cachedir == None:
        cache_dir = CACHEDIR[args.cluster]
    else:
        cache_dir = args.cachedir
    if args.nmargin == None:
        n_file = GWFMARGIN[args.cluster]
    else:
        n_file = args.nmargin
    if args.prefix == None:
        if args.private:
            segment_pref = SEGPREF['LOCAL']
        else:
            segment_pref = SEGPREF['DQSEGDB']
    else:
        if not args.private or args.prefix != SEGPREF['DQSEGDB']:
            segment_pref = args.prefix
        else:
            print("Can't use {0} in private-mode".format(SEGPREF['DQSEGDB']))
            exit(1)

    ### Try to get start GPS and segment length form the latest segment file
    start_gps, segment_length = _get_next_segment_start(segment_dir)
    if segment_length == 0 and args.online:
        ### [NOTE] Online-mode
        ###        Segment length must be given from the latest segment file.
        print("Can't find latest file in {0}".format(segment_dir))
        print('Please create at least one segment file by fill-mode')
        exit(1)
    elif segment_length == 0 and args.fill != None:
        ### [NOTE] Fill-mode
        ###        Segment length is given by command-line option
        ###        only when it can't be decide from the latest segment file.
        segment_length = args.seglength

    ### Restrictions
    if segment_length % GWFLEN != 0:
        print('segment length must be an integral multiple of GWFLEN={0}'.format(GWFLEN))
        exit(1)
    elif 100000 % segment_length != 0:
        print('segment length must be a divisor of 100000')
        exit(1)

    ### Decide GPS epochs
    current_gps = int(gpstime.gpsnow())
    available_gps = current_gps - n_file * GWFLEN
    if args.online == True:
        ### [NOTE] Online-mode
        ###        Start GPS already decided from the latest segment file.
        end_gps   = int(available_gps / segment_length) * segment_length
    elif args.fill != None:
        ### [NOTE] Fill-mode
        ###        Future GPS is ignored and replaced as current GPS.
        start_gps = int( min(args.fill[0], available_gps) / segment_length) * segment_length
        end_gps   = int( min(args.fill[1], available_gps) / segment_length) * segment_length
    else:
        ### [NOTE] Unknown operation mode
        ###        Either Online-mode or Fill-mode must be chosen.
        print("Can't decide operation mode")
        print("Please use '--online' or '--fill'")
        exit(1)
    gpsrange = range(start_gps, end_gps, segment_length)

    ### Log
    if args.dry_run or len(gpsrange) > 0:
        print('-------------------------------------------------')
        print('  current GPS: {0}'.format(current_gps))
        print('      cluster: {0}'.format(args.cluster))
        print('    operation: {0}'.format('online-mode' if args.online==True else 'fill-mode'))
        print('   gwf source: {0}'.format('{0} (specified={1})'.format(cache_dir, cache_dir!=CACHEDIR[args.cluster]) if args.nds==None else args.nds))
        print('      gwf len: {0}'.format(GWFLEN))
        print('     N margin: {0}'.format(n_file))
        print('  segment dir: {0} (specified={1})'.format(segment_dir, segment_dir!=SEGDIR[args.cluster]))
        print(' segment pref: {0}'.format(segment_pref))
        print('  segment len: {0}'.format(segment_length))
        print('  segment GPS: {0}'.format(list(gpsrange)))
        print('     fraction: {0} - {1} ({2}s)'.format(end_gps, available_gps, available_gps - end_gps))
        print('    overwrite: {0}'.format(args.overwrite))
        print('-------------------------------------------------')

    ### Make DataQualityDict for each GPS slice
    for ii_gps in gpsrange:
        gps_dir = int(ii_gps / 100000)
        output_xml = '{0}/{1}/{2}-{3}-{4}.xml'.format(segment_dir, gps_dir, segment_pref, ii_gps, segment_length)

        ### [NOTE] Overwrite-mode
        ###        When file already exists, process will be skipped except overwrite-mode.
        ###        DataQualityDict.write() overwrites files only when overwrite=True.
        ###        So this secion is not necessary to avoid accidental overwrite.
        ###        But this implementation can reduce CPU cost for data reading.
        if not args.overwrite and os.path.exists(output_xml):
            print('    exist: {0}'.format(output_xml))
            continue
        elif args.dry_run and args.no_read:
            if args.overwrite and os.path.exists(output_xml):
                print('overwrite: {0}'.format(output_xml))
            else:
                print('   create: {0}'.format(output_xml))

            if args.nds == None:
                gwf_files = _get_gwf_list(ii_gps, ii_gps+segment_length, cache_dir)
                print('\n'.join(['           {0}'.format(g) for g in gwf_files]))
            continue

        ### Read all channels
        all_channels = list( {c for k in SEGLIST for c in SEGLIST[k]['channel']} )
        if args.nds == None:
            ### [NOTE] Cache-mode (default)
            gwf_files = _get_gwf_list(ii_gps, ii_gps+segment_length, cache_dir)
            try:
                all_data = TimeSeriesDict.read(gwf_files, all_channels, start=ii_gps, end=ii_gps+segment_length,
                                               pad='pad')
            except Exception as e:
                print('     fail: {0} {1}'.format(output_xml, e))
                break

        else:
            ### [NOTE] NDS-mode
            ###        This mode should be used only for tests.
            port = 8088
            host = args.nds.split(':')
            if len(host) >= 2:
                try:
                    port = int(host[1])
                except:
                    pass
            host = host[0]
            gwf_files = []
            try:
                all_data = TimeSeriesDict.fetch(all_channels, start=ii_gps, end=ii_gps+segment_length,
                                                host=host, port=port, pad='pad')
            except Exception as e:
                print('     fail: {0} {1}'.format(output_xml, e))
                break

        ### Make DataQualityFlag for each Segment
        DQDic = DataQualityDict()
        for key in SEGLIST.keys():
            ### Pick-up only necessary data for each Segment
            dq_data = {k: v for k, v in all_data.items() if k in SEGLIST[key]["channel"]}
            tmpDQD = SEGLIST[key]['function'](dq_data, *SEGLIST[key]['option'])
            if key > 0 or args.private:
                DQDic[tmpDQD.name] = tmpDQD

        ### Overwrite check
        if args.overwrite and os.path.exists(output_xml):
            old_DQDic = DataQualityDict.read(output_xml)
            diff = compareSegmentDict(DQDic, old_DQDic)
            if not diff:
                print('no change: {0}'.format(output_xml))
                continue

            print('overwrite: {0}'.format(output_xml))
            if args.nds == None:
                print('\n'.join(['           {0:2d}) {1}'.format(i, g) for i, g in enumerate(gwf_files)]))
        else:
            print('   create: {0}'.format(output_xml))
            if args.nds == None:
                print('\n'.join(['           {0:2d}) {1}'.format(i, g) for i, g in enumerate(gwf_files)]))

        ### Write segments file for each GPS slice
        if not args.dry_run:
            os.makedirs('{0}/{1}'.format(segment_dir, gps_dir), exist_ok=True)
            DQDic.write(output_xml, overwrite=args.overwrite, format='ligolw')

#########################################
###  EOF
#########################################
