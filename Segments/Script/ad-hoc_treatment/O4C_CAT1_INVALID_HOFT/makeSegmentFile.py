#!/usr/bin/env python
#******************************************#
#     File Name: makeSegmentFile.py
#        Author: Takahiro Yamamoto
# Last Modified: 2026/08/07 10:47:27
#******************************************#

import os
from gwpy.segments import DataQualityFlag,SegmentList

def INVALID_MEASUREMENT():
    segname = 'CAL_HOFT_NOT_OK'
    DQF = DataQualityFlag(
        name = 'K1:{0}:1'.format(segname),
        category = None,
        label = 'INVALID_HOFT',
        description = 'hoft is unavailable due to calibration issue',
        isgood = False,
    )

    ### Known segment
    startO4c = 1433689218 ### 2025-06-11 15:00:00 UTC
    endO4c   = 1447516818 ### 2025-11-18 16:00:00 UTC
    DQF.known = SegmentList( [(startO4c, endO4c)] )
    
    ### Problematic segment
    startSeg = 1447062499 ### 2025-11-13 09:48:01 UTC
    endSeg   = 1447114214 ### 2025-11-14 00:09:56 UTC
    DQF.active = SegmentList( [(startSeg, endSeg)] )

    return DQF

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='make "CAL_HOFT_NOT_OK" segment')
    parser.add_argument('--path', type=str, required=True, help='output directory')
    args = parser.parse_args()

    DQF = INVALID_MEASUREMENT()
    os.makedirs(args.path, exist_ok=True)
    DQF.write('{0}/K1-CAL_HOFT_NOT_OK_O4c.xml'.format(args.path), format='ligolw')

############################################
### EOF
############################################
