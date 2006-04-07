-- Data model to support content repository of the ArsDigita Community
-- System.  This file contains DDL patches to the basic data model
-- that were incorporated after the code freeze.  It makes it easier for
-- existing users to update their data models.

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Authors:      Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

--set serveroutput on
-- FIXME: drop constraint doesn't work on postgresql
create function inline_0 ()
returns integer as '
begin
  -- altering the constraint on cr_type_template_map
  raise NOTICE ''Altering constraint on cr_type_template_map...'';
  execute ''alter table cr_type_template_map drop constraint cr_type_template_map_pk'';
  execute ''alter table cr_type_template_map add constraint cr_type_template_map_pk primary key (content_type, template_id, use_context)'';
  execute ''VACUUM ANALYZE cr_type_template_map'';

  return 0;
end;' language 'plpgsql';

-- select inline_0 ();

drop function inline_0 ();

create function inline_1 () returns integer as '
begin

  -- Set the workflow permission as child of admin
  update acs_privilege_hierarchy
    set privilege = ''cm_admin''
  where
    privilege = ''cm_write''
  and
    child_privilege = ''cm_item_workflow'';

  if not table_exists(''cr_doc_filter'') then

    raise NOTICE ''Creating CR_DOC_FILTER table for converting
                          documents to HTML'';

    execute ''create table cr_doc_filter (
      revision_id        integer primary key,
      content            integer
    )'';

   -- execute ''create index cr_doc_filter_index 
   --   on cr_doc_filter ( content ) indextype is ctxsys.context
   --   parameters (''''FILTER content_filter_pref'''' )'';

  end if;

  if not table_exists(''cr_content_text'') then

    raise NOTICE ''Creating CR_CONTENT_TEXT table'';

    execute ''create table cr_content_text (
      revision_id        integer primary key,
      content            text
    )'';

  end if;


  if not column_exists(''cr_folders'', ''has_child_folders'') then

    raise NOTICE ''Adding HAS_CHILD_FOLDERS column to CR_FOLDERS and updating the column based on selection criteria.'';

    execute ''create view cr_resolved_items as
       select
         i.parent_id, i.item_id, i.name, 
         case s.target_id is NULL then \\\'\\\'f\\\'\\\' else \\\'\\\'t\\\'\\\'  end as is_symlink,
         coalesce(s.target_id, i.item_id) resolved_id, s.label
       from
         cr_items i left outer join cr_symlinks s
       on i.item_id = s.symlink_id'';

    execute ''alter table cr_folders add
      has_child_folders boolean
			default \\\'\\\'f\\\'\\\''';

    execute ''update cr_folders f set has_child_folders =
      coalesce((select \\\'\\\'t\\\'\\\' from dual where exists
	    (select 1 from cr_folders f_child, cr_resolved_items r_child
	       where r_child.parent_id = f.folder_id
		 and f_child.folder_id = r_child.resolved_id)), \\\'\\\'f\\\'\\\')'';
  end if;



  if not column_exists(''cr_keywords'', ''parent_id'') then

    raise NOTICE ''Adding PARENT_ID column to CR_KEYWORDS and updating the parent id from the context id'';

    execute ''alter table cr_keywords add 
       parent_id      integer 
                      constraint cr_keywords_hier
                      references cr_keywords'';

    execute ''update cr_keywords set parent_id = (
                         select context_id from acs_objects 
                         where object_id = keyword_id)'';

  end if;

  if not table_exists(''cr_text'') then

    raise NOTICE ''Creating CR_TEXT table for incoming text submissions...'';

    execute ''create table cr_text ( text text default \\\'\\\' not null )'';

    -- For some reason a simple insert statement throws an error but this works
    execute ''insert into cr_text values (NULL)'';

  end if;

  if not column_exists(''cr_items'', ''publish_status'') then

    raise NOTICE ''Adding PUBLISH_STATUS column to CR_ITEMS for tracking deployment status...'';

    execute ''alter table cr_items add 
      publish_status varchar(40) 
                     constraint cr_items_pub_status_chk
                     check (publish_status in 
                       (\\\'\\\'production\\\'\\\', \\\'\\\'ready\\\'\\\', \\\'\\\'live\\\'\\\', \\\'\\\'expired\\\'\\\'))'';

    execute ''update cr_items set publish_status = \\\'\\\'live\\\'\\\'
                         where live_revision is not null'';

    execute ''alter table cr_item_publish_audit add column 
      old_status varchar(40)'';
    execute ''alter table cr_item_publish_audit add column
      new_status varchar(40)'';

  end if;

  if not column_exists(''cr_items'', ''latest_revision'') then

    raise NOTICE ''Adding LATEST_REVISION column to CR_ITEMS for tracking revision status...'';

    execute ''alter table cr_items add 
      latest_revision integer
                      constraint cr_items_latest_fk
                      references cr_revisions'';

    execute ''update cr_items 
                       set latest_revision = 
                         content_item__get_latest_revision(item_id)'';

  end if;

  if not table_exists(''cr_release_periods'') then

    raise NOTICE ''Creating CR_RELEASE_PERIODS table for scheduled publishing...'';

    execute ''
      create table cr_release_periods (
	item_id          integer
			 constraint cr_release_periods_fk
			 references cr_items
			 constraint cr_release_periods_pk
			 primary key,
	start_when	 timestamptz default current_timestamp,
	end_when	 timestamptz default current_timestamp + interval ''''20 years''''
      )'';

  end if;

  if not table_exists(''cr_scheduled_release_log'') then

    raise NOTICE ''Creating CR_SCHEDULED_RELEASE_LOG table for auditing of scheduled publishing...'';

    execute ''
      create table cr_scheduled_release_log (
	exec_date        timestamptz default current_timestamp not null,
	items_released   integer not null,
	items_expired    integer not null,
	err_num          integer,
	err_msg          varchar(500) default \\\'\\\' not null
      )'';

  end if;

  if not table_exists(''cr_scheduled_release_job'') then

    raise NOTICE ''Creating CR_SCHEDULED_RELEASE_JOB table for tracking database job for scheduled publishing...'';

    execute ''
      create table cr_scheduled_release_job (
        job_id     integer,
        last_exec  timestamptz
      )'';

    execute ''
      insert into cr_scheduled_release_job values (NULL, now())'';

  end if;

  return null;
end;' language 'plpgsql';

-- select inline_1 ();

drop function inline_1 ();

-- show errors

\i content-schedule.sql

