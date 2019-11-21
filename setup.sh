#!/bin/bash 

for ff in cleanall.sh cleandb.sh cleanhr.sql cleanup.sql mountdb.sh unmountdb.sh queryhr.sql verify_db.sql
do
	mv $ff /home/oracle
	chown oracle:oinstall /home/oracle/$ff
	chmod 755 /home/oracle/$ff
done

for ff in pre.sh post.sh
do
	mv $ff /act/scripts  
	chmod 755 /home/oracle/$ff
done
