-- @author Peter Marklund
-- Change the lang_messages_audit table to have a new integer primary key column
create sequence lang_messages_audit_id_seq;

alter table lang_messages_audit add column audit_id integer;

alter table lang_messages_audit drop constraint lang_messages_audit_pk;

create function inline_0()
returns integer as '
declare
  v_rec           record;
  v_next_id       integer;
begin

  for v_rec in select message_key,
                       package_key,
                       locale,
                       overwrite_date
                from lang_messages_audit
                order by overwrite_date 
  loop

        select nextval(''lang_messages_audit_id_seq''::text) into v_next_id;

        update lang_messages_audit set audit_id = v_next_id
        where message_key = v_rec.message_key
          and package_key = v_rec.package_key
          and locale = v_rec.locale
          and overwrite_date = v_rec.overwrite_date;
  end loop;

  return 0;

end;' language 'plpgsql';
select inline_0();
drop function inline_0();

alter table lang_messages_audit
        alter column audit_id set not null;
alter table lang_messages_audit 
        add constraint lang_messages_audit_pk primary key (audit_id);
