#!/usr/bin/env python
#******************************************#
#     File Name: ipcGlitchEachModel.py
#        Author: Takahiro Yamamoto
# Last Modified: 2025/07/26 13:13:08
#******************************************#

import os
import sys
import numpy as np

from findSegments import findSegments
from DAQ_IPC_ERROR import _make_ipc_glitch_flag

from FEC import FECs

import gpstime
from gwpy.timeseries import TimeSeriesDict
from gwpy.segments import DataQualityDict,DataQualityFlag

CACHEDIR = {
    'Kamioka': '/users/DET/Cache/Cache_GPS',
    'Kashiwa': '/home/detchar/cache/Cache_GPS'
}
GWFLEN=32

def _get_gwf_list(start_gps, stop_gps, cachedir):
    cachefiles = sorted({ '{0}/{1}.ffl'.format(cachedir, int(t/100000))
                          for t in [start_gps, stop_gps]
                          if os.path.exists('{0}/{1}.ffl'.format(cachedir, int(t/100000)))
                         })
    gwffiles = [l[0] for c in cachefiles for l in np.loadtxt(c, dtype=str) if int(start_gps/GWFLEN)*GWFLEN <= int(l[1]) < stop_gps]
    return gwffiles

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='a')
    parser.add_argument('--cluster', type=str, required=True, choices=['Kamioka', 'Kashiwa'], help='cluster')
    parser.add_argument('--term', type=str, choices=['O4a', 'O4c'], help='start gpstime')
    parser.add_argument('--t0', type=int, help='start gpstime')
    parser.add_argument('--t1', type=int, help='end gpstime')
    parser.add_argument('--utc', type=str, help='utc date')
    parser.add_argument('--science', type=str,
                        default='/users/DET/Segments/K1-GRD_SCIENCE_MODE',
                        help='path to science-mode segments [default=/users/DET/Segments/K1-GRD_SCIENCE_MODE]')
    parser.add_argument('--output', type=str, required=True,
                        help='output directory')
    parser.add_argument('--cachedir', type=str, default=None, help='path to cache dir [default=None]')
    parser.add_argument('--nds', type=str, default=None, help='used NDS (host:port) [default=None]')
    args = parser.parse_args()

    if args.t0 and args.t1:
        gps0 = args.t0
        gps1 = args.t1
        base = 'K1_IPC_GLITCH_EACH_MODEL-{0}-{1}.xml'.format(gps0, gps1-gps0)
    elif args.utc:
        gps0 = gpstime.tconvert('{0} 00:00:00 UTC'.format(args.utc))
        gps1 = gps0 + 86400
        base = 'K1_IPC_GLITCH_EACH_MODEL-{0}_UTC.xml'.format(args.utc)
    elif args.term:
        gps0, gps1 = {'O4a' : (1368975618.0, 1371337218.0),
                      'O4c' : (1433689218.0, 1443884418.0)}[args.term]
        base = 'K1_IPC_GLITCH_EACH_MODEL-{0}.xml'.format(args.term)
    else:
        parser.print_help()
        print('\nrequired one of --term, a pair of (--t0, --t1), or --utc')
        exit(-1)
    science_seg = args.science
    output_dir = args.output
    if args.cachedir == None:
        cache_dir = CACHEDIR[args.cluster]
    else:
        cache_dir = args.cachedir

    ### Intialize DataQualityDict
    DQdic = DataQualityDict()
    for fec in FECs.keys():
        DQdic[FECs[fec]] = DataQualityFlag()
        DQdic[FECs[fec]].name = 'K1:DAQ_IPC_ERROR_{0}:1'.format(FECs[fec])
        DQdic[FECs[fec]].label = 'IPC_ERROR_{0}'.format(FECs[fec])
        DQdic[FECs[fec]].category = None
        DQdic[FECs[fec]].description = 'glitches on {0} due to digital system trouble'.format(FECs[fec].lower())
        DQdic[FECs[fec]].isgood = False

    ### Read Science segments
    DQsci = findSegments(science_seg, gps0, gps1)['K1:GRD_SCIENCE_MODE:1']

    ### Make Segments
    chans = ['K1:FEC-{0}_TIME_DIAG'.format(fec) for fec in FECs.keys()]
    n_chans = len(chans)
    n_read = 18
    for act in DQsci.active:
        start, end = act
        if gps0 > end or gps1 < start:
            continue

        if start < gps0:
            start = gps0
        if gps1 < end:
            end = gps1
        print(start, end, end-start)

        if args.nds == None:
            gwf_files = _get_gwf_list(start, end, cache_dir)
        else:
            port = 8088
            host = args.nds.split(':')
            if len(host) >= 2:
                try:
                    port = int(host[1])
                except:
                    pass
            host = host[0]
        for nn in range(n_read,n_chans+n_read,n_read):
            if args.nds == None:
                TSdic = TimeSeriesDict.read(gwf_files, chans[nn-n_read:min(nn,n_chans)], start=start, end=end)
            else:
                TSdic = TimeSeriesDict.fetch(chans[nn-n_read:min(nn,n_chans)], start=start, end=end, host=host, port=port)
            for chan in TSdic.keys():
                fec = int(chan.replace('K1:FEC-', '').replace('_TIME_DIAG', ''))
                dqf = _make_ipc_glitch_flag( TimeSeriesDict({chan: TSdic[chan]}) )
                DQdic[FECs[fec]] |= dqf

    os.makedirs(output_dir, exist_ok=True)
    DQdic.write('{0}/{1}'.format(output_dir, base), overwrite=False, format='ligolw')

