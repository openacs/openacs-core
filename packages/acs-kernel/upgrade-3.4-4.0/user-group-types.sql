--    file: packages/acs-kernel/upgrade-3.4-4.0/user-group-types.sql
-- history: date            email                   message
--          2000-08-01      rhs@mit.edu             initial version

set serveroutput on
set feedback off

declare
  first_p char;
begin
  dbms_output.enable(1000000);

  for ugt in (select *
              from user_group_types) loop

    -- Generate the data model for the user group type.
    dbms_output.put_line('create table ' || ugt.group_type || ' (');
    dbms_output.put(chr(9) || ugt.group_type || '_id' || chr(9) || 'primary key references organizations(org_id)');

    for ugtf in (select *
                 from user_group_type_fields
                 where group_type = ugt.group_type
		 order by sort_key) loop
      dbms_output.put(',');
      dbms_output.new_line;
      dbms_output.put(chr(9) || ugtf.column_name || chr(9) ||
                      ugtf.column_actual_type);

      if ugtf.column_extra is not null then
        dbms_output.put(' ' || ugtf.column_extra);
      end if;
    end loop;

    dbms_output.new_line;
    dbms_output.put_line(');' || chr(10));
    dbms_output.new_line;

    -- Generate the metadata insert for the organization type.
    dbms_output.put_line('insert into acs_object_types');
    dbms_output.put_line('(object_type, supertype, pretty_name, ' ||
                         'pretty_plural, table_name, id_column)');
    dbms_output.put_line('values');
    dbms_output.put_line('(''' || ugt.group_type ||
			 ''', ''organization'', ''' || ugt.pretty_name ||
			 ''', ''' || ugt.pretty_plural || ''', ''' ||
			 ugt.group_type || ''', ''' || ugt.group_type ||
			 '_id' || ''');' || chr(10));

    dbms_output.put_line('insert into organization_types');
    dbms_output.put_line('(org_type, approval_policy, ' || 
                         'default_new_member_policy)');
    dbms_output.put_line('values');
    dbms_output.put_line('(''' || ugt.group_type || ''', ''' ||
                         ugt.approval_policy || ''', ''' ||
			 ugt.default_new_member_policy || ''');' || chr(10));
  end loop;
end;
/
