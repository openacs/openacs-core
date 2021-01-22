-- Data model to support content repository of the ArsDigita Community
-- System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html


--------------------------------------------------------------
-- MIME TYPES
--------------------------------------------------------------
-- Mime data for the following table is in mime-type-data.sql

create table cr_mime_types (
  label			varchar(200),
  mime_type	        varchar(200)
			constraint cr_mime_types_mime_type_pk
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

-- Currently file_extension is the pk although it seems likely someone
-- will want to support multiple mime types with the same extension.
-- Would need UI work however

create table cr_extension_mime_type_map (
   extension            varchar(200) 
                        constraint cr_extension_mime_type_map_pk
                        primary key,
   mime_type            varchar(200) 
                        constraint cr_mime_ext_map_mime_type_fk
                        references cr_mime_types
); 
create index cr_extension_mime_type_map_idx on cr_extension_mime_type_map(mime_type);

comment on table cr_extension_mime_type_map is '
  a mapping table for extension to mime_type in db version of ns_guesstype data
';

-- Load the mime type data.
\i ../common/mime-type-data.sql

create table cr_content_mime_type_map (
  content_type  varchar(1000)
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

-- RI Index 
-- fairly static, could probably omit this one.
create index cr_cont_mimetypmap_mimetyp_idx ON cr_content_mime_type_map(mime_type);

--------------------------------------------------------------
-- LOCALES
--------------------------------------------------------------

create table cr_locales (
  locale		varchar(4)
                        constraint cr_locales_locale_pk
                        primary key,
  label			varchar(200)
                        constraint cr_locales_label_nn
			not null
                        constraint cr_locales_label_un
                        unique,
  nls_language		varchar(30)
                        constraint cr_locale_nls_language_nn
			not null,
  nls_territory		varchar(30),
  nls_charset		varchar(30)
);

comment on table cr_locales is '
  Locale definitions in Oracle consist of a language, and optionally
  territory and character set.  (Languages are associated with default
  territories and character sets when not defined).  The formats
  for numbers, currency, dates, etc. are determined by the territory.

  The cr_locales table is deprecated for OpenACS 5.2, and will be removed in OpenACS 6 (TIP #66)
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
  parent_type   varchar(1000)
		constraint cr_type_children_parent_type_fk
		references acs_object_types,
  child_type    varchar(1000)
		constraint cr_type_children_child_type_fk
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

-- RI Indexes
create index cr_type_children_chld_type_idx ON cr_type_children(child_type);


create table cr_type_relations (
  content_type  varchar(1000)
		constraint cr_type_relations_parent_fk
		references acs_object_types,
  target_type   varchar(1000)
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

-- RI Indexes 
create index cr_type_relations_tgt_typ_idx ON cr_type_relations(target_type);


--------------------------------------------------------------
-- CONTENT ITEMS
--------------------------------------------------------------
CREATE TYPE cr_item_storage_type_enum AS ENUM ('text', 'file', 'lob');

-- Define the cr_items table

create table cr_items (
  item_id             integer 
                      constraint cr_items_item_id_fk references
                      acs_objects on delete cascade
                      constraint cr_items_item_id_pk primary key,
  parent_id           integer 
                      constraint cr_items_parent_id_nn 
                      not null
                      constraint cr_items_parent_id_fk references
                      acs_objects on delete cascade,
  name                varchar(400)
                      constraint cr_items_name_nn
                      not null,
  locale              varchar(4)
                      constraint cr_items_locale_fk references
                      cr_locales,
  live_revision       integer,
  latest_revision     integer,
  publish_status      varchar(40) 
                      constraint cr_items_publish_status_ck
                      check (publish_status in 
                            ('production', 'ready', 'live', 'expired')
                            ),
  content_type        varchar(1000)
                      constraint cr_items_content_type_fk
                      references acs_object_types,
  storage_type        cr_item_storage_type_enum default 'text' not null,
  storage_area_key    varchar(100) default 'CR_FILES' not null,
  tree_sortkey        varbit not null,
  max_child_sortkey   varbit
);  

create index cr_items_by_locale on cr_items(locale);
create index cr_items_by_content_type on cr_items(content_type);
create unique index cr_items_by_live_revision on cr_items(live_revision);
create unique index cr_items_by_latest_revision on cr_items(latest_revision);
create unique index cr_items_unique_name on cr_items(parent_id, name);
create unique index cr_items_unique_id on cr_items(parent_id, item_id);
create index cr_items_by_parent_id on cr_items(parent_id);
create index cr_items_name on cr_items(name);
create unique index cr_items_tree_sortkey_un on cr_items(tree_sortkey);

-- content-create.sql patch
--
-- adds standard mechanism for deleting revisions from the file-system
--
-- Walter McGinnis (wtem@olywa.net), 2001-09-23
-- based on original photo-album package code by Tom Baginski
--

create table cr_files_to_delete (
  path                  varchar(250),
  storage_area_key      varchar(100)
);

comment on table cr_files_to_delete is '
  Table to store files to be deleted by a scheduled sweep.
  Since binaries are stored in filesystem and attributes in database,
  need a way to delete both atomically.  So any process to delete file-system cr_revisions,
  copies the file path to this table as part of the delete transaction.  Sweep
  run later to remove the files from filesystem once database info is successfully deleted.
';


-- DCW, this can't be defined in the apm_package_versions table definition,
-- because cr_items is created afterwards.

alter table apm_package_versions add
  constraint apm_package_ver_item_id_fk
  foreign key (item_id) references cr_items(item_id);




-- added
select define_function_args('cr_items_get_tree_sortkey','item_id');

--
-- procedure cr_items_get_tree_sortkey/1
--
CREATE OR REPLACE FUNCTION cr_items_get_tree_sortkey(
   p_item_id integer
) RETURNS varbit AS $$
DECLARE
BEGIN
  return tree_sortkey from cr_items where item_id = p_item_id;
END;
$$ LANGUAGE plpgsql stable strict;



--
-- procedure cr_items_tree_insert_tr/0
--
CREATE OR REPLACE FUNCTION cr_items_tree_insert_tr(

) RETURNS trigger AS $$
DECLARE
    v_parent_sk      	varbit default null;
    v_max_child_sortkey varbit;
    v_parent_id      	integer default null;
BEGIN
    select item_id
    into   v_parent_id
    from   cr_items
    where  item_id = new.parent_id;

    if new.parent_id = 0 then
	
	new.tree_sortkey := int_to_tree_key(new.item_id+1000);

    elsif v_parent_id is null then 

	new.tree_sortkey := int_to_tree_key(new.parent_id+1000) || int_to_tree_key(new.item_id+1000);

    else

	SELECT tree_sortkey, tree_increment_key(max_child_sortkey)
	INTO v_parent_sk, v_max_child_sortkey
	FROM cr_items
	WHERE item_id = new.parent_id 
	FOR UPDATE;

	UPDATE cr_items
	SET max_child_sortkey = v_max_child_sortkey
	WHERE item_id = new.parent_id;

	new.tree_sortkey := v_parent_sk || v_max_child_sortkey;

    end if;

    return new;
END;
$$ LANGUAGE plpgsql;

create trigger cr_items_tree_insert_tr before insert 
on cr_items for each row 
execute procedure cr_items_tree_insert_tr ();



--
-- procedure cr_items_tree_update_tr/0
--
CREATE OR REPLACE FUNCTION cr_items_tree_update_tr(

) RETURNS trigger AS $$
DECLARE
        v_parent_sk     	varbit default null;
        v_max_child_sortkey     varbit;
        v_parent_id            	integer default null;
        v_old_parent_length	integer;
BEGIN
        if new.item_id = old.item_id and 
           ((new.parent_id = old.parent_id) or
            (new.parent_id is null and old.parent_id is null)) then

           return new;

        end if;

        select item_id
    	into   v_parent_id
	from   cr_items
	where  item_id = new.parent_id;

	-- the tree sortkey is going to change so get the new one and update it and all its
	-- children to have the new prefix...
	v_old_parent_length := length(new.tree_sortkey) + 1;

        if new.parent_id = 0 then
            v_parent_sk := int_to_tree_key(new.item_id+1000);
	elsif v_parent_id is null then 
            v_parent_sk := int_to_tree_key(new.parent_id+1000) || int_to_tree_key(new.item_id+1000);
        else
	    SELECT tree_sortkey, tree_increment_key(max_child_sortkey)
	    INTO v_parent_sk, v_max_child_sortkey
	    FROM cr_items
	    WHERE item_id = new.parent_id 
	    FOR UPDATE;

	    UPDATE cr_items
	    SET max_child_sortkey = v_max_child_sortkey
	    WHERE item_id = new.parent_id;

	    v_parent_sk := v_parent_sk || v_max_child_sortkey;
        end if;

	UPDATE cr_items
	SET tree_sortkey = v_parent_sk || substring(tree_sortkey, v_old_parent_length)
	WHERE tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);

        return new;

END;
$$ LANGUAGE plpgsql;

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
                     constraint cr_child_rels_rel_id_pk
                     primary key
                     constraint cr_child_rels_rel_id_fk
                     references acs_objects,
  parent_id          integer
                     constraint cr_child_rels_parent_id_nn
                     not null
		     CONSTRAINT cr_child_rels_parent_id_fk
                     REFERENCES acs_objects(object_id) ON DELETE CASCADE,
  child_id           integer
                     constraint cr_child_rels_child_id_nn
                     not null
		     CONSTRAINT cr_child_rels_child_id_fk
		     REFERENCES cr_items(item_id) ON DELETE CASCADE,
  relation_tag       varchar(100),
  order_n            integer
);

create index cr_child_rels_by_parent on cr_child_rels(parent_id);
create unique index cr_child_rels_unq_id on cr_child_rels(parent_id, child_id);
create unique index cr_child_rels_child_id_idx on cr_child_rels(child_id);


comment on table cr_child_rels is '
  Provides for richer parent-child relationships than the simple
  link encapsulated in the primary table.  May be subclassed to provide
  additional attributes.
';

create table cr_item_rels (
  rel_id             integer
                     constraint cr_item_rels_rel_id_pk
                     primary key
                     constraint cr_item_rels_rel_id_fk
                     references acs_objects,
  item_id            integer
		     CONSTRAINT cr_item_rels_item_id_fk
		     REFERENCES cr_items(item_id) ON DELETE CASCADE,
  related_object_id  integer
                     constraint cr_item_rels_rel_obj_fk
                     references acs_objects,
  relation_tag       varchar(100),
  order_n            integer
);

create unique index cr_item_rel_unq on cr_item_rels (
  item_id, related_object_id, relation_tag
);

-- RI Indexes
create index cr_item_rels_rel_obj_id_idx ON cr_item_rels(related_object_id);

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
  revision_id     integer constraint cr_revisions_revision_id_fk references
		  acs_objects (object_id) on delete cascade
		  constraint cr_revisions_revision_id_pk primary key,
  item_id         integer constraint cr_revisions_item_id_nn
                  not null
                  constraint cr_revisions_item_id_fk references
		  cr_items on delete cascade,
  title		  varchar(1000),
  description	  text,
  publish_date	  timestamptz,
  mime_type	  varchar(200) default 'text/plain'
		  constraint cr_revisions_mime_type_fk
		  references cr_mime_types,
  nls_language    varchar(50),
  -- lob_id if storage_type = lob.
  lob             integer
                  constraint cr_revisions_lob_fk
                  references lobs
                  on delete set null,
  -- content holds the file name if storage type = file
  -- otherwise it holds the text data if storage_type = text.
  content	  text,
  content_length  integer
);

-- RI Indexes 
create index cr_revisions_lob_idx ON cr_revisions(lob);
create index cr_revisions_item_id_idx ON cr_revisions(item_id);

CREATE TRIGGER cr_revisions_lob_trig AFTER UPDATE or DELETE or INSERT
ON cr_revisions FOR EACH ROW EXECUTE PROCEDURE on_lob_ref();

create index cr_revisions_by_mime_type on cr_revisions(mime_type);
create index cr_revisions_title_idx on cr_revisions(title);
create index cr_revisions_publish_date_idx on cr_revisions(publish_date);

-- create index cr_revisions_lower_title_idx on cr_revisions(lower(title));
-- create index cr_revisions_title_ltr_idx on cr_revisions(substr(lower(title), 1, 1));

create index cr_revisions_content_idx on cr_revisions (substring(content for 100));

comment on table cr_revisions is '
  Each content item may be associated with any number of revisions.
  The item_id is used to associate revisions with an item.
';

comment on column cr_revisions.nls_language  is '
  NLS_LANGUAGE is required in the same table as the content column
  for multi-lingual searching in Intermedia.
';

alter table cr_items add constraint cr_items_live_revision_fk 
      foreign key (live_revision) references cr_revisions(revision_id) on delete set null;

alter table cr_items add constraint cr_items_latest_revision_fk 
     foreign key (latest_revision) references cr_revisions(revision_id) on delete set null;




--
-- procedure cr_revision_del_ri_tr/0
--
-- CREATE OR REPLACE FUNCTION cr_revision_del_ri_tr(
-- ) RETURNS trigger AS $$
-- DECLARE
--         dummy           integer;
--         v_latest        integer;
--         v_live          integer;
-- BEGIN
--         select 1 into dummy
--         from 
--           cr_revisions           
--         where 
--           revision_id = old.live_revision;
--         
--         if FOUND then
--           raise EXCEPTION 'Referential Integrity: live_revision still exists: %', old.live_revision;
--         end if;
--         
--         select 1 into dummy
--         from 
--           cr_revisions 
--         where 
--           revision_id = old.latest_revision;
--         
--         if FOUND then
--           raise EXCEPTION 'Referential Integrity: latest_revision still exists: %', old.latest_revision;
--         end if;
--         
--         return old;
-- END;
-- $$ LANGUAGE plpgsql;



--
-- procedure cr_revision_ins_ri_tr/0
--
-- CREATE OR REPLACE FUNCTION cr_revision_ins_ri_tr(
-- ) RETURNS trigger AS $$
-- DECLARE
--         dummy           integer;
--         v_latest        integer;
--         v_live          integer;
-- BEGIN
--         select 1 into dummy
--         from 
--           cr_revisions           
--         where 
--           revision_id = new.live_revision;
--         
--         if NOT FOUND and new.live_revision is NOT NULL then
--           raise EXCEPTION 'Referential Integrity: live_revision does not exist: %', new.live_revision;
--         end if;
--         
--         select 1 into dummy
--         from 
--           cr_revisions 
--         where 
--           revision_id = new.latest_revision;
--         
--         if NOT FOUND and new.latest_revision is NOT NULL then
--           raise EXCEPTION 'Referential Integrity: latest_revision does not exist: %', new.latest_revision;
--         end if;
-- 
--         return new;
-- END;
-- $$ LANGUAGE plpgsql;



--
-- procedure cr_revision_up_ri_tr/0
--
-- CREATE OR REPLACE FUNCTION cr_revision_up_ri_tr(
-- ) RETURNS trigger AS $$
-- DECLARE
--         dummy           integer;
--         v_latest        integer;
--         v_live          integer;
-- BEGIN
--         select 1 into dummy
--         from 
--           cr_revisions           
--         where 
--           revision_id = new.live_revision;
--         
--         if NOT FOUND and new.live_revision <> old.live_revision and new.live_revision is NOT NULL then
--           raise EXCEPTION 'Referential Integrity: live_revision does not exist: %', new.live_revision;
--         end if;
--         
--         select 1 into dummy
--         from 
--           cr_revisions 
--         where 
--           revision_id = new.latest_revision;
--         
--         if NOT FOUND and new.latest_revision <> old.latest_revision and new.latest_revision is NOT NULL then
--           raise EXCEPTION 'Referential Integrity: latest_revision does not exist: %', new.latest_revision;
--         end if;
--         
--         return new;
-- END;
-- $$ LANGUAGE plpgsql;



--
-- procedure cr_revision_del_rev_ri_tr/0
--
-- CREATE OR REPLACE FUNCTION cr_revision_del_rev_ri_tr(
-- ) RETURNS trigger AS $$
-- DECLARE
--         dummy           integer;
-- BEGIN
--         select 1 into dummy
--         from 
--           cr_items
--         where 
--           item_id = old.item_id
--         and
--           live_revision = old.revision_id;
--         
--         if FOUND then
--           raise EXCEPTION 'Referential Integrity: attempting to delete live_revision: %', old.revision_id;
--         end if;
--         
--         select 1 into dummy
--         from 
--           cr_items
--         where 
--           item_id = old.item_id
--         and
--           latest_revision = old.revision_id;
--         
--         if FOUND then
--           raise EXCEPTION 'Referential Integrity: attempting to delete latest_revision: %', old.revision_id;
--         end if;
--         
--         return old;
-- END;
-- $$ LANGUAGE plpgsql;


-- reimplementation of RI triggers. (DanW dcwickstrom@earthlink.net)

-- create trigger cr_revision_del_ri_tr 
-- after delete on cr_items
-- for each row execute procedure cr_revision_del_ri_tr();

-- create trigger cr_revision_up_ri_tr 
-- after update on cr_items
-- for each row execute procedure cr_revision_up_ri_tr();

-- create trigger cr_revision_ins_ri_tr 
-- after insert on cr_items
-- for each row execute procedure cr_revision_ins_ri_tr();

-- create trigger cr_revision_del_rev_ri_tr 
-- after delete on cr_revisions
-- for each row execute procedure cr_revision_del_rev_ri_tr();



-- (DanW - OpenACS) Added cleanup trigger to log file items that need 
-- to be cleaned up from the CR.
--
-- procedure cr_cleanup_cr_files_del_tr/0
--
CREATE OR REPLACE FUNCTION cr_cleanup_cr_files_del_tr(
) RETURNS trigger AS $$
DECLARE
        
BEGIN
        insert into cr_files_to_delete
        select r.content as path, i.storage_area_key
          from cr_items i, cr_revisions r
         where i.item_id = r.item_id
           and r.revision_id = old.revision_id
           and i.storage_type = 'file'
           and r.content is not null;

        return old;
END;
$$ LANGUAGE plpgsql;

create trigger cr_cleanup_cr_files_del_tr
before delete on cr_revisions
for each row execute procedure cr_cleanup_cr_files_del_tr();


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



create table cr_content_text (
    revision_id        integer 
		       constraint cr_content_text_revision_id_pk primary key,
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
                     constraint cr_item_publish_audit_item_fk references cr_items (item_id) on delete cascade,
  old_revision       integer
                     constraint cr_item_publish_audit_orev_fk references cr_revisions (revision_id) on delete cascade,
  new_revision       integer
                     constraint cr_item_publish_audit_nrev_fk references cr_revisions (revision_id) on delete cascade,
  old_status         varchar(40),
  new_status         varchar(40),
  publish_date       timestamptz
                     constraint cr_item_publish_audit_date_nn
                     not null
);

create index cr_item_publish_audit_idx on cr_item_publish_audit(item_id);
create index cr_item_publish_audit_orev_idx on cr_item_publish_audit(old_revision);
create index cr_item_publish_audit_nrev_idx on cr_item_publish_audit(new_revision);

comment on table cr_item_publish_audit is '
  An audit table (populated by a trigger on cr_items.live_revision)
  that is used to keep track of the publication history of an item.
';

create table cr_release_periods (
  item_id          integer
                   constraint cr_release_periods_item_id_fk
		   references cr_items on delete cascade
                   constraint cr_release_periods_item_id_pk
		   primary key,
  start_when	   timestamptz default current_timestamp,
  end_when	   timestamptz default current_timestamp + interval '20 years'
);

create table cr_scheduled_release_log (
  exec_date        timestamptz default current_timestamp not null,
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
  last_exec  timestamptz
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
		    constraint cr_folders_folder_id_fk references
		    cr_items on delete cascade
		    constraint cr_folders_folder_id_pk 
                    primary key,
  label		    varchar(1000),
  description	    text,
  has_child_folders boolean default 'f',
  has_child_symlinks boolean default 'f',
  package_id integer 
  constraint cr_folders_pkg_id_fk
  references apm_packages
);  

comment on table cr_folders is '
  Folders are used to support a virtual file system within the content
  repository.
';

--RI Indexes
create index cr_folders_package_id_idx ON cr_folders(package_id);

create table cr_folder_type_map (
  folder_id	integer
		constraint cr_folder_type_map_fldr_fk
		references cr_folders on delete cascade,
  content_type  varchar(1000)
		constraint cr_folder_type_map_typ_fk
		references acs_object_types on delete cascade,
  constraint cr_folder_type_map_pk
  primary key (folder_id, content_type)
);

comment on table cr_folder_type_map is '
  A one-to-many mapping table of content folders to content types. 
  Basically, this table restricts the content types a folder may contain.
  Future releases will add numeric and tagged constraints similar to
  thos available for content types.  
';

-- RI Indexes 
create index cr_folder_typ_map_cont_typ_idx ON cr_folder_type_map(content_type);

--------------------------------------------------------------
-- CONTENT TEMPLATES
--------------------------------------------------------------

create table cr_templates (
  template_id	  integer
		  constraint cr_templates_template_id_fk references
		  cr_items on delete cascade
		  constraint cr_templates_template_id_pk 
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
  content_type     varchar(1000)
                   constraint cr_type_template_map_typ_fk
                   references acs_object_types
                   constraint cr_type_template_map_typ_nn
                   not null,
  template_id      integer
                   constraint cr_type_template_map_tmpl_fk
	           references cr_templates,
  use_context	   varchar(100)
                   constraint cr_type_template_map_ctx_nn
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
                   references cr_items (item_id) on delete cascade
                   constraint cr_item_template_map_item_nn
                   not null,
  template_id      integer
                   constraint cr_item_template_map_tmpl_fk
	           references cr_templates
                   constraint cr_item_template_map_tmpl_nn
                   not null,
  use_context	   varchar(100)
                   constraint cr_item_template_map_ctx_nn
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
		  constraint cr_symlinks_symlink_id_fk references
		  cr_items on delete cascade
		  constraint cr_symlinks_symlink_id_pk 
                  primary key,
  target_id       integer
  		  CONSTRAINT cr_symlinks_target_id_fk
		  REFERENCES cr_items(item_id) ON DELETE CASCADE
		  constraint cr_symlinks_target_id_nn
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
		  constraint cr_extlinks_extlink_id_fk references
		  cr_items on delete cascade
		  constraint cr_extlinks_extlink_id_pk 
                  primary key,
  url             varchar(1000)
		  constraint cr_extlinks_url_nn
		  not null,
  label           varchar(1000)
		  constraint cr_extlinks_label_nn
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
			 constraint cr_keywords_keyword_id_pk
		         primary key,
  parent_id              integer 
                         constraint cr_keywords_parent_id_fk
                         references cr_keywords,
  heading		 varchar(600)
			 constraint cr_keywords_heading_nn
			 not null,
  description            text,
  has_children           boolean,
  tree_sortkey           varbit
);

-- RI Indexes 
create index cr_keywords_parent_id_idx ON cr_keywords(parent_id);



-- added
select define_function_args('cr_keywords_get_tree_sortkey','keyword_id');

--
-- procedure cr_keywords_get_tree_sortkey/1
--
CREATE OR REPLACE FUNCTION cr_keywords_get_tree_sortkey(
   p_keyword_id integer
) RETURNS varbit AS $$
DECLARE
BEGIN
  return tree_sortkey from cr_keywords where keyword_id = p_keyword_id;
END;
$$ LANGUAGE plpgsql stable strict;



--
-- procedure cr_keywords_tree_insert_tr/0
--
CREATE OR REPLACE FUNCTION cr_keywords_tree_insert_tr(

) RETURNS trigger AS $$
DECLARE
        v_parent_sk      varbit default null;
        v_max_value      integer;
BEGIN
        if new.parent_id is null then 
            select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value 
              from cr_keywords 
             where parent_id is null;
        else 
            select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value 
              from cr_keywords 
             where parent_id = new.parent_id;

            select tree_sortkey into v_parent_sk 
              from cr_keywords 
             where keyword_id = new.parent_id;
        end if;

        new.tree_sortkey := tree_next_key(v_parent_sk, v_max_value);

        return new;

END;
$$ LANGUAGE plpgsql;

create trigger cr_keywords_tree_insert_tr before insert 
on cr_keywords for each row 
execute procedure cr_keywords_tree_insert_tr ();



--
-- procedure cr_keywords_tree_update_tr/0
--
CREATE OR REPLACE FUNCTION cr_keywords_tree_update_tr(

) RETURNS trigger AS $$
DECLARE
        v_parent_sk     varbit default null;
        v_max_value     integer;
        p_id            integer;
        v_rec           record;
        clr_keys_p      boolean default 't';
BEGIN
        if new.keyword_id = old.keyword_id and 
           ((new.parent_id = old.parent_id) or
            (new.parent_id is null and old.parent_id is null)) 
        THEN

           return new;

        end if;

        for v_rec in select keyword_id
                       from cr_keywords 
                      where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey)
                   order by tree_sortkey
        LOOP
            if clr_keys_p then
               update cr_keywords set tree_sortkey = null
               where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);
               clr_keys_p := 'f';
            end if;
            
            select parent_id into p_id
              from cr_keywords 
             where keyword_id = v_rec.keyword_id;

            if p_id is null then 
                select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
                  from cr_keywords 
                 where parent_id is null;
            else 
                select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
                  from cr_keywords 
                 where parent_id = p_id;

                select tree_sortkey into v_parent_sk 
                  from cr_keywords 
                 where keyword_id = p_id;
            end if;

            update cr_keywords 
               set tree_sortkey = tree_next_key(v_parent_sk, v_max_value)
             where keyword_id = v_rec.keyword_id;

        end LOOP;

        return new;

