#!/bin/bash

gpstime=$1


if [ "$gpstime" = "" ]; then
    gpstime=1260822812
fi

gpsbeg=$gpstime
JST=`tconvert -l -f %Y%m%d ${gpstime}`

subgroups="GlitchPlot"
subgroup="GlitchPlot"

#dir_bKAGRA_summary_html=$HOME/bKAGRA_summary/html
#dir_bKAGRA_summary=$HOME/bKAGRA_summary
dir_bKAGRA_summary_html=$HOME/bKAGRA_summary/${JST}/html
dir_bKAGRA_summary=$HOME/bKAGRA_summary/${JST}

mkdir -p $dir_bKAGRA_summary_html

cd $dir_bKAGRA_summary
echo $dir_bKAGRA_summary
pwd



output=${dir_bKAGRA_summary_html}/${JST}_${subgroup}.html

dir_GlitchPlot_summary=summary_GlitchPlot
mkdir -p ${dir_GlitchPlot_summary}
file_GlitchPlot_summary=${dir_GlitchPlot_summary}/${JST}_summary_GlitchPlot.txt
rm $file_GlitchPlot_summary


function gene_GlitchPlot_wiki_link(){
    echo "
<span style=\"font-size:16pt;\">
<a href=\"https://docs.google.com/spreadsheets/d/1JxC3QL6jF3xmA0MnWtWO_dUgNOF_i5enD_j4yUK1X7s/edit?usp=sharing\" target=\"_blank\" title=\"GlitchPlot Catalog\" >GlitchPlot Catalog</a>
$SPACE
<a href=\"https://gwdoc.icrr.u-tokyo.ac.jp/cgi-bin/private/DocDB/ShowDocument?docid=10371\" target=\"_blank\" title=\"GlitchPlot introduction\" >GlitchPlot introduction</a>
$SPACE
<a href=\"http://gwwiki.icrr.u-tokyo.ac.jp/JGWwiki/KAGRA/Subgroups/DET/GlitchPlot\" target=\"_blank\" title=\"GlitchPlot wiki\" >GlitchPlot wiki</a>
</span>
<br><br>" >> $1

}

function gene_header(){
    echo "<!DOCTYPE HTML PUBLIC >                                                            
<html>                                                                                       
  <head>                                                                                     
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">                  
       <title>Summary page of KAGRA comissioning</title>                                     
       <link rel=\"stylesheet\" type=\"text/css\" href=\"$2style$3.css\">                    
  </head>                                                                                    
  <body>                                                                                     
                                                                                             
  <a href=\"https://www.icrr.u-tokyo.ac.jp/~yuzu/bKAGRA_summary/html/list_of_date.html\">    
   <div class=\"img_header\">                                                                
    <img src=\"https://www.icrr.u-tokyo.ac.jp/~yuzu/bKAGRA_summary/fig/header_kagra.gif\">   
   </div>                                                                                    
  </a>                                                                                       
 <br>                                                                                        
" > $1
    #  <h1 align=\"left\">Summary page of KAGRA comissioning</h1>" > $1                      
}

function gene_h2bar_output_subgroup_JST(){
    output_func=$1
    subgroup=$2
    path=$3 # ../ みたいな感じで最後に/が必要                                                
    echo "<h2>$subgroup channel $SPACE" >> $output_func
    # subgroups="GRD PSL IMC OMC VIS PEM GlitchPlot"                                         
    for i_subgroup in $subgroups
    do
        echo "<a href=\"${path}${JST}_${i_subgroup}.html\" target=\"_self\" title=\"#${i_subgroup}_${JST}\" >${i_subgroup}</a> $SPACE" >> $output_func
    done

    echo "JST : $JST</h2>" >> $output_func
}

function gene_table_header(){
    echo "<table border="1">                                                                 
<tr align=\"center\"> <td>index </td> <td>JST time</td> <td>GPS time</td>                    
<td>Interferometer</td>                                                                      
<td>max SNR</td>                                                                             
<td>frequency [Hz] @ max SNR</td>                                                            
<td>duration [s]</td>                                                                        
<td>trigger channel</td> </tr>" >> $1
}

