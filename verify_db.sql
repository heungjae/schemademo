set pagesize 100
set linesize 180
set echo off
set feedback off
set wrap on
col tablespace_name format a15
col status format a15
col file_name format a95
col host_name format a25
col startuptime head "STARTUP TIME" format a25
col scn_tstamp head "SCN TIMESTAMP" format a45
col instance_number head INST# format 99
col owner format a25
col cnt head "# TABLES" format 99999
select distinct tablespace_name, file_name from dba_data_files order by 1;
select tablespace_name, status from dba_tablespaces;
select owner,count(*) cnt from dba_tables group by owner order by 1;
select dbid, name, open_mode from v$database;
select SCN_to_timestamp(current_scn) scn_tstamp, current_scn from V$database;
select sum(bytes)/(1024*1024*1024) "DB size (GB)" from dba_data_files;
select instance_number, instance_name, host_name, version, TO_CHAR(startup_time,'DD-MON-YYYY HH24:MI:SS') startuptime, status, logins, database_status, instance_role, edition, database_type from v$instance;
exit
