--
-- Data model for acs-authentication
--
-- $Id$
--

\i batch-job-tables-create.sql


create table auth_action_tokens (
    user_id integer constraint auth_action_tokens_user_fk
                    references users(user_id) on delete cascade,
    purpose varchar(64) not null,
    token_digest varchar(64) not null,
    expires_at numeric(12) not null,
    token_context varchar(4000),
    constraint auth_action_tokens_pk primary key (user_id, purpose),
    constraint auth_action_tokens_digest_un unique (token_digest)
);
