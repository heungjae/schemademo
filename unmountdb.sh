#!/bin/bash
# set -x

key_file=/home/oracle/.ssh/id_rsa

[[ `id -u` -eq 0 ]] && { echo "You must not run this script as root." ; exit 1 ; }
[[ ! -f $key_file ]] && { echo "$key_file keyfile is missing. Please load it before running script." ; exit 1 ; }

ssh -tt -p 22 -i /home/oracle/.ssh/id_rsa sybase@10.65.5.35 2>/dev/null  "$( cat <<'EOT'


label=tmpdemo
appname=DEMODB
tgthost=syd-ora12-1
appid=`udsinfo lsapplication -nohdr -delim ^ -filtervalue appname=$appname | cut -d ^ -f1`

mntImage=`reportmountedimages -c -a $appid | grep $label | cut -d"," -f1`

if [ "$mntImage" == "" ] ; then
  echo "Unable to locate any image to unmount!!"
  echo "No virtual copy of Oracle schema mounted on $tgthost "
  exit
fi

# echo " udstask unmountimage -delete -nowait -image $mntImage -script \"phase=PRE:name=act_Pre_Target_Primary.sh\" "
# jobid=`udstask unmountimage -delete -nowait -image $mntImage -script "phase=PRE:name=act_Pre_Target_Primary.sh" | cut -d " " -f1`

cmd="udstask unmountimage -delete -nowait -image $mntImage -script 'phase=PRE:name=cleanall.sh'"
echo $cmd

jobid=`eval $cmd | cut -d" " -f1`
echo $jobid


exit
EOT
)"


sleep 10

ssh -tt -p 22 -i /home/oracle/.ssh/id_rsa sybase@10.65.5.35 2>/dev/null  "$( cat <<'EOT'

label=tmpdemo
appname=DEMODB
tgthost=syd-ora12-1
appid=`udsinfo lsapplication -nohdr -delim ^ -filtervalue appname=$appname | cut -d ^ -f1`

mntImage=`reportmountedimages -c -a $appid | grep $label | cut -d"," -f1`
if [ "$mntImage" == "" ] ; then
  echo "Unable to locate any image to unmount!!"
  echo "No virtual copy of Oracle schema mounted on $tgthost "
  exit
fi

jobid=`reportrunningjobs -c -a $appid | tail -1 | cut -d"," -f2`
echo "AppID for $appname is $appid and the jobID is $jobid"


# sleep 5
prevpct=0
stat=`reportrunningjobs -c -a $appid | grep $jobid | cut -d"," -f8`
if [ "$stat" == "running" ] ; then
  while [ "running" == $stat ] ; do
    pct=`reportrunningjobs -c -a $appid | grep $jobid | cut -d"," -f10`
    if [ "$pct" != "$prevpct" ] ; then
      prevpct=$pct
#       sleep 5
      echo "Progress % : $pct ..."
    fi
    stat=`reportrunningjobs -c -a $appid | grep $jobid | cut -d"," -f8`
  done
  
fi

exit
EOT
)" 
