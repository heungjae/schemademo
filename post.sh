#!/bin/sh
set


set -x

cd /act/scripts
tmp_dump=/act/touch/db_dump

export SOURCE_SCHEMA_NAME=hr
export TARGET_SID=demodb
export TARGET_SCHEMA_NAME=scotty

osuser=$username
export osuser
TARGET_SID=$TARGET_SID
export TARGET_SID
target_dbuser=$TARGET_SCHEMA_NAME
export target_dbuser
src_dbuser=$SOURCE_SCHEMA_NAME
export src_dbuser
ORACLE_HOME=$orahome
export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH
export PATH
TNS_ADMIN=$ORACLE_HOME/network/admin
export TNS_ADMIN

echo "***************** POSTSKJOB_TYPE= $ACT_JOBTYPE *********************"

if [ $ACT_JOBTYPE == "unmount" ] || [ $ACT_MULTI_OPNAME == "unmount" ] ; then
   echo "NO-OP for post-script when unmount"
   exit 0
fi
if [ $ACT_JOBTYPE == "mount" ] || [ $ACT_MULTI_OPNAME == "mount" ] ; then
   if [ $ACT_PHASE == "pre" ] ; then
        echo "** No op for pre during unmount **"
      exit
   fi
   if [ $ACT_LOGSMART_TYPE == "log" ] ; then
        echo "** No op for log during unmount **"
     exit
   fi
   if [ $ACT_PHASE == "post" ] ; then
        echo "************************* start post during mount ************************"

ORACLE_SID=$databasesid
export ORACLE_SID

echo "************starting *************"
date


if [ -d $tmp_dump ]; then
   rm -rf $tmp_dump/*
else
   mkdir -p $tmp_dump
   chown -R oracle:dba $tmp_dump
   chmod 755 /act/touch
   chmod 755 -R $tmp_dump
fi

echo "************creating dumpdir *************"
su $osuser -c "$ORACLE_HOME/bin/sqlplus -s / as sysdba" << EOF
CREATE or REPLACE DIRECTORY dmpdir as '$tmp_dump';
GRANT read, write ON DIRECTORY dmpdir TO sys, system;
exit;
EOF

if [ $? -ne 0 ]; then
   echo "failed to create dmpdir direcotry"
   exit 1
fi

tblist=`su -m $osuser -c "$ORACLE_HOME/bin/sqlplus -S / as sysdba @/act/scripts/tablespaces.sql $src_dbuser"`
echo $tblist

if [ -z $tblist ]; then
  echo "Tablespace list is empty"
  exit 1
fi

echo "************Running TRANSPORT_SET_CHECK *************"

su $osuser -c "$ORACLE_HOME/bin/sqlplus / as sysdba @/act/scripts/transport_check.sql $tblist"

echo "************checking violations *************"

errcnt=`su $osuser -c "sqlplus -S / as sysdba " << 'EOF1'
set head off;
select count(*) from TRANSPORT_SET_VIOLATIONS;
exit;
EOF1`

if [ "$errcnt" -gt "0" ]; then
 echo "please check the violation under transport_set_violations table and correct it"
 exit 1;
fi


date

echo "************ Rename Tablespace *************"

su $osuser -c "$ORACLE_HOME/bin/sqlplus -s / as sysdba" << EOF
set head off;
begin
    for rec in (select distinct TABLESPACE_NAME from dba_segments where owner = upper('$src_dbuser'))
     loop
        execute immediate 'alter tablespace '||rec.tablespace_name||' rename to $target_dbuser'||'_'|| rec.tablespace_name;
     end loop;
end;
/
exit;
EOF
if [ $? -ne 0 ]; then
   echo "failed to rename tablespace"
   exit 1
fi


echo "************alter tablespace as read only *************"

su $osuser -c "$ORACLE_HOME/bin/sqlplus -s / as sysdba" << EOF
set head off;
begin
    for rec in (select distinct TABLESPACE_NAME from dba_segments where owner = upper('$src_dbuser'))
     loop
        execute immediate 'alter tablespace '||rec.tablespace_name||' read only';
     end loop;
end;
/
exit;
EOF
if [ $? -ne 0 ]; then
   echo "failed to make tablespace read only"
   exit 1
fi

echo "************export metadata *************"

tblist=`su -m $osuser -c "$ORACLE_HOME/bin/sqlplus -S / as sysdba @/act/scripts/tablespaces.sql $src_dbuser"`
DFILE=$SOURCE_DBUSER'_dbmetaexp.dmp'
LFILE=$SOURCE_DBUSER'_exp_ttswf.log'

su $osuser -c "expdp '\"/ as sysdba\"' DUMPFILE=$DFILE DIRECTORY=dmpdir TRANSPORT_TABLESPACES=$tblist logfile=$LFILE "

if [ $? -ne 0 ]; then
   echo "failed to export metadata. Check $tmp_dump/$LFILE"
   exit 1
fi

datafiles=`su -m $osuser -c "$ORACLE_HOME/bin/sqlplus -S / as sysdba @/act/scripts/datafiles.sql $src_dbuser"`
echo "datafiles: $datafiles"

su $osuser -c "$ORACLE_HOME/bin/sqlplus -s / as sysdba" << EOF
shutdown immediate;
exit;
EOF
if [ $? -ne 0 ]; then
   echo "failed to shutdown the database"
   exit 1
fi

ORACLE_SID=$TARGET_SID
export ORACLE_SID

su $osuser -c "$ORACLE_HOME/bin/sqlplus -s / as sysdba" << EOF
set head off;
declare
 v_user varchar2(4);
begin
 select count(1) into v_user from dba_users where username='$target_dbuser';
 if (v_user = 0)
 then
   execute immediate 'create user $target_dbuser identified by abc#1234';
 end if;
end;
/
grant connect, resource to $target_dbuser;
CREATE or REPLACE DIRECTORY actdmpdir as '$tmp_dump';
GRANT read, write ON DIRECTORY actdmpdir TO sys, system;
exit;
EOF


LFILE=$SOURCE_DBUSER'_imp_ttswf.log'

echo "************import metadata *************"
su $osuser -c "impdp '\"/ as sysdba\"' DUMPFILE=$DFILE DIRECTORY=actdmpdir TRANSPORT_DATAFILES='$datafiles' logfile=$LFILE remap_schema=$src_dbuser:$target_dbuser "

if [ $? -ne 0 ]; then
   echo "failed to import  metadata. Check $tmp_dump/$LFILE"
   exit 1
fi

su $osuser -c "$ORACLE_HOME/bin/sqlplus -s / as sysdba" << EOF
set head off;
begin
    for rec in (select distinct TABLESPACE_NAME from dba_segments where owner = upper('$target_dbuser'))
     loop
        execute immediate 'alter tablespace '||rec.tablespace_name||' read write';
     end loop;
end;
/
exit;
EOF

if [ $? -ne 0 ]; then
   echo "failed to make tablespace read write!"
   exit 1
fi
fi
fi

echo "Schema Refresh is complete..!!"
