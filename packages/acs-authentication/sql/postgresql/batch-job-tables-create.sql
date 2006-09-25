
create sequence auth_batch_jobs_job_id_seq;

create table auth_batch_jobs (
  job_id                     integer 
                             constraint auth_batch_jobs_job_id_pk
                             primary key,
  job_start_time             timestamptz default current_timestamp,
  job_end_time               timestamptz,
  interactive_p              boolean
                             constraint auth_batch_jobs_interactive_nn
                             not null,
  snapshot_p                 boolean,
  authority_id               integer
                             constraint auth_batch_jobs_auth_id_fk
                             references auth_authorities(authority_id)
                             on delete cascade,
  message                    text,
  -- if interactive, by which user
  creation_user              integer 
                             constraint auth_batch_jobs_user_fk
                             references users(user_id)
                             on delete set null,
  -- status information for the GetDocument operation
  doc_start_time             timestamptz,
  doc_end_time               timestamptz,
  doc_status                 text,
  doc_message                text,
  document                   text
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
  entry_time                 timestamptz default current_timestamp,
  operation                  varchar(100) 
                             constraint auth_batch_jobs_entries_op_ck
                             check (operation in ('insert', 'update', 'delete')),
  username                   varchar(100),
  user_id                    integer 
                             constraint auth_batch_job_entries_user_fk
                             references users(user_id) on delete set null,
  success_p                  boolean not null,
  message                    text,
  element_messages           text
);

create index auth_batch_job_ent_job_idx on auth_batch_job_entries(job_id);
create index auth_batch_job_ent_user_idx on auth_batch_job_entries(user_id);




