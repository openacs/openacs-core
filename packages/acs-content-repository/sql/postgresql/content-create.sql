-- Data model to support content repository of the ArsDigita Community
-- System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

----------------------------------
-- CMS datatypes
----------------------------------

-- create ats datatypes for cms
create function inline_0 ()
returns integer as '
begin
  insert into acs_datatypes
    (datatype, max_n_values)
  values
    (''text'', null);

  insert into acs_datatypes
    (datatype, max_n_values)
  values
    (''keyword'', 1);

  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();




--------------------------------------------------------------
-- MIME TYPES
--------------------------------------------------------------

create table cr_mime_types (
  label			varchar(200),
  mime_type	        varchar(200)
			constraint cr_mime_types_pk
			primary key,
  file_extension        varchar(200)
);


comment on table cr_mime_types is '
  Standard MIME types recognized by the content management system.
';

comment on table cr_mime_types is '
  file_extension is not used to recognize MIME types, but to associate
  a file extension to the file after its MIME type is specified.
';

-- Common mime types (administered from admin pages)

insert into cr_mime_types values ('Plain text', 'text/plain', 'txt');
insert into cr_mime_types values ('HTML text', 'text/html', 'html');
insert into cr_mime_types values ('Rich Text Format (RTF)', 'text/richtext', 'rtf');

create table cr_content_mime_type_map (
  content_type  varchar(100)
		constraint cr_content_mime_map_ctyp_fk
		references acs_object_types,
  mime_type	varchar(200)
		constraint cr_content_mime_map_typ_fk
		references cr_mime_types,
  constraint cr_content_mime_map_pk
  primary key (content_type, mime_type)
);

comment on table cr_content_mime_type_map is '
  A mapping table that restricts the MIME types associated with a 
  content type.
';



--------------------------------------------------------------
-- LOCALES
--------------------------------------------------------------

create table cr_locales (
  locale		varchar(4)
                        constraint cr_locale_abbrev_pk
                        primary key,
  label			varchar(200)
                        constraint cr_locale_name_nil
			not null
                        constraint cr_locale_name_unq
                        unique,
  nls_language		varchar(30)
                        constraint cr_locale_nls_lang_nil
			not null,
  nls_territory		varchar(30),
  nls_charset		varchar(30)
);

comment on table cr_locales is '
  Locale definitions in Oracle consist of a language, and optionally
  territory and character set.  (Languages are associated with default
  territories and character sets when not defined).  The formats
  for numbers, currency, dates, etc. are determined by the territory.
';

insert into cr_locales (
  locale, label, nls_language, nls_territory, nls_charset
) values (
  'us', 'American', 'AMERICAN', 'AMERICA', 'WE8ISO8859P1'
);

--------------------------------------------------------------
-- CONTENT TYPES
--------------------------------------------------------------

create table cr_type_children (
  parent_type   varchar(100)
		constraint cr_type_children_parent_fk
		references acs_object_types,
  child_type    varchar(100)
		constraint cr_type_children_child_fk
		references acs_object_types,
  relation_tag  varchar(100),
  min_n         integer,
  max_n         integer,
  constraint cr_type_children_pk
  primary key (parent_type, child_type, relation_tag)
);

comment on table cr_type_children is '
  Constrains the allowable content types which a content type may
  contain.
';

create table cr_type_relations (
  content_type  varchar(100)
		constraint cr_type_relations_parent_fk
		references acs_object_types,
  target_type   varchar(100)
		constraint cr_type_relations_child_fk
		references acs_object_types,
  relation_tag  varchar(100),
  min_n         integer,
  max_n         integer,
  constraint cr_type_relations_pk
  primary key (content_type, target_type, relation_tag)
);

comment on table cr_type_relations is '
  Constrains the allowable object types to which a content type may
  relate (see above).
';

--------------------------------------------------------------
-- CONTENT ITEMS
--------------------------------------------------------------

-- Define the cr_items table

create table cr_items (
  item_id	  integer 
                  constraint cr_items_item_id_fk references
		  acs_objects on delete cascade
		  constraint cr_items_pk primary key,
  parent_id	  integer 
                  constraint cr_items_parent_id_nil 
                  not null
                  constraint cr_items_parent_id_fk references
		  acs_objects on delete cascade,
  name		  varchar(400)
		  constraint cr_items_name_nil
                  not null,
  locale	  varchar(4)
		  constraint cr_items_locale_fk references
		  cr_locales,
  live_revision   integer,
  latest_revision integer,
  publish_status  varchar(40) 
                  constraint cr_items_pub_status_chk
                  check (publish_status in 
                    ('production', 'ready', 'live', 'expired')
                  ),
  content_type    varchar(100)
                  constraint cr_items_rev_type_fk
                  references acs_object_types,
  tree_sortkey    varchar(4000)
);  

