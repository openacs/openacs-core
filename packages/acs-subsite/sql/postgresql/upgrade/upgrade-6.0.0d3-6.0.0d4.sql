create table subsite_email_changes (
    user_id integer constraint subsite_email_changes_pk primary key
                    constraint subsite_email_changes_fk references users(user_id) on delete cascade,
    old_email varchar(100),
    new_email varchar(100) not null,
    token_digest varchar(64) not null,
    expires_at numeric(12) not null
);
