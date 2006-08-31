--------Fill the index from scratch

truncate table site_wide_index;

insert into site_wide_index (object_id, object_name, datastore)
  select message_id, subject, 'a' from forums_messages;


commit;

@/web/dotlrn211/packages/search/sql/oracle/search-dirk-imconvert.sql

alter index sws_ctx_index rebuild parameters ('sync') ;

select * from sws_log_messages;