create index cr_items_by_locale on cr_items(locale);
create index cr_items_by_content_type on cr_items(content_type);
create unique index cr_items_by_live_revision on cr_items(live_revision);
create unique index cr_items_by_latest_revision on cr_items(latest_revision);
create unique index cr_items_unique_name on cr_items(parent_id, name);
create unique index cr_items_unique_id on cr_items(parent_id, item_id);
create index cr_items_by_parent_id on cr_items(parent_id);


create function cr_items_tree_insert_tr () returns opaque as '
declare
        v_parent_sk     varchar;
        max_key         varchar;
begin
        if new.parent_id is null then 
            select max(tree_sortkey) into max_key 
              from cr_items 
             where parent_id is null;

            v_parent_sk := '''';
        else 
            select max(tree_sortkey) into max_key 
              from cr_items 
             where parent_id = new.parent_id;

            select coalesce(max(tree_sortkey),'''') into v_parent_sk 
              from cr_items 
             where item_id = new.parent_id;
        end if;


        new.tree_sortkey := v_parent_sk || ''/'' || tree_next_key(max_key);

        return new;

end;' language 'plpgsql';

create trigger cr_items_tree_insert_tr before insert 
on cr_items for each row 
execute procedure cr_items_tree_insert_tr ();

create function cr_items_tree_update_tr () returns opaque as '
declare
        v_parent_sk     varchar;
        max_key         varchar;
        p_id            integer;
        v_rec           record;
        clr_keys_p      boolean default ''t'';
begin
        if new.item_id = old.item_id and 
           ((new.parent_id = old.parent_id) or
            (new.parent_id is null and old.parent_id is null)) then

           return new;

        end if;

        for v_rec in select item_id
                       from cr_items 
                      where tree_sortkey like new.tree_sortkey || ''%''
                   order by tree_sortkey
        LOOP
            if clr_keys_p then
               update cr_items set tree_sortkey = null
               where tree_sortkey like new.tree_sortkey || ''%'';
               clr_keys_p := ''f'';
            end if;
            
            select parent_id into p_id
              from cr_items 
             where item_id = v_rec.item_id;

            if p_id is null then 
                select max(tree_sortkey) into max_key
                  from cr_items 
                 where parent_id is null;

                v_parent_sk := '''';
            else 
                select max(tree_sortkey) into max_key
                  from cr_items 
                 where parent_id = p_id;

                select coalesce(max(tree_sortkey),'''') into v_parent_sk 
                  from cr_items 
                 where item_id = p_id;
            end if;

            update cr_items 
               set tree_sortkey = v_parent_sk || ''/'' || tree_next_key(max_key)
             where item_id = v_rec.item_id;

        end LOOP;

        return new;

end;' language 'plpgsql';

create trigger cr_items_tree_update_tr after update 
on cr_items
for each row 
execute procedure cr_items_tree_update_tr ();

comment on table cr_items is '
  Each content item has a row in this table, as well as a row in
  the acs_objects table.  The parent_id is used to place an
  item in a directory or place it within another container item.
';

comment on column cr_items.content_type is '
  The content type constrains the type of revision that may be
  added to this item (an item should have revisions of only one type).
  If null, then no revisions should be allowed.
';

create table cr_child_rels (
  rel_id             integer
                     constraint cr_child_rels_rel_pk
                     primary key
                     constraint cr_child_rels_rel_fk
                     references acs_objects,
  parent_id          integer
                     constraint cr_child_rels_parent_nil
                     not null,
  child_id           integer
                     constraint cr_child_rels_child_nil
                     not null,
  relation_tag       varchar(100),
  order_n            integer
);

create index cr_child_rels_by_parent on cr_child_rels(parent_id);
create unique index cr_child_rels_unq_id on cr_child_rels(parent_id, child_id);

comment on table cr_child_rels is '
  Provides for richer parent-child relationships than the simple
  link encapsulated in the primary table.  May be subclassed to provide
  additional attributes.
';