function gene_h3bar_GlitchPlot(){
    echo "                                                                                   
<h3>                                                                                         
GlitchPlot-$2 channel $SPACE                                                                 
<a href=\"${JST}_${subgroup}.html\" target=_self title=\"${JST}_${subgroup}.html\" id=h3>all</a> $SPACE
<a href=\"${JST}_${subgroup}_lockloss.html\" target=_self title=\"${JST}_${subgroup}_lockloss.html\" id=h3 >lockloss</a> $SPACE
<a href=\"${JST}_${subgroup}_during_lock.html\" target=_self title=\"${JST}_${subgroup}_during_lock.html\" id=h3>glitch</a> $SPACE
<a href=\"${JST}_${subgroup}_not_lock.html\" target=_self title=\"${JST}_${subgroup}_not_lock.html\" id=h3>other</a> $SPACE
<a href=\"${JST}_${subgroup}_locked_cbc.html\" target=_self title=\"${JST}_${subgroup}_locked_cbc.html\" id=h3>cbc</a> $SPACE
<a href=\"${JST}_${subgroup}_locked_burst.html\" target=_self title=\"${JST}_${subgroup}_locked_burst.html\" id=h3>burst</a> $SPACE
</h3></hr>" >> $1
}

function gene_footer(){
    echo "<br><hr><br>If you have any problem, any comment and any request about this page, please contact <a href="mailto:yuzu@icrr.u-tokyo.ac.jp">yuzurihara</a>.
</body>
</html>" >> $1
}

gene_GlitchPlot_wiki_link $output


for GlitchPlot_sub in not_lock lockloss during_lock locked_cbc locked_burst
do

    # 通し番号の初期化                                                                                       
    #i_total=1; i_oplotter=1; i_lockloss=1; i_glitch=1                                                       
    i_total=1

    output_tmp=${dir_bKAGRA_summary_html}/${JST}_${subgroup}_${GlitchPlot_sub}.html
    gene_header ${output_tmp}
    #echo "<div id="${ID}"></div>" >> $output_tmp                                                            
    gene_h2bar_output_subgroup_JST $output_tmp "GlitchPlot"
    
    echo "                                                                                                   
<span style=\"font-size:16pt;\"><a href=\"${JST_PREV}_${subgroup}_${GlitchPlot_sub}.html\" target=\"_self\"><< Previous day($JST_PREV)</a>
$SPACE $SPACE
<a href=\"list_of_date.html\" target=\"_self\">List of Date(all)</a>
$SPACE $SPACE
<a href=\"latest_${subgroup}.html\" target=\"_self\">Latest</a>
$SPACE $SPACE
<a href=\"${JST_NEXT}_${subgroup}_${GlitchPlot_sub}.html\" target=\"_self\">Next day(${JST_NEXT})>></a></span>
<br>
<br>" >> $output_tmp

    gene_GlitchPlot_wiki_link $output_tmp
    
    gene_h3bar_GlitchPlot ${output_tmp} ${GlitchPlot_sub}
    
    # tableの準備                                                                                            
    gene_table_header ${output_tmp}
    
done # end of for GlitchPlot_sub in plotter lockloss glitch summary  

gene_h3bar_GlitchPlot ${output} all
gene_table_header ${output}

TODAY=${JST}