END;
$$ LANGUAGE plpgsql;

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
                   constraint cr_item_keyword_map_item_id_fk
                   references cr_items (item_id) on delete cascade
                   constraint cr_item_keyword_map_item_id_nn
                   not null,
  keyword_id       integer
                   constraint cr_item_keyword_map_kw_fk
	           references cr_keywords
                   constraint cr_item_keyword_map_kw_nn
                   not null,
  constraint cr_item_keyword_map_pk
  primary key (item_id, keyword_id)
);

-- RI Indexes
create index cr_item_keyword_map_kw_id_idx ON cr_item_keyword_map(keyword_id);

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

CREATE OR REPLACE FUNCTION cr_text_tr () RETURNS trigger AS $$
BEGIN

   raise EXCEPTION '-20000: Inserts are not allowed into cr_text.';

   return new;

END;
$$ LANGUAGE plpgsql;

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
    revision_id        integer 
                       constraint cr_doc_filter_revision_id_pk 
                       primary key,
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



--
-- procedure inline_1/0
--
CREATE OR REPLACE FUNCTION inline_1(

) RETURNS integer AS $$
DECLARE
  v_id integer;
BEGIN

  PERFORM content_type__register_mime_type('content_revision', 
                                           'text/html');
  PERFORM content_type__register_mime_type('content_revision', 
                                           'text/plain');
  PERFORM content_type__register_mime_type('content_revision', 
                                           'application/rtf');

  v_id := content_folder__new (
    'pages',
    'Pages', 
    'Site pages go here',
    -4,
    null,
    content_item__get_root_folder(null),
    now(),
    null,
    null
  );

  PERFORM content_folder__register_content_type(
    v_id,
    'content_revision',
    't'
  );

  PERFORM content_folder__register_content_type(
    v_id,
    'content_folder',
    't'
  );

  PERFORM content_folder__register_content_type(
    v_id,
    'content_symlink',
    't'
  );

  -- add the root content folder to acs_magic_objects
  insert into acs_magic_objects (name, object_id)
  select 'cr_item_root',
         content_item__get_root_folder(null);

  v_id := content_folder__new (
    'templates',
    'Templates', 
    'Templates which render the pages go here',
    -4,
    null,
    content_template__get_root_folder(),
    now(),
    null,
    null
  );

  PERFORM content_folder__register_content_type(
    v_id,
    'content_folder',
    't'
  );

  PERFORM content_folder__register_content_type(
    v_id,
    'content_symlink',
    't'
  );

  PERFORM content_folder__register_content_type(
    v_id,
    'content_template',
    't'
  );

  -- add to acs_magic_objects
  insert into acs_magic_objects (name, object_id)
  select 'cr_template_root',
         content_template__get_root_folder();

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_1 ();

