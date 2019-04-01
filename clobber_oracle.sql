set pages 0

spool dropper.sql
select case when object_type = 'TABLE' then 'drop table "'|| object_name ||'" cascade constraints;'
            when object_type = 'VIEW' then 'drop view "'|| object_name ||'";'
            when object_type = 'PROCEDURE' then 'drop procedure "'|| object_name ||'";'
            when object_type = 'SEQUENCE' then 'drop sequence "'|| object_name ||'";'
       end
from user_objects
order by 1 desc
/

select 'purge user_recyclebin;' from dual
/

spool off
@dropper
