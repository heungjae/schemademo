#!/bin/bash

export ORAENV_ASK=NO
export ORACLE_SID=demodb
. /u01/app/oracle/product/12.2.0/dbhome_1/bin/oraenv
export ORAENV_ASK=YES

/u01/app/oracle/product/12.2.0/dbhome_1/bin/sqlplus scotty/tiger @/home/oracle/cleanhr.sql
/u01/app/oracle/product/12.2.0/dbhome_1/bin/sqlplus / as sysdba @/home/oracle/cleanup.sql
