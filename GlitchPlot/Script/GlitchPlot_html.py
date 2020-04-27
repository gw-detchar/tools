'''
This script generates HTMLs for GlitchPlot.
'''

import os
import glob
import datetime
import subprocess
import matplotlib
matplotlib.use('Agg')  # this line is required for the batch job before importing other matplotlib modules.  

#  argument processing
import argparse

parser = argparse.ArgumentParser(description='Make html for GlitchPlot.')
#parser.add_argument('-d','--date',help='Date to be proccessd. eg. 20200320 ',default='20200320')
#parser.add_argument('-i','--inputdir',help='Input directory.',default='/Users/kozakai/Documents/KAGRA/DetChar/Kashiwa/20200320/GlitchPlot/')
#parser.add_argument('-o','--outputdir',help='Output directory.',default='/Users/kozakai/Documents/KAGRA/DetChar/Kashiwa/20200320/')
#parser.add_argument('-i','--inputdir',help='Input directory.',default='/mnt/GlitchPlot/')
parser.add_argument('-i','--inputdir',help='Input directory.',default='/home/chihiro.kozakai/public_html/KAGRA/test/GlitchPlot/')
#parser.add_argument('-o','--outputdir',help='Output directory.',default='/mnt/GlitchPlot/')



# define variables
args = parser.parse_args()

#date = args.date
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
            <meta http-eqiv="Pragma" content="no-cache">\n\
            <meta http-eqiv="Cache-Control" content="no-cache">\n\
            <title>KAGRA GlitchPlot</title>\n\
            <link rel=\"stylesheet\" type=\"text/css\" href=\"'+place+'style.css\">\n\
            <link rel="shortcut icon" href='+place+'GlitchPlot_minilogo.png>\n\
        </head>\n\
        \n\
        <body>\n\
            <a href='+place+'index.html target=_top>\n\
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

now = str(datetime.datetime.now())        
def WriteFooter(fname):
    '''
    Write down hooter and contact information at the bottom of the page.
    '''

    with open(fname,mode='a') as f:
        string='\
        <p style="clear: left;">\n\
        <br><hr><br>\n\
        If you have any problem, any comment or any request about this page, please contact <a href="mailto:ckozakai@icrr.u-tokyo.ac.jp">C. Kozakai</a>.\n\
        <br>\n\
        Updated at JST '+now+'.\n\
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

datelist = [os.path.basename(p.rstrip(os.sep)) for p in glob.glob(ind+"/20*/")]
datelist.sort()

with open(ftop,mode='a') as f:

    string='\
            <h3 class=h3_form>Welcome to KAGRA GlitchPlot ! </h3>\n\
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

categorywords = {"":"All","CBC":"CBC","Burst":"Burst","glitch":"Glitch","lockloss":"Lock loss"}

#for date in datelist:
latestdate=datelist[len(datelist)-1]
for i in range(len(datelist)):
    date = datelist[i]

    if not os.path.isdir(ind+date+"/html"):
        os.makedirs(ind+date+"/html")

    fdaily = ind+date+"/html/index.html"
    linkday = fdaily.replace(ind+date,"..")
    
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
        

        #fparameter = glob.glob(ind+date+"/events/"+event+"/parameter.txt")[0]
        fparameters = glob.glob(ind+date+"/events/"+event+"/parameter.txt")
        if len(fparameters) > 0:
            fparameter = fparameters[0]
            with open(fparameter,mode='r') as fp:
                parameters = fp.read().split()
                gpstime = float(parameters[0])
                cmd = "gpstime "+str(gpstime)
                info = subprocess.check_output(cmd.split())
                #info="info0 info1 info2" # dummy for environment wuthout gpstime command
                JSTglitch = info.split()[1] + " " + info.split()[2]
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
        else:
            parameters = event.split("_",2) 
            gpstime = float(parameters[1])
            cmd = "gpstime "+str(gpstime)
            info = subprocess.check_output(cmd.split())
            #info="info0 info1 info2" # dummy for environment wuthout gpstime command
            JSTglitch = info.split()[1] + " " + info.split()[2]
            snr = "-1"
            frequency = "-1"
            duration = "-1"
            pipeline = "Unknown"
            mainchannel = parameters[2]
            category = categorywords[parameters[0]]
            
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
<frameset cols="*,450">\n\
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

        with open(fform,mode='w') as ff:
#<span style="font-size:18pt; color:royalblue;"><b>Thank you very much for contributing glitch cassification !\n\
            string='\
<!DOCTYPE HTML PUBLIC >\n\
    <html>\n\
        <head>\n\
            <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n\
            <meta name="author" content="Chihiro Kozakai">\n\
            <title>KAGRA GlitchPlot</title>\n\
            <link rel=\"stylesheet\" type=\"text/css\" href=\"../../style.css\">\n\
            <link rel="shortcut icon" href=../../GlitchPlot_minilogo.png>\n\
        </head>\n\
        \n\
        <body>\n\
<h3 class=h3_form>Thank you very much for contributing glitch cassification !</h3>\n\
</br>\n\
\n\
Your reports go here: <a href="https://docs.google.com/spreadsheets/d/1JxC3QL6jF3xmA0MnWtWO_dUgNOF_i5enD_j4yUK1X7s/edit?usp=sharing" target="_blank" title="GlitchPlot Catalog" >GlitchPlot Catalog</a>\n\
\n\
</span>\n\
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
<b>1. Fill your name</b>\n\
<br>\n\
\n\
\n\
<input type="text" name="yourname" placeholder="Your name">\n\
<br><br>\n\
\n\
<b>2. Are you familiar with the latest KAGRA?</b>\n\
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
<b>3-1. Suspect the glitch origin.</b>\n\
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
<b>3-2. If you want, you can specify the sensor and location where the glitch was found.</b>\n\
<br>\n\
\n\
&emsp;Sensor :\n\
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
<br>\n\
\n\
&emsp;Location :\n\
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
<b>4. Add any suspects about the origin, comment, request, or fan letter to developpers.</b>\n\
<br>\n\
<textarea name="comment" rows="6" cols="50" placeholder="comment or fan letter"></textarea>\n\
<br><br>\n\
<input type="submit" value="Submit"/>\n\
</form>\n\
<h3 class=h3_form> Trigger channel plots</h3>\n\
'

            ff.write(string)

        fplots = ind+date+"/html/"+event+"_plots.html"
        WriteHeader(fplots, place="../../")

        with open(fplots, mode='a') as fp:

            string='\
<a href='+linkday+' target=_top>Back to trigger list</a> &ensp;&ensp;\n\
<a href=../../index.html target="_top">List of Date(all)</a> &ensp;&ensp;\n\
<br><br>\n\
<h3 class=h3_a>Triggered by '+mainchannel+' at GPS='+str(gpstime)+' &ensp; JST='+str(JSTglitch)+'</h3>'
            fp.write(string)
            
            lockfig=glob.glob(ind+date+"/events/"+event+"/*lockedsegments*")
            if len(lockfig) != 0:
                linkfig = lockfig[0].replace(ind+date,"..")
                string = '\
<a href='+linkfig+' target="_self"><img src='+linkfig+' alt='+linkfig+' title=locked width=430></a><br>'
                fp.write(string)
                with open(fform, mode='a') as ff:                
                    ff.write(string)

            mainfigs=glob.glob(ind+date+"/events/"+event+"/"+mainchannel+"*")
            for fig in mainfigs:
                if "coherence" in fig:
                    continue
                linkfig = fig.replace(ind+date,"..")
                string = '\
<a href='+linkfig+' target="_self"><img src='+linkfig+' alt='+linkfig+' title=locked width=430></a>'
                fp.write(string)
                with open(fform, mode='a') as ff:                
                    ff.write(string)
                    

            # link to suggestion.txt
            fsname=glob.glob(ind+date+"/events/"+event+"/suggestion1.txt")

                
            if len(fsname) > 0:
                linktxt = fsname[0].replace(ind+date,"..")
                with open(fform, mode='a') as ff:
                    string = '\
<br><a href='+linktxt+' target="_self">Suggestion (1) channel list</a>\n'
                    ff.write(string)

                string='\
<h3 class=h3_a>Suggested channel (1): '+mainchannel+' at GPS='+str(gpstime)+' &ensp; JST='+str(JSTglitch)+'</h3>\n'
                fp.write(string)

                f1 = open(fsname[0])
                suggestion1 = f1.read().split()
                f1.close()

                for channel in suggestion1:
                    string = '\
<br><p>'+channel+'</p><br>'
                    fp.write(string)
                    figs=glob.glob(ind+date+"/events/"+event+"/*"+channel+"*")
                    for fig in figs:
                        linkfig = fig.replace(ind+date,"..")
                        string = '\
<a href='+linkfig+' target="_self"><img src='+linkfig+' alt='+linkfig+' title='+linkfig+' width=430></a>\n'
                        fp.write(string)

                # Suggestion 2
                string='\
<h3 class=h3_a>Suggested channel (2): '+mainchannel+' at GPS='+str(gpstime)+' &ensp; JST='+str(JSTglitch)+'</h3>\n'
                fp.write(string)

                fsname=glob.glob(ind+date+"/events/"+event+"/suggestion2.txt")
                linktxt = fsname[0].replace(ind+date,"..")
                with open(fform, mode='a') as ff:
                    string = '\
<br><a href='+linktxt+' target="_self">Suggestion (2) channel list</a>\n'
                    ff.write(string)

                f2 = open(fsname[0])
                suggestion2 = f2.read().split()
                f2.close()

                for channel in suggestion2:
                    string = '\
<br><p>'+channel+'</p><br>'
                    fp.write(string)
                    figs=glob.glob(ind+date+"/events/"+event+"/*"+channel+"*")
                    for fig in figs:
                        linkfig = fig.replace(ind+date,"..")
                        string = '\
<a href='+linkfig+' target="_self"><img src='+linkfig+' alt='+linkfig+' title='+linkfig+' width=430></a>\n'
                        fp.write(string)

                # DARM affected
                string='\
<h3 class=h3_a>Channels affected by DARM DoF: '+mainchannel+' at GPS='+str(gpstime)+' &ensp; JST='+str(JSTglitch)+'</h3>\n'
                fp.write(string)

                fsname=glob.glob(ind+date+"/events/"+event+"/DARMaffected.dat")
                if len(fsname) > 0:
                    linktxt = fsname[0].replace(ind+date,"..")
                    with open(fform, mode='a') as ff:
                        string = '\
<br><a href='+linktxt+' target="_self">DARM affected channel list</a>\n'
                        ff.write(string)

                    f4 = open(fsname[0])
                    affected = f4.read().split()
                    f4.close()
                    
                    for channel in affected:
                        string = '\
<br><p>'+channel+'</p><br>'
                        fp.write(string)
                        figs=glob.glob(ind+date+"/events/"+event+"/*"+channel+"*")
                        for fig in figs:
                            linkfig = fig.replace(ind+date,"..")
                            string = '\
<a href='+linkfig+' target="_self"><img src='+linkfig+' alt='+linkfig+' title='+linkfig+' width=430></a>\n'
                            fp.write(string)

                # Not suggestion
                string='\
<h3 class=h3_a>Other auxiliary channel: '+mainchannel+' at GPS='+str(gpstime)+' &ensp; JST='+str(JSTglitch)+'</h3>\n'
                fp.write(string)

                fsname=glob.glob(ind+date+"/events/"+event+"/notsuggestion.txt")
                linktxt = fsname[0].replace(ind+date,"..")
                with open(fform, mode='a') as ff:
                    string = '\
<br><a href='+linktxt+' target="_self">Other auxiliary channel list</a>\n'
                    ff.write(string)

                f3 = open(fsname[0])
                notsuggestion = f3.read().split()
                f3.close()

                for channel in notsuggestion:
                    if channel == mainchannel:
                        continue
                    string = '\
<br><p>'+channel+'</p><br>'
                    fp.write(string)
                    figs=glob.glob(ind+date+"/events/"+event+"/*"+channel+"*")
                    for fig in figs:
                        linkfig = fig.replace(ind+date,"..")
                        string = '\
<a href='+linkfig+' target="_self"><img src='+linkfig+' alt='+linkfig+' title='+linkfig+' width=430></a>\n'
                        fp.write(string)
                
            else:
                figs=glob.glob(ind+date+"/events/"+event+"/*.png")
                for fig in figs:
                    if "coherence" in fig:
                        continue

                    linkfig = fig.replace(ind+date,"..")
                    string = '\
<a href='+linkfig+' target="_self"><img src='+linkfig+' alt='+linkfig+' title='+linkfig+' width=430></a>\n'
                    fp.write(string)
                
                figs=glob.glob(ind+date+"/events/"+event+"/*coherence*.png")
                for fig in figs:
                    linkfig = fig.replace(ind+date,"..")
                    string = '\
<a href='+linkfig+' target="_self"><img src='+linkfig+' alt='+linkfig+' title='+linkfig+' width=430></a>\n'
                    fp.write(string)



        WriteFooter(fform)
        WriteFooter(fplots)
        
    #####################################################################
    # Make eventlist for each day.
    #####################################################################

    #categorywords = {"CBC":"CBC","Burst":"Burst","glitch":"Glitch","lockloss":"Lock loss"}

    for category in categorywords.keys(): 
        fdaily = ind+date+"/html/"+category+"index.html"

        WriteHeader(fdaily,place="../../")

        # Link to other days

        with open(fdaily,mode='a') as f:

            string='\
<span style=\"font-size:16pt;\">\n'

            # if there is previous date
            if i != 0:
                prevdate = datelist[i-1]
                string+='<a href=../../'+prevdate+'/html/'+category+'index.html target=\"_self\"><< Previous day('+prevdate+')</a> &ensp;&ensp;\n'
            else:
                string+='No previous result &ensp;&ensp;\n'
            string+='<a href=../../index.html >List of Date(all)</a> &ensp;&ensp;\n\
<a href=../../'+latestdate+'/html/'+category+'index.html target=\"_self\">Latest</a> &ensp;&ensp;\n'

            # if there is next date
            if i != len(datelist)-1:
                nextdate = datelist[i+1] 
                string+='<a href=../../'+nextdate+'/html/'+category+'index.html target=\"_self\"> Next day('+nextdate+') >></a> &ensp;&ensp;\n'
            else:
                string+='No next result &ensp;&ensp;\n'

            string+='</span>\n'
            f.write(string)

            string='\
<hr><br>\n\
<span style="font-size:25pt; color:#000000;"> Event list on '+date+' JST:  '+categorywords[category]+' events</span><br>\n\
<h4>Category filter:  <a href=index.html>All</a> <a href=glitchindex.html>Glitch</a> <a href=locklossindex.html>Lock loss</a> <a href=CBCindex.html>CBC</a> <a href=Burstindex.html>Burst</a>  </h4>\n\
            <p>\n\
            Please choose interested event.\n\
            </p>\n'
            f.write(string)

            tmplist=sorted(gpstimedict.items(), key=lambda x:x[1])

            for tmp in tmplist:
                # Get main channel q-transform plot for link
                event=tmp[0]

                if category in event:

                
                    mainfig=glob.glob(ind+date+"/events/"+event+"/"+mainchanneldict[event]+"_qtransform*")
                    if len(mainfig) != 0:
                        linkfig = mainfig[0].replace(ind+date,"..")
                        string='\
                <div class="imagebox">\n\
            <a href='+event+'.html>\n\
                    <p class="image"><img src='+linkfig+' alt="Link to event page" width=400></p>\n\
                    <p class="caption">'+categorydict[event]+'<br>'+str(JSTglitchdict[event])+'</p>\n\
            </a>\n\
                </div>\n'

                    else:
                        string='\
            <a href='+event+'.html>'+event+'</a>\n'

                    f.write(string)

        
        WriteFooter(fdaily)