create table cr_item_rels (
  rel_id             integer
                     constraint cr_item_rels_pk
                     primary key
                     constraint cr_item_rels_fk
                     references acs_objects,
  item_id            integer
                     constraint cr_item_rels_item_fk
                     references cr_items,
  related_object_id  integer
                     constraint cr_item_rels_rel_obj__fk
                     references acs_objects,
  relation_tag       varchar(100),
  order_n            integer
);

create unique index cr_item_rel_unq on cr_item_rels (
  item_id, related_object_id, relation_tag
);

comment on table cr_item_rels is '
  Describes all relations from one item to any number of other
  objects.
';

comment on column cr_item_rels.relation_tag is '
  A token for lightweight classification of item relationships.
  If additional attributes are required, then a subtype of
  item_rel may be created.
';

comment on column cr_item_rels.order_n is '
  Optional column for specifying a sort order.  Note that the ordering
  method is application-dependent (it may be by relation type or
  across multiple relation types).
';

--------------------------------------------------------------
-- CONTENT REVISIONS
--------------------------------------------------------------

-- Define the cr_revisions table

create table cr_revisions (
  revision_id     integer constraint cr_revisions_rev_id_fk references
		  acs_objects (object_id) on delete cascade
		  constraint cr_revisions_pk primary key,
  item_id         integer constraint cr_revisions_item_id_nil
                  not null
                  constraint cr_revisions_item_id_fk references
		  cr_items on delete cascade,
  title		  varchar(1000),
  description	  text,
  publish_date	  timestamp,
  mime_type	  varchar(200) default 'text/plain'
		  constraint cr_revisions_mime_type_ref
		  references cr_mime_types,
  nls_language    varchar(50),
  -- use Don's postgresql lob hack for now.
  storage_type    varchar(10) default 'lob' not null
                  constraint cr_revisions_storage_type
                  check (storage_type in ('lob','text','file')),
  -- lob_id if storage_type = lob.
  lob             integer,
  -- content holds the file name if storage type = file
  -- otherwise it holds the text data if storage_type = text.
  content	  text,
  content_length  integer
);

create trigger cr_revisions_lob_trig before delete or update or insert
on cr_revisions for each row execute procedure on_lob_ref();


create index cr_revisions_by_mime_type on cr_revisions(mime_type);
create index cr_revisions_title_idx on cr_revisions(title);
-- create index cr_revisions_lower_title_idx on cr_revisions(lower(title));
-- create index cr_revisions_title_ltr_idx on cr_revisions(substr(lower(title), 1, 1));

comment on table cr_revisions is '
  Each content item may be associated with any number of revisions.
  The item_id is used to associate revisions with an item.
';

comment on column cr_revisions.nls_language  is '
  NLS_LANGUAGE is required in the same table as the content column
  for multi-lingual searching in Intermedia.
';

alter table cr_items add constraint cr_items_live_fk 
  foreign key (live_revision) references cr_revisions(revision_id);

alter table cr_items add constraint cr_items_latest_fk 
  foreign key (latest_revision) references cr_revisions(revision_id);

create table cr_revision_attributes (
  revision_id    integer
                 constraint cr_revision_attributes_pk
                 primary key
                 constraint cr_revision_attributes_fk
                 references cr_revisions,
  attributes     text
);

comment on column cr_revision_attributes.attributes is '
  An XML document representing the compiled attributes for a revision
';


-- create global temporary table cr_content_text (
--     revision_id        integer primary key,
--     content            CLOB
-- ) on commit delete rows;

create table cr_content_text (
    revision_id        integer primary key,
    content            integer
);

comment on table cr_content_text is '
  A temporary table for holding text extracted from the content blob.
  Provides a workaround for the fact that blob_to_string(content) has
  4000 character limit.
';

--------------------------------------------------------------
-- CONTENT PUBLISHING
--------------------------------------------------------------

create table cr_item_publish_audit (
  item_id            integer
                     constraint cr_item_publish_audit_fk
                     references cr_items on delete cascade, 
  old_revision       integer
                     constraint cr_item_pub_audit_old_rev_fk
                     references cr_revisions, 
  new_revision       integer
                     constraint cr_item_pub_audit_new_rev_fk
                     references cr_revisions, 
  old_status         varchar(40),
  new_status         varchar(40),
  publish_date       timestamp
                     constraint cr_item_publish_audit_date_nil
                     not null
);

create index cr_item_publish_audit_idx on cr_item_publish_audit(item_id);

comment on table cr_item_publish_audit is '
  An audit table (populated by a trigger on cr_items.live_revision)
  that is used to keep track of the publication history of an item.
