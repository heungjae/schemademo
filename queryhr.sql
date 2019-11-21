set linesize 120
col table_name format a15
SELECT table_name FROM user_tables ORDER BY table_name
/
select
   table_name,
   to_number(
   extractvalue(
      xmltype(
         dbms_xmlgen.getxml('select count(*) c from '||table_name))
    ,'/ROWSET/ROW/C')) count
from 
   user_tables
order by 
   table_name
/
exit
