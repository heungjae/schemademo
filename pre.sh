#!/bin/sh

set
set -x

echo "****************** PRESK_JOBTYPE $ACT_JOBTYPE ***************"

if [ $ACT_JOBTYPE == "unmount" ] || [ $ACT_MULTI_OPNAME == "unmount" ] ; then
   if [ $ACT_PHASE == "post" ] ; then
        echo "NO-OP for post-script when unmount"
        echo "** no op exit **"
      exit
   fi
   if [ $ACT_LOGSMART_TYPE == "log" ] ; then
	echo "** no op exit **"
     exit
   fi
   if [ $ACT_PHASE == "pre" ] ; then
	echo "************************* start pre during unmount ************************"

export SOURCE_SCHEMA_NAME=hr
export TARGET_SID=demodb
export TARGET_SCHEMA_NAME=scotty

osuser=$username
ORACLE_SID=$TARGET_SID
target_dbuser=$TARGET_SCHEMA_NAME
export ORACLE_SID
ORACLE_HOME=$orahome
export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH

su $osuser -c "$ORACLE_HOME/bin/sqlplus -s / as sysdba << EOF
begin
  for rec in (select distinct TABLESPACE_NAME from dba_segments where owner = upper('$target_dbuser'))
   loop
        execute immediate 'alter tablespace '||rec.tablespace_name||' offline immediate ';
        execute immediate 'drop tablespace '||rec.tablespace_name||' INCLUDING CONTENTS and datafiles CASCADE CONSTRAINTS ';
   end loop;
end;
/
exit;
EOF
"
if [ $? -ne 0 ]; then
   echo "failed to drop tablespace"
   exit 1
fi
fi
fi

exit $?

