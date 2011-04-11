-- Uninstall content repository tables of the ArsDigita Community
-- System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- set serveroutput on

-- unregistering types, deleting the default folders
create function inline_0 () returns integer as '
declare
  v_id integer;
begin

  -- root folder for templates
  v_id := content_template__get_root_folder();

  PERFORM content_folder__unregister_content_type(
    v_id,
    ''content_template'',
    ''t''
    );

  PERFORM content_folder__unregister_content_type(
    v_id,
    ''content_symlink'',
    ''t''
  );

  PERFORM content_folder__unregister_content_type(
    v_id,
    ''content_folder'',
    ''t''
  );

  PERFORM content_folder__delete(v_id);
    

  -- the root folder for content items	
  v_id := content_item__get_root_folder(null);

  PERFORM content_folder__unregister_content_type(
    v_id,
    ''content_symlink'',
    ''t''
  );

  PERFORM content_folder__unregister_content_type(
    v_id,
    ''content_folder'',
    ''t''
  );

  PERFORM content_folder__unregister_content_type (
    v_id,
    ''content_revision'',
    ''t''
  );	 

  PERFORM content_folder__delete (v_id);

  return null;

end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();



begin;
  select content_type__unregister_mime_type('content_revision', 'text/html');
  select content_type__unregister_mime_type('content_revision', 'text/plain');
end;


-- drop all extended attribute tables

--declare
--  cursor type_cur is
--    select object_type, table_name 
--    from acs_object_types 
--    where table_name <> 'cr_revisions'
--    connect by prior object_type =  supertype 
--    start with object_type = 'content_revision' 
--    order by level desc;
--begin
  
--  for type_rec in type_cur loop
--    dbms_output.put_line('Dropping ' || type_rec.table_name);
--    execute immediate 'drop table ' || type_rec.table_name;
--  end loop;

--end;
--/
--show errors


-- dropping pl/sql definitions
--prompt ** dropping content-image 
\i content-image-drop.sql

-- doc-package-drop

-- content-search-drop
-- begin
--  ctx_ddl.drop_section_group('auto');
--end;

select acs_sc_impl__delete(
	   'FtsContentProvider',		-- impl_contract_name
           'acs-content-repository'             -- impl_name
);

drop trigger content_search__utrg on cr_revisions;
drop trigger content_search__dtrg on cr_revisions;
drop trigger content_search__itrg on cr_revisions;

drop function content_search__utrg ();
drop function content_search__dtrg ();
drop function content_search__itrg ();



--begin
--  ctx_ddl.drop_preference('CONTENT_FILTER_PREF');
--end;


-- prompt ** dropping object types
\i types-drop.sql

-- packages-drop


-- content-package-drop

-- prompt ** dropping lots of tables
-- content-xml-drop
drop table cr_xml_docs;
drop sequence cr_xml_doc_seq;

-- content-util drop

-- document submission with conversion to html
drop index cr_doc_filter_index;
drop table cr_doc_filter;


--text submission
drop table cr_text;

-- content keywords
drop table cr_item_keyword_map ;
drop table cr_keywords ;

-- content extlinks
drop table cr_extlinks ;

-- content symlinks
drop table cr_symlinks ;

-- content templates
drop table cr_item_template_map ;
drop table cr_type_template_map ;
drop table cr_template_use_contexts ;
drop table cr_templates ;

-- content folders
drop table cr_folder_type_map ;
drop table cr_folders cascade constraints;


-- prompt ** dropping more tables
-- content publishing
drop table cr_scheduled_release_job;
drop table cr_scheduled_release_log;
drop table cr_release_periods;
drop table cr_item_publish_audit;

-- content revisions
drop table cr_files_to_delete;
drop table cr_content_text;
drop table cr_revision_attributes;
drop table cr_revisions cascade constraints;

-- content_items
drop table cr_item_rels ;
drop table cr_child_rels ;
drop table cr_items cascade constraints;

-- content types
drop table cr_type_relations ;
drop table cr_type_children ;

-- locales
drop table cr_locales ;

-- mime types
drop table cr_content_mime_type_map ;
drop table cr_mime_types ;