';

create table cr_release_periods (
  item_id          integer
                   constraint cr_release_periods_fk
		   references cr_items
                   constraint cr_release_periods_pk
		   primary key,
  start_when	   timestamp default now(),
  end_when	   timestamp default now() + (365 * 20)
);

create table cr_scheduled_release_log (
  exec_date        timestamp default now() not null,
  items_released   integer not null,
  items_expired    integer not null,
  err_num          integer,
  err_msg          varchar(500)
);

comment on table cr_scheduled_release_log is '
  Maintains a record, including any exceptions that may
  have aborted processing, for each scheduled update of live content.
';

create table cr_scheduled_release_job (
  job_id     integer,
  last_exec  timestamp
);

comment on table cr_scheduled_release_job is '
  One-row table to track job ID of scheduled release update.
';

insert into cr_scheduled_release_job values (NULL, now());

--------------------------------------------------------------
-- CONTENT FOLDERS
--------------------------------------------------------------

create table cr_folders (
  folder_id	    integer
		    constraint cr_folder_id_fk references
		    cr_items on delete cascade
		    constraint cr_folders_pk 
                    primary key,
  label		    varchar(1000),
  description	    text,
  has_child_folders boolean default 'f',
  has_child_symlinks boolean default 'f'
);  

comment on table cr_folders is '
  Folders are used to support a virtual file system within the content
  repository.
';


create table cr_folder_type_map (
  folder_id	integer
		constraint cr_folder_type_map_fldr_fk
		references cr_folders,
  content_type  varchar(100)
		constraint cr_folder_type_map_typ_fk
		references acs_object_types,
  constraint cr_folder_type_map_pk
  primary key (folder_id, content_type)
);

comment on table cr_folder_type_map is '
  A one-to-many mapping table of content folders to content types. 
  Basically, this table restricts the content types a folder may contain.
  Future releases will add numeric and tagged constraints similar to
  thos available for content types.  
';




--------------------------------------------------------------
-- CONTENT TEMPLATES
--------------------------------------------------------------

create table cr_templates (
  template_id	  integer
		  constraint cr_template_id_fk references
		  cr_items on delete cascade
		  constraint cr_templates_pk 
                  primary key
);

comment on table cr_templates is '
  Templates are a special class of text objects that are used for specifying
  the layout of a content item.  They may be mapped to content types for
  defaults, or may be mapped to individual content items.
';

create table cr_template_use_contexts (
  use_context	   varchar(100)
                   constraint cr_template_use_contexts_pk
                   primary key
);

comment on table cr_template_use_contexts is '
  A simple table (for now) for constraining template use contexts.
';

insert into cr_template_use_contexts values ('admin');
insert into cr_template_use_contexts values ('public');

create table cr_type_template_map (
  content_type     varchar(100)
                   constraint cr_type_template_map_typ_fk
                   references acs_object_types
                   constraint cr_type_template_map_typ_nil
                   not null,
  template_id      integer
                   constraint cr_type_template_map_tmpl_fk
	           references cr_templates,
  use_context	   varchar(100)
                   constraint cr_type_template_map_ctx_nil
                   not null
                   constraint cr_type_template_map_ctx_fk
                   references cr_template_use_contexts,
  is_default	   boolean default 'f',
  constraint cr_type_template_map_pk
    primary key (content_type, template_id, use_context)
);

create index cr_ttmap_by_content_type on cr_type_template_map(content_type);
create index cr_ttmap_by_template_id on cr_type_template_map(template_id);
create index cr_ttmap_by_use_context on cr_type_template_map(use_context);

comment on table cr_type_template_map is '
  A simple mapping template among content types and templates.
  Used to determine the default template to use in any particular
  context, as well as for building any UI that allows publishers
  to choose from a palette of templates.
';

comment on column cr_type_template_map.use_context is '
  A token to indicate the context in which a template is appropriate, 
  such as admin or public.  Should be constrained when it becomes
  clearer how this will be used.
';

create table cr_item_template_map (
  item_id          integer
                   constraint cr_item_template_map_item_fk
                   references cr_items
                   constraint cr_item_template_map_item_nil
                   not null,
  template_id      integer
                   constraint cr_item_template_map_tmpl_fk
	           references cr_templates
                   constraint cr_item_template_map_tmpl_nil
                   not null,
  use_context	   varchar(100)
                   constraint cr_item_template_map_ctx_nil
                   not null
                   constraint cr_item_template_map_ctx_fk
                   references cr_template_use_contexts,
  constraint cr_item_template_map_pk
  primary key (item_id, template_id, use_context)
);

