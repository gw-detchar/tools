#!/usr/bin/env python
#******************************************#
#     File Name: findSegments.py
#        Author: Takahiro Yamamoto
# Last Modified: 2025/11/14 11:41:04
#******************************************#

import re
import os
import glob

import gpstime
from gwpy.segments import DataQualityDict,DataQualityFlag

def _check_type(seg_dir):
    child_dir = sorted(glob.glob('{0}/*'.format(seg_dir)))
    if len(child_dir) == 0:
        return 'Unknown'

    try:
        x = int(os.path.basename(child_dir[0]))
        if x < 3000:
            return 'UTC1'
        else:
            return 'GPS'
    except:
        return 'UTC'

def findSegmentFiles(seg_dir, gps0, gps1):
    seg_type = _check_type(seg_dir)
    if seg_type == 'GPS':
        gps_dir_0 = int(gps0 / 100000)
        gps_dir_1 = int(gps1 / 100000)

        gps_dir = [d for d in glob.glob('{0}/[0-9][0-9]*'.format(seg_dir))
                   if gps_dir_0 <= int(os.path.basename(d)) <= gps_dir_1]

        files = [f for d in gps_dir for f in glob.glob('{0}/*.xml'.format(d))
                 if gps0 - int(re.split('[-.]', f)[-2]) <= int(re.split('[-.]', f)[-3]) <= gps1]
        return files
    elif seg_type in ['UTC', 'UTC1']:
        year0 = int(gpstime.tconvert(gps0).split(' ')[0].split('-')[0])
        year1 = int(gpstime.tconvert(gps1).split(' ')[0].split('-')[0])

        if seg_type == 'UTC':
            year_dir = [d for d in glob.glob('{0}/*/[0-9][0-9]*'.format(seg_dir))
                        if year0 <= int(os.path.basename(d)) <= year1]
        else:
            year_dir = [d for d in glob.glob('{0}/[0-9][0-9]*'.format(seg_dir))
                        if year0 <= int(os.path.basename(d)) <= year1]

        files = [f for d in year_dir for f in glob.glob('{0}/*.xml'.format(d))
                 if gps0 - 86400 <= gpstime.tconvert('{0} 00:00:00 UTC'.format(re.split('[_.]', os.path.basename(f))[-2])) <= gps1]
        return files
    else:
        raise("Can't decide directory structure")
    
def findSegments(seg_dir, gps0, gps1, truncate=False):
    try:
        files = findSegmentFiles(seg_dir, gps0, gps1)
    except:
        files = []

    if len(files) == 0:
        return None
    else:
        xs = DataQualityDict.read(files, coalesce=True)
        if truncate == True:
            y = DataQualityFlag(known=[(gps0, gps1)], active=[(gps0, gps1)])
            xs = {k: v & y for k, v in xs.items()}
        return xs

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        description='find segments',
        # epilog='> python3 makeSegmentDict.py'
    )
    parser.add_argument('--directory', type=str, required=True, metavar='DIR',
                        help='path to the primary segment directory')
    parser.add_argument('--t0', type=int, required=True,
                        help='start gps time')
    parser.add_argument('--t1', type=int, required=True,
                        help='end gps time')
    parser.add_argument('--truncate', action='store_true',
                        help='truncate as [t0, t1)')
    parser.add_argument('--names', type=str, nargs='+', metavar='NAME',
                        help='')
    parser.add_argument('--show-names', action='store_true',
                        help='show segment names in files')
    parser.add_argument('--show-files', action='store_true',
                        help='show segment files')
    args = parser.parse_args()

    if args.show_files:
        files = findSegmentFiles(args.directory, args.t0, args.t1)
        for ff in files:
            print(ff)
    else:
        dq = findSegments(args.directory, args.t0, args.t1, truncate=args.truncate)

        if dq == None:
            print("Can't find segment [{0}, {1}) in {2}".format(args.t0, args.t1, args.directory))
        elif args.show_names:
            for key in dq.keys():
                print(key)
        elif args.names:
            for key in args.names:
                print(dq[key])
        else:
            for key in dq.keys():
                print(dq[key])
        
