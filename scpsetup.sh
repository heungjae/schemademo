#!/bin/bash 

oracle_host=syd-ora12-2

for ff in cleanall.sh cleandb.sh cleanhr.sql cleanup.sql mountdb.sh unmountdb.sh queryhr.sql verify_db.sql
do
	scp $ff root@$oracle_host:/home/oracle
	ssh root@$oracle_host "chown oracle:oinstall /home/oracle/$ff"
done

ssh root@$oracle_host "chmod 0755 /home/oracle/*.sh"
ssh root@$oracle_host "chmod 0644 /home/oracle/*.sql"

for ff in pre.sh post.sh
do
	scp $ff root@$oracle_host:/act/scripts  
done

ssh root@$oracle_host "chmod 0755 /act/scripts/*.sh"