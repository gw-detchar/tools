#!/usr/bin/env python
#******************************************#
#     File Name: compareSegmentDict.py
#        Author: Takahiro Yamamoto
# Last Modified: 2025/06/20 23:00:28
#******************************************#

from gwpy.segments import SegmentList

from findSegments import findSegments

def compareSegmentDict(dq1, dq2, t0=None, t1=None):
    diff = False
    if dq1.keys() != dq2.keys():
        print('Different keys')
        print('  Missing in DQ1\n    => {0}'.format(list( dq1.keys() - dq2.keys()) ) )
        print('  Missing in DQ2\n    => {0}'.format(list( dq2.keys() - dq1.keys()) ) )
        diff |= True


    msg = []
    for key in dq1.keys() & dq2.keys():
        if t0 != None and t1 != None:
            dq1[key].known &= SegmentList( [(t0, t1)] )
            dq2[key].known &= SegmentList( [(t0, t1)] )

        dq1[key].coalesce()
        dq2[key].coalesce()

        known_xor = dq1[key].known ^ dq2[key].known
        active_xor = dq1[key].active ^ dq2[key].active
        if known_xor != [] or active_xor != []:
            msg += ['  {0}\n   - known  => {1}\n   - active => {2}\n'.format(key, known_xor, active_xor)]

    if msg != []:
        print('\nDifferent segments')
        print('\n'.join(msg))
        diff |= True
    
    return diff

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        description='compare two segments',
        # epilog='> python3 makeSegmentDict.py'
    )
    parser.add_argument('--dir1', type=str, required=True, metavar='DIR1',
                        help='path to the primary segment directory')
    parser.add_argument('--dir2', type=str, required=True, metavar='DIR2',
                        help='path to the secondary segment directory')
    parser.add_argument('--t0', type=int, required=True,
                        help='start gps time')
    parser.add_argument('--t1', type=int, required=True,
                        help='end gps time')
    args = parser.parse_args()

    dq1 = findSegments(args.dir1, args.t0, args.t1)
    dq2 = findSegments(args.dir2, args.t0, args.t1)

    msg = []
    if dq1 == None:
        msg += [args.dir1]
    if dq2 == None:
        msg += [args.dir2]

    if msg == []:
        compareSegmentDict(dq1, dq2, args.t0, args.t1)
    else:
        print("Can't find segment [{0}, {1}) in {2}".format(args.t0, args.t1, ', '.join(msg)))
