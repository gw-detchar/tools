#!/usr/bin/env python
#******************************************#
#     File Name: makeDATASegment.py
#        Author: Takahiro Yamamoto
# Last Modified: 2026/08/07 04:35:04
#******************************************#

import os
import glob
import numpy as np
import subprocess

from gwpy.segments import DataQualityFlag,DataQualityDict

ALIAS = {
    '@full'  : '/home/detchar/cache/Cache_GPS',
    '@second': '/home/detchar/cache/CacheSecond_GPS',
    '@minute': '/home/detchar/cache/CacheMinute_GPS',
}

def _make_data0_flag(cache_data:np.ndarray, framecheck=True) -> DataQualityFlag:
    gwf = DataQualityFlag(name = 'K1:DATA_{0}:1'.format(cache_data[0][1]),
                          label = 'DATA_{0}'.format(cache_data[0][1]),
                          category = None,
                          description = 'available data',
                          isgood = True)
    
    for _, _, tt, dd, _ in cache_data:
        gwf_t0 = int(tt)
        gwf_t1 = gwf_t0 + int(dd)
        gwf.active += [(gwf_t0, gwf_t1)]
        
    if len(gwf.active) == 0:
        return gwf
    gwf.known = [(gwf.active[0][0], gwf.active[-1][1])]

    if framecheck == True:
        frame = DataQualityFlag(name = 'K1:DATA_FRAME:1',
                                label = 'DATA_FRAME',
                                category = None,
                                description = 'frame in GWF',
                                isgood = True,
                                known = gwf.known,
        )

        gap = DataQualityFlag(name = 'K1:DATA_FRAME_GAP:1',
                              label = 'DATA_FRAME_GAP',
                              category = None,
                              description = 'gap in GWF',
                              isgood = False,
                              known = gwf.known,
        )

        for _, _, tt, dd, ff in cache_data:
            cmd = 'FrDump -i {0} | grep "at:"'.format(ff.replace('file://localhost', ''))
            output = subprocess.run(cmd, capture_output=True, text=True, shell=True).stdout
            for ll in output.splitlines():
                line = ll.split()
                frame_tt = int(line[3].replace('at:', ''))
                if 'First' in ll:
                    frame_t0 = frame_tt
                    gap.active += [(int(tt), frame_tt)]
                elif 'Missing' in ll:
                    frame.active += [(frame_t0, frame_tt)]
                    frame_t0 = frame_tt + int(line[9].replace('(', '').replace('.000s.', ''))
                    gap.active += [(frame_tt, frame_t0)]
                elif 'Last' in ll:
                    frame.active += [(frame_t0, frame_tt)]
                    gap.active += [(frame_tt, int(tt)+int(dd))]

        if len(frame.active) != 0:
            frame.known = [(
                min(frame.active[0][0], frame.known[0][0]),
                max(frame.active[-1][1], frame.known[-1][1])
            )]

        gwf &= ~gap
        
        if gwf.known != frame.known:
            gwf.known = frame.known
        if gwf.active != frame.active:
            gwf.known = frame.known

    return gwf

def make_data0_flag(gps0:int, gps1:int, cache:str, framecheck:bool=True, round:bool=True) -> DataQualityFlag:
    if os.path.isfile(cache):
        cache_data = np.loadtxt(cache, dtype=str)
    elif os.path.isdir(cache):
        dir0 = int(gps0 / 100000) - 1
        dir1 = int((gps1-1) / 100000) + 1
        
        caches = [c for c in sorted(glob.glob('{0}/*.cache'.format(cache)))
                  if dir0 <= int(os.path.splitext(os.path.basename(c))[0]) <= dir1]

        if len(caches) == 0:
            print("Can't find cache files in {0}".format(cache))
            return None
        cache_data = np.concatenate(
            [np.loadtxt(c, dtype=str)
             for c in caches]
        )
    else:
        print("Can't find {0}".format(cache))
        return None

    gps = cache_data[:, 2].astype(int)
    duration = cache_data[:, 3].astype(int)
    mask = (gps0 <= (gps+duration)) & (gps <= gps1)
    masked_data = cache_data[mask]
    if len(masked_data) != 0:
        cache_data = masked_data
    else:
        cache_data = cache_data[0:1]

    dqflag = _make_data0_flag(cache_data, framecheck=framecheck)
    if round:
        dqflag.known = [(gps0, gps1)]
        dqflag.coalesce()        
    elif len(dqflag.known) > 0:
        dqflag.known = [(
            max(gps0, dqflag.known[0][0]),
            min(gps1, dqflag.known[-1][1]),
        )]
        dqflag.coalesce()
    return dqflag

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        description='make K1_DATA (to ensure the existence of the frames) segments the cache files',
    )
    parser.add_argument('--gps0', type=int, required=True, help='start gpstime')
    parser.add_argument('--gps1', type=int, required=True, help='stop gpstime')
    parser.add_argument('--cache', type=str, required=True, nargs='+', help='cache file (*.cache) or cache directory')
    parser.add_argument('--truncate', action='store_true', help='truncate exact given time')
    parser.add_argument('--output', type=str, help='output filename')
    parser.add_argument('--overwrite', action='store_true', help='overwrite exist XMLs')
    args = parser.parse_args()

    DQDic = DataQualityDict()
    for cc in args.cache:
        if cc in ALIAS.keys():
            cc = ALIAS[cc]
        xs = make_data0_flag(args.gps0, args.gps1, cc, round=args.truncate)
        if xs != None:
            DQDic[xs.name] = xs
    DQDic.write(args.output, overwrite=args.overwrite, format='ligolw')

############################################
### EOF
############################################
