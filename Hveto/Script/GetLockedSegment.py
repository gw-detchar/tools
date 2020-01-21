'''
This script gives locked segment including the given gps time.
'''

import sys
import subprocess
import argparse
from gwpy.segments import DataQualityFlag
from gwpy.segments import SegmentList
from gwpy.segments import Segment

parser = argparse.ArgumentParser(description='Get locked segment including the given gps time.')
parser.add_argument('-t','--time',help='input gpstime.',required=True)
parser.add_argument('-d','--date',help='input date',required=True)

args = parser.parse_args()
time = int(args.time)
date = args.date

segmentfile="/users/DET/Segments/SegmentList_FPMI_UTC_"+date+".xml"

Locked = DataQualityFlag.read(segmentfile)

#triggerseg = DataQualityFlag(known=[time-30,time+30], active=[time-1,time+1])
triggerseg=SegmentList([Segment(time-1,time+1)])
IsLocked = Locked.active.intersects(triggerseg)

if IsLocked:
    for seg in Locked.active:
        if seg[0] < time and time < seg[1]:
            print(str(seg[0]) + " " + str(seg[1]))
            break

else:
    print("Not locked.")
