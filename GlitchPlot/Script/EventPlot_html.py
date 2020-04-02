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

def WriteHeader(fname, place=''):
    '''
    Write down header and logo/links in the top of the page.
    place is relative place to the ind.
    '''
    
    with open(fname,mode='w') as f:
        string='\
<!DOCTYPE HTML PUBLIC >\n\
    <html>\n\
        <head>\n\
            <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n\
            <meta name="author" content="Chihiro Kozakai">\n\
            <title>KAGRA EventPlot</title>\n\
            <link rel=\"stylesheet\" type=\"text/css\" href=\"'+place+'style.css\">\n\
            <link rel="shortcut icon" href='+place+'GlitchPlot_minilogo.png>\n\
        </head>\n\
        \n\
        <body>\n\
            <a href='+place+'index.html>\n\
                <div class=\"img_header\">\n\
                <img src='+place+'GlitchPlot_logo.png alt="Link to top page" width=700>\n\
                </div>\n\
            </a>\n\
            <br>\n\
            <a href=\"https://docs.google.com/spreadsheets/d/1JxC3QL6jF3xmA0MnWtWO_dUgNOF_i5enD_j4yUK1X7s/edit?usp=sharing\" target=\"_blank\" title=\"GlitchPlot Catalog\" >GlitchPlot Catalog</a>\n\
            &ensp;\n\
            <a href=\"https://gwdoc.icrr.u-tokyo.ac.jp/cgi-bin/private/DocDB/ShowDocument?docid=10371\" target=\"_blank\" title=\"GlitchPlot introduction\" >GlitchPlot introduction</a>\n\
            &ensp;\n\
            <a href=\"http://gwwiki.icrr.u-tokyo.ac.jp/JGWwiki/KAGRA/Subgroups/DET/GlitchPlot\" target=\"_blank\" title=\"GlitchPlot wiki\" >GlitchPlot wiki</a>\n\
            <br>\n\
            <br>\n\
'
#
        f.write(string)

        
def WriteFooter(fname):
    '''
    Write down hooter and contact information at the bottom of the page.
    '''
    
    with open(fname,mode='a') as f:
        string='\
        <p style="clear: left;">\n\
        <br><hr><br>\n\
        If you have any problem, any comment or any request about this page, please contact <a href="mailto:ckozakai@icrr.u-tokyo.ac.jp">C. Kozakai</a>.\n\
        </p>\n\
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
        
    eventlist = [os.path.basename(p.rstrip(os.sep)) for p in glob.glob(ind+date+"/events/*/")]
    eventlist.sort()

    gpstimedict = {}
    JSTglitchdict = {}   # To be modified
    snrdict = {}
    frequencydict = {}
    durationdict = {}
    pipelinedict = {}
    mainchanneldict = {}
    categorydict = {}
    
    for event in eventlist:
        # Get event information.
            
        categorywords = {"CBC":"CBC","Burst":"Burst","glitch":"Glitch","lockloss":"Lock loss"}
        fparameter = glob.glob(ind+date+"/events/"+event+"/parameter.txt")[0]

        with open(fparameter,mode='r') as fp:
            parameters = fp.read().split()
            gpstime = float(parameters[0])
            JSTglitch = parameters[0]   # To be modified
            snr = parameters[5]
            frequency = parameters[6]
            duration = parameters[3]
            pipeline = parameters[10]
            mainchannel = parameters[1]
            category = categorywords[parameters[9]]

            gpstimedict[event]=gpstime
            JSTglitchdict[event]=JSTglitch
            snrdict[event]=snr
            frequencydict[event]=frequency
            durationdict[event]=duration
            pipelinedict[event]=pipeline
            mainchanneldict[event]=mainchannel
            categorydict[event]=category


        #####################################################################
        # Make event pages.
        #####################################################################

        eventdir = ind+date+"/events/"+event+"/"

        fframe = ind+date+"/html/"+event+".html"
        with open(fframe,mode='w') as ff:
            string='\
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">\n\
<html>\n\
<head>\n\
<title>KAGRA GlitchPlot</title>\n\
<link rel=\"stylesheet\" type=\"text/css\" href=\"../../style.css\">\n\
<link rel="shortcut icon" href=../../GlitchPlot_minilogo.png>\n\
</head>\n\
\n\
<frameset cols="*,500">\n\
\n\
<frame src='+event+'_plots.html name="frame1" title="left">\n\
<frame src='+event+'_form.html name="frame2" title="right">\n\
\n\
<noframes>\n\
<body>\n\
<p>content</p>\n\
</body>\n\
</noframes>\n\
\n\
</frameset>\n\
\n\
</html>\n'
            ff.write(string)
        

        fform = ind+date+"/html/"+event+"_form.html"
        #WriteHeader(fform,place="../../")

        with open(fform,mode='w') as ff:

