#!/bin/bash 

for ff in cleanall.sh cleandb.sh cleanhr.sql cleanup.sql mountdb.sh unmountdb.sh refreshdb.sh queryhr.sql verify_db.sql query_db.sql
do
	mv $ff /home/oracle
	chown oracle:oinstall /home/oracle/$ff
done

chmod 0755 /home/oracle/*.sh
chmod 0644 /home/oracle/*.sql

for ff in pre.sh post.sh
do
	mv $ff /act/scripts  
done

chmod 0755 /act/scripts/*.sh