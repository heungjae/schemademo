### Introduction
The following are the list of files required to refresh the Oracle schema.

#### Adding new virtual schema
To add new schemas to an existing Oracle instance, modify the entries in pre.sh and post.sh:

When Actifio mount an image to an Oracle instance, it will run thru the pre and post phase. In each phase, it will run the pre.sh and post.sh script respectively.

export SOURCE_SCHEMA_NAME=hr
export TARGET_SID=demodb
export TARGET_SCHEMA_NAME=scotty


#### Removing virtual schema

When Actifio unmount the virtual database, it will need to remove all the objects in the schema. The Actifio command will call the cleanall.sh script to drop all the objects in the virtual schema and take the tablespace offline.

The cleanall.sh will make use of the following helper scripts:
- cleandb.sh
- cleanhr.sql
- cleanup.sql


