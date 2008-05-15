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

set serveroutput on

begin
  -- altering the constraint on cr_type_template_map
  dbms_output.put_line('Altering constraint on cr_type_template_map...');
  execute immediate 'alter table cr_type_template_map drop constraint cr_type_template_map_pk';
  execute immediate 'alter table cr_type_template_map add constraint cr_type_template_map_pk primary key (content_type, template_id, use_context)';
  execute immediate 'analyze table cr_type_template_map compute statistics for all indexes';
end;
/
show errors

begin

  -- Set the workflow permission as child of admin
  update acs_privilege_hierarchy
    set privilege = 'cm_admin'
  where
    privilege = 'cm_write'
  and
    child_privilege = 'cm_item_workflow';

  if not table_exists('cr_content_text') then

    dbms_output.put_line('Creating CR_CONTENT_TEXT table');

    execute immediate 'create global temporary table cr_content_text (
      revision_id        integer primary key,
      content            CLOB
    ) on commit delete rows';

  end if;


  if not column_exists('cr_folders', 'has_child_folders') then

    dbms_output.put_line('Adding HAS_CHILD_FOLDERS column to CR_FOLDERS' || 
      ' and updating the column based on selection criteria.');

    execute immediate 'create or replace view cr_resolved_items as
       select
         i.parent_id, i.item_id, i.name, 
         decode(s.target_id, NULL, ''f'', ''t'') is_symlink,
         nvl(s.target_id, i.item_id) resolved_id, s.label
       from
         cr_items i, cr_symlinks s
       where
         i.item_id = s.symlink_id (+)';

    execute immediate 'alter table cr_folders add
      has_child_folders char(1)
			default ''f''
			constraint cr_folder_child_chk
			check (has_child_folders in (''t'',''f''))';

    execute immediate 'update cr_folders f set has_child_folders =
      nvl((select ''t'' from dual where exists
	    (select 1 from cr_folders f_child, cr_resolved_items r_child
	       where r_child.parent_id = f.folder_id
		 and f_child.folder_id = r_child.resolved_id)), ''f'')';
  end if;



  if not column_exists('cr_keywords', 'parent_id') then

    dbms_output.put_line('Adding PARENT_ID column to CR_KEYWORDS' || 
      ' and updating the parent id from the context id');

    execute immediate 'alter table cr_keywords add 
       parent_id      integer 
                      constraint cr_keywords_hier
                      references cr_keywords';

    execute immediate 'update cr_keywords set parent_id = (
                         select context_id from acs_objects 
                         where object_id = keyword_id)';

  end if;

  if not table_exists('cr_text') then

    dbms_output.put_line('Creating CR_TEXT table ' ||
     'for incoming text submissions...');

    execute immediate 'create table cr_text ( text varchar2(4000) )';

    -- For some reason a simple insert statement throws an error but this works
    execute immediate 'insert into cr_text values (NULL)';

  end if;

  if not column_exists('cr_items', 'publish_status') then

    dbms_output.put_line('Adding PUBLISH_STATUS column to CR_ITEMS ' ||
     'for tracking deployment status...');

    execute immediate 'alter table cr_items add 
      publish_status varchar2(40) 
                     constraint cr_items_pub_status_chk
                     check (publish_status in 
                       (''production'', ''ready'', ''live'', ''expired''))';

    execute immediate 'update cr_items set publish_status = ''live''
                         where live_revision is not null';

    execute immediate 'alter table cr_item_publish_audit add
      old_status varchar2(40)';
    execute immediate 'alter table cr_item_publish_audit add
      new_status varchar2(40)';

  end if;

  if not column_exists('cr_items', 'latest_revision') then

    dbms_output.put_line('Adding LATEST_REVISION column to CR_ITEMS ' ||
     'for tracking revision status...');

    execute immediate 'alter table cr_items add 
      latest_revision integer
                      constraint cr_items_latest_fk
                      references cr_revisions';

    execute immediate 'update cr_items 
                       set latest_revision = 
                         content_item.get_latest_revision(item_id)';

  end if;

  if not table_exists('cr_release_periods') then

    dbms_output.put_line('Creating CR_RELEASE_PERIODS table ' ||
     'for scheduled publishing...');

    execute immediate '
      create table cr_release_periods (
	item_id          integer
			 constraint cr_release_periods_fk
			 references cr_items
			 constraint cr_release_periods_pk
			 primary key,
	start_when	   date default sysdate,
	end_when	   date default sysdate + (365 * 20)
      )';

  end if;

  if not table_exists('cr_scheduled_release_log') then

    dbms_output.put_line('Creating CR_SCHEDULED_RELEASE_LOG table ' ||
     'for auditing of scheduled publishing...');

    execute immediate '
      create table cr_scheduled_release_log (
	exec_date        date default sysdate not null,
	items_released   integer not null,
	items_expired    integer not null,
	err_num          integer,
	err_msg          varchar2(500)
      )';

  end if;

  if not table_exists('cr_scheduled_release_job') then

    dbms_output.put_line('Creating CR_SCHEDULED_RELEASE_JOB table ' ||
     'for tracking database job for scheduled publishing...');

    execute immediate '
      create table cr_scheduled_release_job (
        job_id     integer,
        last_exec  date
      )';

    execute immediate '
      insert into cr_scheduled_release_job values (NULL, sysdate)';

  end if;

end;
/
show errors

create or replace trigger cr_text_tr
before insert on cr_text
for each row
begin

   raise_application_error(-20000,
        'Inserts are not allowed into cr_text.'
      );
end;
/
show errors

@@ content-schedule.sql

