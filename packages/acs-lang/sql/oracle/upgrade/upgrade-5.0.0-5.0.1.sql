-- @author Peter Marklund
-- Change the lang_messages_audit table to have a new integer primary key column
create sequence lang_messages_audit_id_seq;

alter table lang_messages_audit add audit_id integer;

alter table lang_messages_audit drop constraint lang_messages_audit_pk;

begin
     for one_row in (select message_key,
                            package_key,
                            locale,
                            overwrite_date
                     from lang_messages_audit
                     order by overwrite_date
                    )
     loop       
       update lang_messages_audit set audit_id = lang_messages_audit_id_seq.nextval
        where message_key = one_row.message_key
          and package_key = one_row.package_key
          and locale = one_row.locale
          and overwrite_date = one_row.overwrite_date;
     end loop;
end;
/
show errors

alter table lang_messages_audit 
        add constraint lang_messages_audit_pk primary key (audit_id);
