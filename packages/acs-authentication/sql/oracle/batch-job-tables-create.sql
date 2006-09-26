create sequence auth_batch_jobs_job_id_seq;

create table auth_batch_jobs (
  job_id                     integer 
                             constraint auth_batch_jobs_job_id_pk
                             primary key,
  job_start_time             date default sysdate,
  job_end_time               date,
  interactive_p              char(1)
                             constraint auth_batch_jobs_interactive_ck 
                             check (interactive_p in ('t', 'f'))
                             constraint auth_batch_jobs_interactive_nn
                             not null,
  snapshot_p                 char(1)
                             constraint auth_batch_jobs_snapshot_ck 
                             check (snapshot_p in ('t', 'f')),
  authority_id               integer
                             constraint auth_batch_jobs_auth_fk
                             references auth_authorities(authority_id)
                             on delete cascade,
  message                    varchar2(4000),
  -- if interactive, by which user
  creation_user              integer 
                             constraint auth_batch_job_user_fk
                             references users(user_id)
                             on delete set null,
  -- status information for the GetDocument operation
  doc_start_time             date,
  doc_end_time               date,
  doc_status                 varchar2(4000),
  doc_message                varchar2(4000),
  document                   clob
);

create index auth_batch_jobs_user_idx on auth_batch_jobs(creation_user);
create index auth_batch_jobs_auth_idx on auth_batch_jobs(authority_id);


create sequence auth_batch_job_entry_id_seq;

create table auth_batch_job_entries (
  entry_id                   integer   
                             constraint auth_batch_job_entries_pk 
                             primary key,
  job_id                     integer 
                             constraint auth_batch_job_entries_job_fk
                             references auth_batch_jobs(job_id)
                             on delete cascade,
  entry_time                 date default sysdate,
  operation                  varchar(100)
                             constraint auth_batch_jobs_entries_op_ck
                             check (operation in ('insert', 'update', 'delete')),
  username                   varchar(100),
  user_id                    integer 
                             constraint auth_batch_job_entries_user_fk
                             references users(user_id) on delete set null,
  success_p                  char(1)
                             constraint auth_batch_jobs_ent_success_ck
                             check (success_p in ('t', 'f'))
                             constraint auth_batch_jobs_ent_success_nn
                             not null,
  message                    varchar2(4000),
  element_messages           clob
);

create index auth_batch_job_ent_job_idx on auth_batch_job_entries(job_id);
create index auth_batch_job_ent_user_idx on auth_batch_job_entries(user_id);




