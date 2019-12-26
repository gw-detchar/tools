from gwpy.segments import DataQualityFlag


locked = DataQualityFlag.read('tmp/SegmentList_IMC_UTC_2019-12-25.xml')
locked2 = DataQualityFlag.read('tmp/SegmentList_IMC_UTC_2019-12-25_2.xml')

print(locked)
print(locked2)

total = locked+locked2

print(total)

total.write('tmp/SegmentList_IMC_UTC_2019-12-25_total.xml')
