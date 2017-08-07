alter table subsite_themes add local_p char(1) default 'f'
constraint subsite_themes_local_p_ck check (local_p in ('t','f'));
