DECLARE

CURSOR get_pk 
IS

SELECT DISTINCT const.table_name, col.column_name, const.constraint_type, tab.data_type
FROM user_constraints const
JOIN user_cons_columns col
ON const.constraint_name = col.constraint_name
JOIN user_tab_columns tab
ON  col.column_name = tab.column_name
WHERE const.constraint_type = 'P'
AND tab.data_type = 'NUMBER'
AND const.table_name IN
                                    (SELECT OBJECT_NAME 
                                    FROM user_objects 
                                    WHERE OBJECT_TYPE ='TABLE');

CURSOR seq_check IS
SELECT sequence_name 
FROM user_sequences;


seq_name varchar2(200);
seq_max number(10);
seq_beginning varchar2 (200);
trig_name varchar2(100);


BEGIN

FOR rec IN get_pk LOOP
seq_name :=rec.table_name||'_SEQ';

seq_beginning := 'SELECT NVL(MAX( '|| rec.column_name ||'), 0)+1 FROM ' ||rec.table_name;
EXECUTE IMMEDIATE seq_beginning into seq_max;

FOR dup IN seq_check LOOP
IF dup.sequence_name = seq_name THEN
EXECUTE IMMEDIATE 'DROP SEQUENCE '|| dup.sequence_name;
END IF;
END LOOP;


EXECUTE IMMEDIATE '
CREATE SEQUENCE '||seq_name||'
START WITH '|| seq_max||'
INCREMENT BY 1';

      
trig_name := rec.table_name||'_TRIG';

EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER '||trig_name||'
BEFORE INSERT
ON '||rec.table_name ||'
FOR EACH ROW
BEGIN
'||
':new.'|| rec.column_name ||':= '||seq_name||'.nextval;
END; ';

END LOOP;
END;

show errors