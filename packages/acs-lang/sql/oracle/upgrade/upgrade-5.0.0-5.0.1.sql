-- @author Peter Marklund
-- Change the lang_messages_audit table to have a new integer primary key column
create sequence lang_messages_audit_id_seq;

rename lang_messages_audit to lang_messages_audit_bak;

alter table lang_messages_audit_bak drop constraint lang_messages_audit_key_nn;
alter table lang_messages_audit_bak drop constraint lang_messages_audit_p_key_nn;
alter table lang_messages_audit_bak drop constraint lang_messages_audit_l_fk;
alter table lang_messages_audit_bak drop constraint lang_messages_audit_l_nn;
alter table lang_messages_audit_bak drop constraint lang_messages_audit_dp_ck;
alter table lang_messages_audit_bak drop constraint lang_messages_audit_cp_ck;
alter table lang_messages_audit_bak drop constraint lang_messages_audit_us_ck;
alter table lang_messages_audit_bak drop constraint lang_messages_audit_ou_fk;
alter table lang_messages_audit_bak drop constraint lang_messages_audit_fk;
alter table lang_messages_audit_bak drop constraint lang_messages_audit_pk;

create table lang_messages_audit (
    audit_id           integer
                       constraint lang_messages_audit_pk
                       primary key,    
    message_key        varchar2(200)
                       constraint lang_messages_audit_key_nn
                       not null,
    package_key        varchar2(100)
                       constraint lang_messages_audit_p_key_nn
                       not null,
    locale             varchar2(30) 
                       constraint lang_messages_audit_l_fk
                       references ad_locales(locale)
                       constraint lang_messages_audit_l_nn
                       not null,
    old_message        clob,
    deleted_p          char(1) default 'f'
                       constraint lang_messages_audit_dp_ck check (deleted_p in ('t','f')),
    sync_time          date,
    conflict_p         char(1) default 'f'
                       constraint lang_messages_audit_cp_ck check (conflict_p in ('t','f')),
    upgrade_status     varchar2(30)
                       constraint lang_messages_audit_us_ck
                       check (upgrade_status in ('no_upgrade', 'added', 'deleted', 'updated')),
    comment_text       clob,
    overwrite_date     date default sysdate not null,
    overwrite_user     integer
                       constraint lang_messages_audit_ou_fk
                       references users (user_id),
    constraint lang_messages_audit_fk
    foreign key (message_key, package_key) 
    references lang_message_keys(message_key, package_key)
    on delete cascade
);

begin
     for old_row in (select *
                     from lang_messages_audit
                     order by overwrite_date
                    )
     loop
       insert into lang_messages_audit
          (audit_id, message_key, package_key, locale, old_message, deleted_p, sync_time, conflict_p, upgrade_status,
           comment_text, overwrite_date, overwrite_user)
       values 
          (lang_messages_audit_id_seq.nextval, old_row.message_key, old_row.package_key, old_row.locale, 
           old_row.old_message, old_row.deleted_p, old_row.sync_time, old_row.conflict_p, old_row.upgrade_status,
           old_row.comment_text, old_row.overwrite_date, old_row.overwrite_user);
     end loop;
end;
/
show errors

drop table lang_messages_audit_bak;
