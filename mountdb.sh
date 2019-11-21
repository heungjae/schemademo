#!/bin/bash
#set -x

key_file=/home/oracle/.ssh/id_rsa

[[ `id -u` -eq 0 ]] && { echo "You must not run this script as root." ; exit 1 ; }
[[ ! -f $key_file ]] && { echo "$key_file keyfile is missing. Please load it before running script." ; exit 1 ; }

ssh -tt -p 22 -i /home/oracle/.ssh/id_rsa sybase@10.65.5.35 2>/dev/null  "$( cat <<'EOT'

label=tmpdemo
appname=DEMODB
tgthost=syd-ora12-1
appid=`udsinfo lsapplication -nohdr -delim ^ -filtervalue appname=$appname | cut -d ^ -f1`

image=`reportimages -c -a $appid | tail -1`
imageid=`echo $image | cut -d , -f1`

if [ "$image" == "" ] ; then
  echo "Unable to locate any image to mount!!"
  exit
fi

# mntImage=`reportmountedimages -n -a $applid | grep $oracleSID | cut -d" " -f1`
#
echo "AppID for $appname is $appid and the latest ImageID is $imageid"

# udstask backup -app $MYAPP -policy $MYPOLICY -script 'name=MYSCRIPT.sh:phase=PRE:timeout=60:args=ARG1,ARG2'
cmd="udstask mountimage -image $imageid -host $tgthost -label $label -appaware -nowait -restoreoption 'mountpointperimage=/tmpdemo,provisioningoptions=<provisioningoptions><databasesid>tmpdemo</databasesid><orahome>/u01/app/oracle/product/12.2.0/dbhome_1</orahome><tnsadmindir>/u01/app/oracle/product/12.2.0/dbhome_1/network/admin</tnsadmindir><username>oracle</username></provisioningoptions>' -script 'phase=PRE:name=pre.sh:timeout=1800;phase=POST:name=post.sh:timeout=1800'"
echo $cmd

# jobid = Job_3659703 to mount Image_3646276 started
jobid=`eval $cmd | cut -d" " -f1`
echo "Actifio JobID = $jobid"

prevpct=0
stat=`reportrunningjobs -c | grep $jobid | cut -d"," -f8`
if [ "$stat" == "running" ] ; then
  while [ "running" == $stat ] ; do
    pct=`reportrunningjobs -c | grep $jobid | cut -d"," -f10`
    if [ "$pct" != "$prevpct" ] ; then
      prevpct=$pct
      echo "Progress % : $pct ..."
    fi
    stat=`reportrunningjobs -c | grep $jobid | cut -d"," -f8`
  done
fi


exit
EOT
)"

sleep 120

ssh -tt -p 22 -i /opt/sybase/.ssh/id_rsa sybase@10.65.5.35 2>/dev/null  "$( cat <<'EOT'

appname=DEMODB
tgthost=syd-ora12-1
appid=`udsinfo lsapplication -nohdr -delim ^ -filtervalue appname=$appname | cut -d ^ -f1`
jobid=`reportmounts -c -a $appid | tail -1 | cut -d"," -f2`
echo "AppID for $appname is $appid and the jobID is $jobid"

startdt=`udsinfo lsjobhistory $jobid | grep startdate | sed 's/startdate //'`
enddt=`udsinfo lsjobhistory $jobid | grep enddate | sed 's/enddate //'`
duration=`udsinfo lsjobhistory $jobid | grep duration | sed 's/duration //'`
appszGB=`udsinfo lsjobhistory $jobid | grep -i "Application Size (GB)" | sed 's/Application size (GB) //g'`
consGB=`reportmountedimages -c -n -a $appid | cut -d "," -f13`

echo "The job started at $startdt, and ended at $enddt"
echo "It took $duration , and the actual size consumed (in GB) by the $appname application is $appszGB"

EOT
)"
