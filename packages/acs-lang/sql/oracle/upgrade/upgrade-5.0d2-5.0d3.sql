alter table lang_messages add creation_date      date default sysdate not null;
alter table lang_messages add     creation_user      integer
                                  constraint lang_messages_create_u_fk
                                  references users (user_id);
