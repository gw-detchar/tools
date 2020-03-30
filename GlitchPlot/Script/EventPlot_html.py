'''
This script generates HTMLs for EventPlot.
'''

#  argument processing
import argparse

parser = argparse.ArgumentParser(description='Make coherencegram.')
parser.add_argument('-d','--date',help='Date to be proccessd. eg. 20200320 ',default='20200320')

# define variables
args = parser.parse_args()

date = args.date

ftop = date+"_GlitchPlot.html"