#<a href=\"javascript:history.back()\" target="_top">Back to trigger list</a> &ensp;&ensp;\n\
#<a href=../../index.html target="_top">List of Date(all)</a> &ensp;&ensp;\n\
#<br><br>\n\
#<hr>\n\
            string='\
<!DOCTYPE HTML PUBLIC >\n\
    <html>\n\
        <head>\n\
            <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n\
            <meta name="author" content="Chihiro Kozakai">\n\
            <title>KAGRA EventPlot</title>\n\
            <link rel=\"stylesheet\" type=\"text/css\" href=\"../../style.css\">\n\
            <link rel="shortcut icon" href=../../GlitchPlot_minilogo.png>\n\
        </head>\n\
        \n\
        <body>\n\
<span style="font-size:18pt; color:royalblue;">GlitchPlot needs your help to classify the glitch origin.</span>\n\
<br>\n\
<br>\n\
\
<form id="form" method="get" action="https://script.google.com/macros/s/AKfycbx0aGq4Lgknln9psGopJm6UPW-zXkNt4LOsus8x6W2UcD2mV1Y/exec" accept-charset="UTF-8" target="_blank">\n\
<input type="hidden" name="channelname" value="'+mainchannel+'">\n\
<input type="hidden" name="gpsglitch" value="'+str(gpstime)+'">\n\
<input type="hidden" name="JSTglitch" value="'+JSTglitch+'">\n\
<input type="hidden" name="web" value="https://gwdet.icrr.u-tokyo.ac.jp/~controls/GlitchPlot/'+date+'/html/'+event+'.html">\n\
<input type="hidden" name="snr"       value="'+snr+'">\n\
<input type="hidden" name="frequency" value="'+frequency+'">\n\
<input type="hidden" name="duration" value="'+duration+'">\n\
<input type="hidden" name="pipeline" value="'+pipeline+'">\n\
\n\
1. Fill your name\n\
<br>\n\
\n\
\n\
<input type="text" name="yourname" placeholder="Your name">\n\
<br><br>\n\
\n\
2. Are you familiar with the latest KAGRA?\n\
<br>\n\
\n\
\n\
\n\
<input type="radio" name="team" value="Onsite" checked>Yes (On-site researcher)\n\
\n\
\n\
<input type="radio" name="team" value="Offsite">No (Off-site researcher)\n\
<br><br>\n\
\n\
3-1. Suspect the glitch origin.\n\
<br>\n\
<select name="kindglitch">\n\
<option value="None">No idea</option>\n\
<option value="Accoustic">Environment (accoustic)</option>\n\
<option value="Magnetic">Environment (magnetic)</option>\n\
<option value="Seismic activity">Environment (seismic, earthquake)</option>\n\
<option value="Human activity">Environment (Human activity in mine)</option>\n\
<option value="Typhoon">Environment (typhoon)</option>\n\
<option value="Hardware injection">Hardware injection</option>\n\
<option value="Software injection">Software injection</option>\n\
<option value="Real time system">Related to real time system</option>\n\
<option value="Laser">Related to laser(PSL, IMC)</option>\n\
<option value="Unknown">Unknown noise (write your opinion in comment)</option>\n\
<option value="GravitationalWave">Gravitational wave !!</option>\n\
<option value="Other">other (If no suitable option, select other and write comments)</option>\n\
</select>\n\
\n\
<br>\n\
<br>\n\
\n\
3-2. If you want, you can specify the sensor and location where the glitch was found.\n\
<br>\n\
\n\
Sensor :\n\
<select name="glitchsensor">\n\
<option value="None">No idea</option>\n\
<option value="Accelerometer">Accelerometer</option>\n\
<option value="Seismometer">Seismometer</option>\n\
<option value="Microphone">Microphone</option>\n\
<option value="Magnetometer">Magnetometer</option>\n\
<option value="Oplev">Oplev</option>\n\
<option value="VIS related">VIS related</option>\n\
<option value="Control system">Control System</option>\n\
<option value="Other">other (You can write comments below)</option>\n\
</select>\n\
\n\
\n\
\n\
Location :\n\
<select name="glitchlocation">\n\
<option value="None">No idea</option>\n\
<option value="PSL">PSL</option>\n\
<option value="IMC">IMC</option>\n\
<option value="SR2">SR2</option>\n\
<option value="SR3">SR3</option>\n\
<option value="POP">POP</option>\n\
<option value="POS">POS</option>\n\
<option value="IMMT1">IMMT1</option>\n\
<option value="IMMT2">IMMT2</option>\n\
<option value="OMMT1">OMMT1</option>\n\
<option value="OMMT2">OMMT2</option>\n\
<option value="OMC">OMC</option>\n\
<option value="Center">Center</option>\n\
<option value="IX">IX</option>\n\
<option value="EX">EX</option>\n\
<option value="IY">IY</option>\n\
<option value="EY">EY</option>\n\
<option value="all">all</option>\n\
<option value="Control system">Control System</option>\n\
<option value="Out of mine">Out of mine</option>\n\
<option value="Other">other (You can write comments below)</option>\n\
</select>\n\
\n\
<br><br>\n\
\n\
4. Add any suspects about the origin, comment, request, or fan letter to developpers.\n\
<br>\n\
<textarea name="comment" rows="6" cols="50" placeholder="comment or fan letter"></textarea>\n\
<br><br>\n\
<input type="submit" value="Submit"/>\n\
</form>\n\
\n\
<span style="font-size:18pt; color:royalblue;">Thank you in advance, we really appreciate your help.\n\
</br>\n\
\n\
You can see the result in <a href="https://docs.google.com/spreadsheets/d/1JxC3QL6jF3xmA0MnWtWO_dUgNOF_i5enD_j4yUK1X7s/edit?usp=sharing" target="_blank" title="GlitchPlot Catalog" >GlitchPlot Catalog</a>.\n\
\n\
</span>\n\
<br>\n\
<br>\n\
'
            ff.write(string)
        WriteFooter(fform)


    #####################################################################
    # Make eventlist for each day.
    #####################################################################

    fdaily = ind+date+"/html/index.html"

    WriteHeader(fdaily,place="../../")

    # Link to other days

    with open(fdaily,mode='a') as f:

        string='\
<span style=\"font-size:16pt;\">\n'

        # if there is previous date
        if i != 0:
            prevdate = datelist[i-1]
            string+='<a href=../../'+prevdate+'/html/index.html target=\"_self\"><< Previous day('+prevdate+')</a> &ensp;&ensp;\n'
        else:
            string+='No previous result &ensp;&ensp;\n'
        string+='<a href=../../index.html >List of Date(all)</a> &ensp;&ensp;\n\
<a href=../../'+latestdate+'/html/index.html target=\"_self\">Latest</a> &ensp;&ensp;\n'

        # if there is next date
        if i != len(datelist)-1:
            nextdate = datelist[i+1] 
            string+='<a href=../../'+nextdate+'/html/index.html target=\"_self\"> Next day('+nextdate+') >></a> &ensp;&ensp;\n'
        else:
            string+='No next result &ensp;&ensp;\n'

        string+='</span>\n'
        f.write(string)

        string='\
<hr><br>\n\
<span style="font-size:25pt; color:#000000;"> Glitch list on '+date+' JST</span><br>\n\
            <p>\n\
            Please choose interested event.\n\
            </p>\n'
        f.write(string)

        tmplist=sorted(gpstimedict.items(), key=lambda x:x[1])

        for tmp in tmplist:
            # Get main channel q-transform plot for link
            event=tmp[0]

            mainfig=glob.glob(ind+date+"/events/"+event+"/"+mainchanneldict[event]+"_qtransform*")
            if len(mainfig) != 0:
                linkfig = mainfig[0].replace(ind+date,"..")
                string='\
                <div class="imagebox">\n\
            <a href='+event+'.html>\n\
                    <p class="image"><img src='+linkfig+' alt="Link to event page" width=400></p>\n\
                    <p class="caption">'+categorydict[event]+'<br>'+str(gpstimedict[event])+'</p>\n\
            </a>\n\
                </div>\n'

            else:
                string='\
            <a href='+event+'.html>'+event+'</a>\n'

            f.write(string)

        
    WriteFooter(fdaily)
