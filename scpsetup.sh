#!/bin/bash 

oracle_host=10.10.10.1

for ff in cleanall.sh cleandb.sh cleanhr.sql cleanup.sql
do
	scp $ff root@$oracle_host:$ff /home/oracle
	ssh root@$oracle_host "chown oracle:oinstall /home/oracle/$ff"
	ssh root@$oracle_host "chmod 755 /home/oracle/$ff"
done

for ff in pre.sh post.sh
do
	scp $ff root@$oracle_host:$ff /act/scripts  
	ssh root@$oracle_host "chmod 755 /home/oracle/$ff"
done