#for i in `find /home/detchar/bKAGRA_summary/html/GlitchPlot/${TODAY}/ -maxdepth 1 -type d | sort -t_ -k2 | grep "_K1"`
for i in `find GlitchPlot/${TODAY}/ -maxdepth 1 -type d | sort -t_ -k2 | grep "_K1"`
do
    echo $i
    kind_glitch=`basename $i | awk -F"_" '{print $1}'` # plotter or lockloss or glitch                               
    echo L146 kind_glitch $kind_glitch
    [[ "$kind_glitch" = "plotter" ]] && kind_glitch_cond=not_lock
    [[ "$kind_glitch" = "glitch" ]] && kind_glitch_cond=during_lock
    [[ "$kind_glitch" = "lockloss" ]] && kind_glitch_cond=lockloss
    [[ "$kind_glitch" = "CBC" ]] && kind_glitch_cond=locked_cbc
    [[ "$kind_glitch" = "Burst" ]] && kind_glitch_cond=locked_burst

    ch_glitch=`echo $i | cut -d_ -f3-`
    echo L146 ch_glitch $ch_glitch
    gps_glitch=`echo $i | awk -F"_" '{print $2}'`
    echo L146 gps_glitch $gps_glitch
    #JST_glitch=`gps2jst ${gps_glitch}`
    JST_glitch=`tconvert -l -f "%Y/%m/%d %H:%M:%S" ${gps_glitch}`
    echo ${gps_glitch} ${JST_glitch} ${ch_glitch} ${kind_glitch} ${kind_glitch_cond}

    output_tmp=${dir_bKAGRA_summary_html}/${JST}_${subgroup}_${kind_glitch_cond}.html

    # もし画像があればlistに追加する                                                                                 
    ls ${i}/*.png >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "this is empty directory."
    else

        parameter_file=$i/parameter.txt
        #echo $parameter_file                                                                                        
        [[ -f $parameter_file ]] && {
            duration=`awk '{printf "%.3f", $4}' ${parameter_file}`
            max_snr=`awk '{print int($6)}' ${parameter_file}`
            f_max_snr=`awk '{printf "%.1f", $7}' ${parameter_file}`
            pipeline=`awk '{print $11}' ${parameter_file}`
            cat ${parameter_file} >> ${file_GlitchPlot_summary}
        } || {
            duration="NA"
            max_snr="NA"
            f_max_snr="NA"
        }

        #cat $parameter_file
        # 1244646238.0 K1:IMC-CAV_TRANS_OUT_DQ 0.00049 6.0 0.05726 699.593 4.3794 0.359331 4.3794
	# [starttime in gps] [channel] [min_duration] [max_duration] [bandwidth] [maxSNR] [frequency_snr] [max_amp] [frequency_amp]                                                                                                                      
        # (4) max_duration: トリガーセグメントの長さ                                                                 
        # (6) maxSNR : このセグメント内のSNR最大値でのSNR                                                            
        # (7) frequency_snr: このセグメント内のSNR最大値の時のpeak frequency                                         
        # snrの大きさが200変わるごとに色も変わる                                                                     
        color_snr=`echo $max_snr | awk '{if($1 > 1000){printf "#FF0000)\n"}
else printf "#FF%02X%02X\n", 255-$1/1000*255, 255-$1/1000*255}'`
        echo "$max_snr $color_snr"

        # PEMのチャンネルは常にglitch扱いになる                                                                      
        [[ `echo ${ch_glitch} | grep 'PEM'` ]] && kind_glitch="PEM"
        color_interferometer=`echo $kind_glitch_cond | awk '{if($1 == "not_lock"){print "red"};
                                                             if($1 == "PEM"){print "#F6CECE"};
                                                             if($1 == "lockloss"){print "yellow"};
                                                             if($1 == "locked_cbc"){print "lightgreen"};
                                                             if($1 == "locked_burst"){print "lightgreen"};
                                                             if($1 == "during_lock"){print "lightgreen"}}'`



        # parameter.txtの値を信用しないほうがいいので、NAとして代入しておく                                          
        # いずれ消す                                                                                                 
        [[ "$kind_glitch" = "locked_cbc" ]] && {
            duration="NA"
            max_snr="NA"
            f_max_snr="NA"
        }
        # いずれ消す、終わり                                                                                         
        echo "<tr align=\"center\"> <td>${i_total}</td> <td>$JST_glitch</td> <td>${gps_glitch}</td>
<td bgcolor=\"${color_interferometer}\"><span style=\"color:black\">${kind_glitch_cond}</span></td>
<td bgcolor=\"${color_snr}\"><span style=\"color:black;\">${max_snr}</span></td>
<td>${f_max_snr}</td>
<td>${duration}</td>
<td> $SPACE <a href=\"GlitchPlot/${TODAY}/${gps_glitch}_${ch_glitch}.html\" target=\"_self\" title=\"${ch_glitch}\" >${ch_glitch}</a> $SPACE </td> </tr>" >> ${output}

	echo "<tr align=\"center\"> <td>${i_total}</td> <td>$JST_glitch</td> <td>${gps_glitch}</td>
<td bgcolor="${color_interferometer}"><span style=\"color:black\">${kind_glitch_cond}</span></td>
<td bgcolor="${color_snr}"><span style=\"color:black\">${max_snr}</span></td>
<td>${f_max_snr}</td>
<td>${duration}</td>
<td> $SPACE <a href=\"GlitchPlot/${TODAY}/${gps_glitch}_${ch_glitch}.html\" target=\"_self\" title=\"${ch_glitch}\" >${ch_glitch}</a> $SPACE </td> </tr>" >> ${output_tmp}

        # ここでページ生成の頭と終わりをやる                                                                         
        dir_html_GlitchPlot=${dir_bKAGRA_summary_html}/GlitchPlot/${TODAY}
        [[ ! -d $dir_html_GlitchPlot ]] && mkdir -p ${dir_html_GlitchPlot}
	echo L226 dir_html_GlitchPlot $dir_html_GlitchPlot
        output_each=${dir_html_GlitchPlot}/${gps_glitch}_${ch_glitch}.html
	echo L227 gps_glitch ${gps_glitch}
	echo L227 output_each $output_each 
        url_output_each="https://www.icrr.u-tokyo.ac.jp/~yuzu/bKAGRA_summary/html/GlitchPlot/${TODAY}/${gps_glitch}_${ch_glitch}.html"
        gene_header ${output_each} ../../
        gene_h2bar_output_subgroup_JST $output_each "GlitchPlot" ../../
        # javascriptで1つ前のページへのリンクを用意する、元のリストが3つあるのでこの方法を使う
        # スプレッドシートは https://docs.google.com/spreadsheets/d/1MUQmZkqjjTmztbIXy7SAOWlEXRTbd262obSkgmi59rU/edit#gid=0
        
	echo "<a href=\"javascript:history.back()\">Back to trigger list</a>
$SPACE
<a href=\"../../list_of_date.html\" target=\"_self\">List of Date(all)</a>
<br><br>
<hr>" >> ${output_each}

	echo "<span style=\"font-size:25pt; color:yellow;\">Yuzu summary needs your help to classify the glitch origin.</span>
<br>
<br>

<form id=\"form\" method=\"get\" action=\"https://script.google.com/macros/s/AKfycbx0aGq4Lgknln9psGopJm6UPW-zXkNt4LOsus8x6W2UcD2mV1Y/exec\" accept-charset=\"UTF-8\" target=\"_blank\">
<input type=\"hidden\" name=\"channelname\" value=\"${ch_glitch}\">
<input type=\"hidden\" name=\"gpsglitch\" value=\"${gps_glitch}\">
<input type=\"hidden\" name=\"JSTglitch\" value=\"${JST_glitch}\">
<input type=\"hidden\" name=\"web\" value=\"${url_output_each}\">
<input type=\"hidden\" name=\"snr\"       value=\"$max_snr\">
<input type=\"hidden\" name=\"frequency\" value=\"$f_max_snr\">
<input type=\"hidden\" name=\"duration\" value=\"$duration\">
<input type=\"hidden\" name=\"pipeline\" value=\"$pipeline \">

1. Fill your name
<br>
$SPACE
$SPACE
<input type=\"text\" name=\"yourname\" placeholder=\"Your name\">
<br><br>

2. Are you familiar with the latest KAGRA?
<br>
$SPACE
$SPACE

<input type=\"radio\" name=\"team\" value=\"Onsite\" checked>Yes (On-site researcher)
$SPACE

<input type=\"radio\" name=\"team\" value=\"Offsite\">No (Off-site researcher)
<br><br>

3-1. Suspect the glitch origin.
<br>
$SPACE
$SPACE
<select name=\"kindglitch\">
<option value=\"None\">No idea</option>
<option value=\"Accoustic\">Environment (accoustic)</option>
<option value=\"Magnetic\">Environment (magnetic)</option>
<option value=\"Seismic activity\">Environment (seismic, earthquake)</option>
<option value=\"Human activity\">Environment (Human activity in mine)</option>
<option value=\"Typhoon\">Environment (typhoon)</option>
<option value=\"Hardware injection\">Hardware injection</option>
<option value=\"Software injection\">Software injection</option>
<option value=\"Real time system\">Related to real time system</option>
<option value=\"Laser\">Related to laser(PSL, IMC)</option>
<option value=\"Unknown\">Unknown noise (write your opinion in comment)</option>
<option value=\"GravitationalWave\">Gravitational wave !!</option>
<option value=\"Other\">other (If no suitable option, select other and write comments)</option>
</select>

<br>
<br>

3-2. If you want, you can specify the sensor and location where the glitch was found.
<br>
$SPACE
$SPACE

Sensor :
<select name=\"glitchsensor\">
<option value=\"None\">No idea</option>
<option value=\"Accelerometer\">Accelerometer</option>
<option value=\"Seismometer\">Seismometer</option>
<option value=\"Microphone\">Microphone</option>
<option value=\"Magnetometer\">Magnetometer</option>
<option value=\"Oplev\">Oplev</option>
<option value=\"VIS related\">VIS related</option>
<option value=\"Control system\">Control System</option>
<option value=\"Other\">other (You can write comments below)</option>
</select>
$SPACE
$SPACE

Location :
<select name=\"glitchlocation\">
<option value=\"None\">No idea</option>
<option value=\"PSL\">PSL</option>
<option value=\"IMC\">IMC</option>
<option value=\"SR2\">SR2</option>
<option value=\"SR3\">SR3</option>
<option value=\"POP\">POP</option>
<option value=\"POS\">POS</option>
<option value=\"IMMT1\">IMMT1</option>
<option value=\"IMMT2\">IMMT2</option>
<option value=\"OMMT1\">OMMT1</option>
<option value=\"OMMT2\">OMMT2</option>
<option value=\"OMC\">OMC</option>
<option value=\"Center\">Center</option>
<option value=\"IX\">IX</option>
<option value=\"EX\">EX</option>
<option value=\"IY\">IY</option>
<option value=\"EY\">EY</option>
<option value=\"all\">all</option>
<option value=\"Control system\">Control System</option>
<option value=\"Out of mine\">Out of mine</option>
<option value=\"Other\">other (You can write comments below)</option>
</select>

<br><br>

4. Add any suspects about the origin, comment, request, or fan letter to developpers.
<br>
$SPACE
$SPACE
<textarea name=\"comment\" rows=\"6\" cols=\"80\" placeholder=\"comment or fan letter\"></textarea>
<br><br>
<input type=\"submit\" value=\"Submit\"/>
</form>

<span style=\"font-size:25pt; color:yellow;\">Thank you in advance, we really appreciate your help.
</br>

You can see the result in <a href=\"https://docs.google.com/spreadsheets/d/1JxC3QL6jF3xmA0MnWtWO_dUgNOF_i5enD_j4yUK1X7s/edit?usp=sharing\" target=\"_blank\" title=\"GlitchPlot Catalog\" >GlitchPlot Catalog</a>.

</span>
<br>
<br>
" >> ${output_each}


	echo "<h3 class=\"h3_a\">Trigger information</h3>" >> ${output_each}
        gene_table_header ${output_each}
        echo "
<tr align=\"center\"> <td>${i_total}</td>
<td>$JST_glitch</td>
<td>${gps_glitch}</td>
<td bgcolor="${color_interferometer}"><span style=\"color:black\">${kind_glitch_cond}</span></td>
<td bgcolor="${color_snr}"><span style=\"color:black\">${max_snr}</span></td>
<td>${f_max_snr}</td>
<td>${duration}</td>
<td>${SPACE} ${ch_glitch} ${SPACE}</td>
</tr>
</table>
<br>
<br>
" >> ${output_each}

	# lock状況をまとめたグラフを貼り付ける
        for i_GlitchPlot in `find ${i} -type f | grep -e "lockedsegments" | sort`
        do
            echo "<a href=\"../../../${i_GlitchPlot}\" target=\"_self\"><img src=\"../../../${i_GlitchPlot}\" alt=\"${i_GlitchPlot}\" title=\"${i_GlitchPlot}\" /></a>" >> ${output_each}
        done

        # triggered のチャンネル関連のグラフを最初に貼り付ける
        echo "<h3 class=\"h3_a\">Triggered by ${ch_glitch} at GPS=${gps_glitch} ${SPACE} JST=${JST_glitch}</h3>" >> $output_each
        # 今は timeseries, spectrogram, spectrum, whiteningspectrogram をリストアップしてる
        for i_GlitchPlot in `find ${i} -type f | grep -e "${ch_glitch}_timeseries" -e "${ch_glitch}_spectrogram" -e "${ch_glitch}_spectrum" -e "${ch_glitch}_whiteningspectrogram" -e "${ch_glitch}_qtransform" | sort`
        do
            echo "<a href=\"../../../${i_GlitchPlot}\" target=\"_self\"><img src=\"../../../${i_GlitchPlot}\" alt=\"${i_GlitchPlot}\" title=\"${i_GlitchPlot}\" /></a>" >> ${output_each}
        done
        # もしsuggestion1.txtやsuggestion2.txtがあればその内容に沿ってグラフを貼り付ける
        # suggestion1.txt, suggestion2.txt, notsuggestion.txt
        suggestion_file=$i/notsuggestion.txt
        echo $suggestion_file
        pwd
	[[ -f $suggestion_file ]] && {
            echo "There is $suggestion_file"
	    
            # suggested channel (1)
            ID=suggestion1
            echo "<div id="${ID}"></div>" >> $output_each
            echo "<h3 class=\"h3_a\">Suggested channels (1) ( ${ch_glitch} ) at GPS=${gps_glitch} ${SPACE} JST=${JST_glitch}</h3>" >> $output_each
            suggestion_file=$i/suggestion1.txt
            while read ch_suggest; do
		if [ "${ch_glitch}" = "${ch_suggest}" ]; then
		    continue
		fi
		echo "<br>
<p>${ch_suggest}</p>
<br>" >> ${output_each}
                #for i_GlitchPlot in `find ${i}/*.png -type f | grep "${ch_suggest}" | grep -v "coherence"| sort`
		for i_GlitchPlot in `find ${i}/*.png -type f | grep "${ch_suggest}" | sort`
                do
                    echo "<a href=\"../../../${i_GlitchPlot}\" target=\"_self\"><img src=\"../../../${i_GlitchPlot}\" alt=\"${i_GlitchPlot}\" title=\"${i_GlitchPlot}\" /></a>" >> ${output_each}
                done
            done < $suggestion_file

            # suggested channel (2)
            ID=suggestion2
            echo "<div id="${ID}"></div>" >> $output_each
            echo "<h3 class=\"h3_a\">Suggested channels (2) ( ${ch_glitch} ) at GPS=${gps_glitch} ${SPACE} JST=${JST_glitch}</h3>" >> $output_each
            suggestion_file=$i/suggestion2.txt
            while read ch_suggest; do
		if [ "${ch_glitch}" = "${ch_suggest}" ]; then
		    continue
		fi
		echo "<br>
<p>${ch_suggest}</p>
<br>" >> ${output_each}
                #for i_GlitchPlot in `find ${i}/*.png -type f | grep "${ch_suggest}.png" | grep -v "coherence"| sort`
		for i_GlitchPlot in `find ${i}/*.png -type f | grep "${ch_suggest}" | sort`
                do
                    echo "<a href=\"../../../${i_GlitchPlot}\" target=\"_self\"><img src=\"../../../${i_GlitchPlot}\" alt=\"${i_GlitchPlot}\" title=\"${i_GlitchPlot}\" /></a>" >> ${output_each}
                done
            done < $suggestion_file

            # not suggested channel                                                                                  
            ID=notsuggestion
            echo "<div id="${ID}"></div>" >> $output_each
            echo "<h3 class=\"h3_a\">Not suggested channels ( ${ch_glitch} ) at GPS=${gps_glitch} ${SPACE} JST=${JST_glitch}</h3>" >> $output_each
            suggestion_file=$i/notsuggestion.txt
            while read ch_suggest; do
		if [ "${ch_glitch}" = "${ch_suggest}" ]; then
		    continue
		fi
		echo "<br>
<p>${ch_suggest}</p>
<br>" >> ${output_each}

                #for i_GlitchPlot in `find ${i}/*.png -type f | grep "${ch_suggest}.png" | grep -v "coherence"| sort`
		for i_GlitchPlot in `find ${i}/*.png -type f | grep "${ch_suggest}" | sort`
                do
                    echo "<a href=\"../../../${i_GlitchPlot}\" target=\"_self\"><img src=\"../../../${i_GlitchPlot}\" alt=\"${i_GlitchPlot}\" title=\"${i_GlitchPlot}\" /></a>" >> ${output_each}
                done
            done < $suggestion_file

        } || {

	    # triggered channel以外の関連チャンネルを貼り付ける
            ID=nottriggered
            echo "<div id="${ID}"></div>" >> $output_each
            echo "<h3 class=\"h3_a\">Not trigger channel ( ${ch_glitch} ) at GPS=${gps_glitch} ${SPACE} JST=${JST_glitch}</h3>" >> $output_each
            for i_GlitchPlot in `find ${i}/*.png -type f | grep -v "^${ch_glitch}.png" | grep -v "coherence"| sort`
            do
                echo "<a href=\"../../../${i_GlitchPlot}\" target=\"_self\"><img src=\"../../../${i_GlitchPlot}\" alt=\"${i_GlitchPlot}\" title=\"${i_GlitchPlot}\" /></a>" >> ${output_each}
            done

	    
            ID=coherence
            echo "<div id="${ID}"></div>" >> $output_each
            echo "<br>
	    <h3 class=\"h3_a\">Coherence of ${ch_glitch} at GPS=${gps_glitch} ${SPACE} JST=${JST_glitch}</h3>" >> $output_each
            for i_GlitchPlot in `find ${i}/*coherence*.png -type f | sort`
            do
                echo "<a href=\"../../../${i_GlitchPlot}\" target=\"_self\"><img src=\"../../../${i_GlitchPlot}\" alt=\"${i_GlitchPlot}\" title=\"${i_GlitchPlot}\" /></a>" >> ${output_each}
            done
    
        }

        # coherenceのグラフは共通なので、ここに置く
        ID=coherence
        #echo "<div id="${ID}"></div>" >> $output_each
        #echo "<br>
#<h3 class=\"h3_a\">Coherence of ${ch_glitch} at GPS=${gps_glitch} ${SPACE} JST=${JST_glitch}</h3>" >> $output_each
        #for i_GlitchPlot in `find ${i}/*coherence*.png -type f | sort`
        #do
        #    echo "<a href=\"../../../${i_GlitchPlot}\" target=\"_self\"><img src=\"../../../${i_GlitchPlot}\" alt=\"${i_GlitchPlot}\" title=\"${i_GlitchPlot}\" /></a>" >> ${output_each}
        #done
        echo output_each $output_each

	gene_footer ${output_each}

    fi # end of if [ $? -ne 0 ]; then                                                                                
    i_total=$(( i_total + 1 ))
    
done # end of for i in `find GlitchPlot/${TODAY}/ -maxdepth 1 -type d | sort -r | grep "_K1"`

for GlitchPlot_sub in not_lock lockloss during_lock
do
    output_tmp=${dir_bKAGRA_summary_html}/${JST}_${subgroup}_${GlitchPlot_sub}.html
    echo "</table>" >> $output_tmp
    gene_footer ${output_tmp}
done #end of GlitchPlot_sub in plotter lockloss glitch                                                               
echo "</table>" >> $output

output_tmp=${dir_bKAGRA_summary_html}/${JST}_${subgroup}_summary.html
gene_header ${output_tmp}
gene_h2bar_output_subgroup_JST $output_tmp "GlitchPlot"

# ここに画像を貼る
echo "<a href=\"../summary_GlitchPlot/${JST}_summary_GlitchPlot.png\" target=\"_self\"><img src=\"../summary_GlitchPlot/${JST}_summary_GlitchPlot.png\" alt=\"${JST}_summary_GlitchPlot.png\" title=\"${JST}_summary_GlitchPlot.png\" /></a>" >> $output_tmp
gene_footer ${output_tmp}