create index cr_itmap_by_item_id on cr_item_template_map(item_id);
create index cr_itmap_by_template_id on cr_item_template_map(template_id);
create index cr_itmap_by_use_context on cr_item_template_map(use_context);

comment on table cr_item_template_map is '
  Allows a template to be assigned to a specific item.
';

--------------------------------------------------------------
-- CONTENT SYMLINKS
--------------------------------------------------------------

create table cr_symlinks (
  symlink_id	  integer
		  constraint cr_symlink_id_fk references
		  cr_items on delete cascade
		  constraint cr_symlinks_pk 
                  primary key,
  target_id       integer
                  constraint cr_symlink_target_id_fk
		  references cr_items
		  constraint cr_symlink_target_id_nil
		  not null,
  label		  varchar(1000)
);

create index cr_symlinks_by_target_id on cr_symlinks(target_id);

comment on table cr_symlinks is '
  Symlinks are pointers to items within the content repository.
';

--------------------------------------------------------------
-- CONTENT EXTLINKS
--------------------------------------------------------------

create table cr_extlinks (
  extlink_id	  integer
		  constraint cr_extlink_id_fk references
		  cr_items on delete cascade
		  constraint cr_extlinks_pk 
                  primary key,
  url             varchar(1000)
		  constraint cr_extlink_url_nil
		  not null,
  label           varchar(1000)
		  constraint cr_extlink_label_nil
		  not null,
  description	  text
);

comment on table cr_extlinks is '
  Extlinks are pointers to items anywhere on the web which the publisher wishes
  to categorize, index and relate to items in the content repository.
';

--------------------------------------------------------------
-- CONTENT KEYWORDS
--------------------------------------------------------------

create table cr_keywords (
  keyword_id		 integer
			 constraint cr_keywords_pk
		         primary key,
  parent_id              integer 
                         constraint cr_keywords_hier
                         references cr_keywords,
  heading		 varchar(600)
			 constraint cr_keywords_name_nil
			 not null,
  description            text,
  has_children           boolean,
  tree_sortkey           varchar(4000)
);


create function cr_keywords_tree_insert_tr () returns opaque as '
declare
        v_parent_sk     varchar;
        max_key         varchar;
begin
        if new.parent_id is null then 
            select max(tree_sortkey) into max_key 
              from cr_keywords 
             where parent_id is null;

            v_parent_sk := '''';
        else 
            select max(tree_sortkey) into max_key 
              from cr_keywords 
             where parent_id = new.parent_id;

            select coalesce(max(tree_sortkey),'''') into v_parent_sk 
              from cr_keywords 
             where keyword_id = new.parent_id;
        end if;


        new.tree_sortkey := v_parent_sk || ''/'' || tree_next_key(max_key);

        return new;

end;' language 'plpgsql';

create trigger cr_keywords_tree_insert_tr before insert 
on cr_keywords for each row 
execute procedure cr_keywords_tree_insert_tr ();

create function cr_keywords_tree_update_tr () returns opaque as '
declare
        v_parent_sk     varchar;
        max_key         varchar;
        p_id            integer;
        v_rec           record;
        clr_keys_p      boolean default ''t'';
begin
        if new.keyword_id = old.keyword_id and 
           new.parent_id = old.parent_id then

           return new;

        end if;

        for v_rec in select keyword_id
                       from cr_keywords 
                      where tree_sortkey like new.tree_sortkey || ''%''
                   order by tree_sortkey
        LOOP
            if clr_keys_p then
               update cr_keywords set tree_sortkey = null
               where tree_sortkey like new.tree_sortkey || ''%'';
               clr_keys_p := ''f'';
            end if;
            
            select parent_id into p_id
              from cr_keywords 
             where keyword_id = v_rec.keyword_id;

            if p_id is null then 
                select max(tree_sortkey) into max_key
                  from cr_keywords 
                 where parent_id is null;

                v_parent_sk := '''';
            else 
                select max(tree_sortkey) into max_key
                  from cr_keywords 
                 where parent_id = p_id;

                select coalesce(max(tree_sortkey),'''') into v_parent_sk 
                  from cr_keywords 
                 where keyword_id = p_id;
            end if;

            update cr_keywords 
               set tree_sortkey = v_parent_sk || ''/'' || tree_next_key(max_key)
             where keyword_id = v_rec.keyword_id;

        end LOOP;

        return new;