drop function inline_1 ();




--
-- procedure inline_2/0
--
CREATE OR REPLACE FUNCTION inline_2(

) RETURNS integer AS $$
DECLARE
  v_item_id     integer;
  v_revision_id integer;
BEGIN

  select nextval('t_acs_object_id_seq') into v_item_id;

  PERFORM content_template__new(
                'default_template',
                '-200',
                v_item_id,
                now(),
                null,
                null
        );

  v_revision_id := content_revision__new(
               'Template',
               null,           -- description
               now(),          -- publish_date
               'text/html',    -- mime_type
               null,           -- nls_language
               '<html><body>@text;noquote@</body></html>',
               v_item_id,
               null,           -- revision_id
               now(),          -- creation_date
               null,           -- creation_user
               null,           -- creation_ip
	       null,           -- content_length
	       null            -- package_id
	       );

  update 
    cr_revisions
  set 
    content_length = length(content)
  where
    revision_id = v_revision_id;

  update 
    cr_items
  set 
    live_revision = v_revision_id
  where 
    item_id = v_item_id;


  PERFORM content_type__register_template(
                       'content_revision',
	               v_item_id,
	               'public',
                       't');


  PERFORM content_type__register_template(
                       'image',
	               v_item_id,
	               'public',
                       't');

  -- testing, this may go away.  DanW
  PERFORM content_type__register_template(
                       'content_template',
	               v_item_id,
	               'public',
                       't');

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_2 ();

drop function inline_2 ();

-- this was added for edit-this-page and others
-- 05-Nov-2001 Jon Griffin jon@mayuli.com

---drop the previw constraint

alter table cr_folders
drop constraint cr_folders_pkg_id_fk;
-------

alter table cr_folders
add constraint cr_folders_package_id_fk foreign key (package_id) references apm_packages (package_id);

--constraint cr_fldr_pkg_id_fk

-- prompt *** Preparing search indices...
\i content-search.sql



