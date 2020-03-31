'''
This script generates HTMLs for EventPlot.
'''

import os
import glob

#  argument processing
import argparse

parser = argparse.ArgumentParser(description='Make coherencegram.')
parser.add_argument('-d','--date',help='Date to be proccessd. eg. 20200320 ',default='20200320')
parser.add_argument('-i','--inputdir',help='Input directory.',default='/Users/kozakai/Documents/KAGRA/DetChar/Kashiwa/20200320/GlitchPlot/')
#parser.add_argument('-o','--outputdir',help='Output directory.',default='/Users/kozakai/Documents/KAGRA/DetChar/Kashiwa/20200320/')
#parser.add_argument('-i','--inputdir',help='Input directory.',default='/mnt/GlitchPlot/')
#parser.add_argument('-o','--outputdir',help='Output directory.',default='/mnt/GlitchPlot/')



# define variables
args = parser.parse_args()

date = args.date
ind = args.inputdir
#outd = args.outputdir

# Functions

def WriteHeader(fname):
    '''
    Write down header and logo/links in the top of the page.
    '''
    
    with open(fname,mode='w') as f:
        string='\
<!DOCTYPE HTML PUBLIC >\n\
    <html>\n\
        <head>\n\
            <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n\
            <meta name="author" content="Chihiro Kozakai">\n\
            <title>KAGRA EventPlot</title>\n\
            <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\">\n\
        </head>\n\
        \n\
        <body>\n\
            <a href=\"https://www.icrr.u-tokyo.ac.jp/~yuzu/bKAGRA_summary/html/list_of_date.html\">\n\
                <div class=\"img_header\">\n\
                <img src=\"https://www.icrr.u-tokyo.ac.jp/~yuzu/bKAGRA_summary/fig/header_kagra.gif\" alt="Link to top page">\n\
                </div>\n\
            </a>\n\
            <br>\n\
            <a href=\"https://docs.google.com/spreadsheets/d/1JxC3QL6jF3xmA0MnWtWO_dUgNOF_i5enD_j4yUK1X7s/edit?usp=sharing\" target=\"_blank\" title=\"GlitchPlot Catalog\" >GlitchPlot Catalog</a>\n\
            &ensp;\n\
            <a href=\"https://gwdoc.icrr.u-tokyo.ac.jp/cgi-bin/private/DocDB/ShowDocument?docid=10371\" target=\"_blank\" title=\"GlitchPlot introduction\" >GlitchPlot introduction</a>\n\
            &ensp;\n\
            <a href=\"http://gwwiki.icrr.u-tokyo.ac.jp/JGWwiki/KAGRA/Subgroups/DET/GlitchPlot\" target=\"_blank\" title=\"GlitchPlot wiki\" >GlitchPlot wiki</a>\n\
            <br>\n\
'

        f.write(string)

        
def WriteFooter(fname):
    '''
    Write down hooter and contact information at the bottom of the page.
    '''
    
    with open(fname,mode='a') as f:
        string='\
        <br><hr><br>If you have any problem, any comment or any request about this page, please contact <a href="mailto:ckozakai@icrr.u-tokyo.ac.jp">C. Kozakai</a>.\n\
    </body>\n\
</html>\n\
'
        f.write(string)

# Template
'''
def WriteFooter(fname):
    
    with open(fname,mode='a') as f:
        # \ is required to ignore line break in the string for python.
        string='\

'
        f.write(string)
'''

#####################################################################
# Make top page.
#####################################################################
        
ftop = ind +"index.html"

WriteHeader(ftop)

# Make link for event list of each day

datelist = [os.path.basename(p.rstrip(os.sep)) for p in glob.glob(ind+"/*/")]
datelist.sort()

with open(ftop,mode='a') as f:

    string='\
            <p>\n\
            Please choose the date in JST.\n\
            </p>\n'
    f.write(string)
    
    for date in datelist:
        string='\
            <br>\n\
            <a href='+date+'/html/index.html>'+date+'</a>\n'
        f.write(string)

WriteFooter(ftop)

#####################################################################
# Make eventlist for each day.
#####################################################################

#for date in datelist:
latestdate=datelist[len(datelist)-1]
for i in range(len(datelist)):
    date = datelist[i]
    if not os.path.isdir(ind+date+"/html"):
        os.makedirs(ind+date+"/html")

    fdaily = ind+date+"/html/index.html"
    WriteHeader(fdaily)

    # Link to other days

    with open(fdaily,mode='a') as f:

        string='\
<span style=\"font-size:16pt;\">\n'

        if i != 0:
            prevdate = datelist[i-1]
            string+='<a href=../../'+prevdate+'/html/index.html target=\"_self\"><< Previous day('+prevdate+')</a> &ensp;&ensp;\n'

        string+='<a href=../../index.html >List of Date(all)</a> &ensp;&ensp;\n\
<a href=../../'+latestdate+'/html/index.html target=\"_self\">Latest</a> &ensp;&ensp;\n'

        if i != len(datelist)-1:
            nextdate = datelist[i+1] 
            string+='<a href=../../'+nextdate+'/html/index.html target=\"_self\"><< Next day('+nextdate+')</a> &ensp;&ensp;\n'

        f.write(string)
        
    eventlist = [os.path.basename(p.rstrip(os.sep)) for p in glob.glob(ind+date+"/events/*/")]
    
    with open(fdaily,mode='a') as f:

        string='\
            <p>\n\
            Please choose interested event.\n\
            </p>\n'
        f.write(string)
 
       
        for event in eventlist:

            string='\
            <br>\n\
            <a href='+event+'.html>'+event+'</a>\n'
            f.write(string)

            #####################################################################
            # Make event pages.
            #####################################################################

            eventdir = ind+date+"/events/"+event+"/"

            fevent = ind+date+"/html/"+event+".html"

            WriteHeader(fevent)

            with open(fevent,mode='a') as fe:
                string='\
<p>\n\
test.\n\
</p>'
                fe.write(string)
            WriteFooter(fevent)

        
    WriteFooter(fdaily)