end;' language 'plpgsql';

create trigger cr_keywords_tree_update_tr after update 
on cr_keywords
for each row 
execute procedure cr_keywords_tree_update_tr ();

comment on table cr_keywords is '
  Stores a subject taxonomy for classifying content items, analogous
  to the system used by a library.
';

comment on column cr_keywords.heading is '
  A subject heading.  This will become a message ID in the next
  release so it should never be referenced directly (only through
  the API)
';

comment on column cr_keywords.description is '
  Description of a subject heading.  This will be a message ID in the next
  release so it should never be referenced directly (only through
  the API)
';

create table cr_item_keyword_map (
  item_id          integer
                   constraint cr_item_keyword_map_item_fk
                   references cr_items
                   constraint cr_item_keyword_map_item_nil
                   not null,
  keyword_id       integer
                   constraint cr_item_keyword_map_kw_fk
	           references cr_keywords
                   constraint cr_item_keyword_map_kw_nil
                   not null,
  constraint cr_item_keyword_map_pk
  primary key (item_id, keyword_id)
);


--------------------------------------------------------------
-- TEXT SUBMISSION
--------------------------------------------------------------

create table cr_text (
  text_data  text
);

comment on table cr_text is '
  A simple placeholder table for generating input views, so that a
  complete revision may be added with a single INSERT statement.
';

insert into cr_text values (NULL);

create function cr_text_tr () returns opaque as '
begin

   raise EXCEPTION ''-20000: Inserts are not allowed into cr_text.'';

   return new;

end;' language 'plpgsql';

create trigger cr_text_tr before insert on cr_text
for each row execute procedure cr_text_tr ();

-- show errors



--------------------------------------------------------------
-- DOCUMENT SUBMISSION WITH CONVERSION TO HTML
--------------------------------------------------------------
-- create global temporary table cr_doc_filter (
--    revision_id        integer primary key,
--    content            BLOB
--) on commit delete rows;

create table cr_doc_filter (
    revision_id        integer primary key,
    -- content            BLOB
    -- need a blob trigger here
    content            integer
);


-- Source PL/SQL Definitions.

\i content-util.sql
\i content-xml.sql

-- prompt *** Creating packaged call specs for Java utility methods...
\i content-package.sql

-- prompt *** Defining and compiling packages...
\i packages-create.sql

-- prompt *** Creating object types...
\i types-create.sql

-- DC@: oracle-specific code that can't be directly ported to postgresql.
-- prompt *** Preparing search indices...
-- \i content-search.sql

-- this index requires prefs created in content-search
-- create index cr_doc_filter_index on cr_doc_filter ( content )
--  indextype is ctxsys.context
--  parameters ('FILTER content_filter_pref' );

comment on table cr_doc_filter is '
  A temporary table for holding binary documents that are to be converted
  into HTML (or plain text) prior to insertion into the repository.
';



-- prompt *** Compiling documentation package...
\i doc-package.sql

-- prompt *** Creating image content type...
\i content-image.sql

-- by default, map all MIME types to 'content_revision'

create function inline_1 ()
returns integer as '
declare
  v_id integer;
begin

  PERFORM content_type__register_mime_type(''content_revision'', 
                                           ''text/html'');
  PERFORM content_type__register_mime_type(''content_revision'', 
                                           ''text/plain'');

  v_id := content_folder__new (
    ''pages'',
    ''Pages'', 
    ''Site pages go here'',
    0,
    null,
    content_item__get_root_folder(null),
    now(),
    null,
    null
  );

  PERFORM content_folder__register_content_type(
    v_id,
    ''content_revision'',
    ''t''
  );

  PERFORM content_folder__register_content_type(
    v_id,
    ''content_folder'',
    ''t''
  );

  PERFORM content_folder__register_content_type(
    v_id,
    ''content_symlink'',
    ''t''
  );

  v_id := content_folder__new (
    ''templates'',
    ''Templates'', 
    ''Templates which render the pages go here'',
    0,
    null,
    content_template__get_root_folder(),
    now(),
    null,
    null
  );

  PERFORM content_folder__register_content_type(
    v_id,
    ''content_folder'',
    ''t''
  );

  PERFORM content_folder__register_content_type(
    v_id,
    ''content_symlink'',
    ''t''
  );

  PERFORM content_folder__register_content_type(
    v_id,
    ''content_template'',
    ''t''
  );

  return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();


-- show errors



