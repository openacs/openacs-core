-- Upgrade script
--
-- @author vinod@kurup.com
-- @created 2002-10-06

-- fixes bug #1502 http://openacs.org/sdm/one-baf.tcl?baf_id=1502
-- This bug was actually fixed in 4.5, but it didn't get merged in properly
-- so let's recreate the function to be sure that it's right

create or replace function content_keyword__delete (integer)
returns integer as '
declare
  delete__keyword_id             alias for $1;  
  v_rec                          record; 
begin

  for v_rec in select item_id from cr_item_keyword_map 
    where keyword_id = delete__keyword_id LOOP
    PERFORM content_keyword__item_unassign(v_rec.item_id, delete__keyword_id);
  end LOOP;

  PERFORM acs_object__delete(delete__keyword_id);

  return 0; 
end;' language 'plpgsql';


-- add mime_types

insert into cr_mime_types(label, mime_type, file_extension) select 'Binary', 'application/octet-stream', 'bin' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/octet-stream');
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Word', 'application/msword', 'doc' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/msword');
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Excel', 'application/msexcel', 'xls' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/msexcel');
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft PowerPoint', 'application/powerpoint', 'ppt' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/powerpoint');
insert into cr_mime_types(label, mime_type, file_extension) select 'Microsoft Project', 'application/msproject', 'mpp' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/msproject');
insert into cr_mime_types(label, mime_type, file_extension) select 'PostScript', 'application/postscript', 'ps' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/postscript');
insert into cr_mime_types(label, mime_type, file_extension) select 'Adobe Illustrator', 'application/x-illustrator', 'ai' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/x-illustrator');
insert into cr_mime_types(label, mime_type, file_extension) select 'Adobe PageMaker', 'application/x-pagemaker', 'p65' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/x-pagemaker');
insert into cr_mime_types(label, mime_type, file_extension) select 'Filemaker Pro', 'application/filemaker', 'fm' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/filemaker');
insert into cr_mime_types(label, mime_type, file_extension) select 'Image Pict', 'image/x-pict', 'pic' from dual where not exists (select 1 from cr_mime_types where mime_type = 'image/x-pict');
insert into cr_mime_types(label, mime_type, file_extension) select 'Photoshop', 'application/x-photoshop', 'psd' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/x-photoshop');
insert into cr_mime_types(label, mime_type, file_extension) select 'Acrobat', 'application/pdf', 'pdf' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/pdf');
insert into cr_mime_types(label, mime_type, file_extension) select 'Video Quicktime', 'video/quicktime', 'mov' from dual where not exists (select 1 from cr_mime_types where mime_type = 'video/quicktime');
insert into cr_mime_types(label, mime_type, file_extension) select 'Video MPEG', 'video/mpeg', 'mpg' from dual where not exists (select 1 from cr_mime_types where mime_type = 'video/mpeg');
insert into cr_mime_types(label, mime_type, file_extension) select 'Audio AIFF',  'audio/aiff', 'aif' from dual where not exists (select 1 from cr_mime_types where mime_type = 'audio/aiff');
insert into cr_mime_types(label, mime_type, file_extension) select 'Audio Basic', 'audio/basic',      'au' from dual where not exists (select 1 from cr_mime_types where mime_type = 'audio/basic');
insert into cr_mime_types(label, mime_type, file_extension) select 'Audio Voice', 'audio/voice',      'voc' from dual where not exists (select 1 from cr_mime_types where mime_type = 'audio/voice');
insert into cr_mime_types(label, mime_type, file_extension) select 'Audio Wave', 'audio/wave', 'wav' from dual where not exists (select 1 from cr_mime_types where mime_type = 'audio/wave');
insert into cr_mime_types(label, mime_type, file_extension) select 'Archive Zip', 'application/zip', 'zip' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/zip');
insert into cr_mime_types(label, mime_type, file_extension) select 'Archive Tar', 'application/z-tar', 'tar' from dual where not exists (select 1 from cr_mime_types where mime_type = 'application/z-tar');
 

-- new version of content_image__new

create or replace function image__new (varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,boolean,timestamp,varchar,integer,integer,integer
  ) returns integer as '
  declare
    new__name		alias for $1;
    new__parent_id	alias for $2; -- default null
    new__item_id	alias for $3; -- default null
    new__revision_id	alias for $4; -- default null
    new__mime_type	alias for $5; -- default jpeg
    new__creation_user  alias for $6; -- default null
    new__creation_ip    alias for $7; -- default null
    new__relation_tag	alias for $8; -- default null
    new__title          alias for $9; -- default null
    new__description    alias for $10; -- default null
    new__is_live        alias for $11; -- default f
    new__publish_date	alias for $12; -- default now()
    new__path   	alias for $13; 
    new__file_size   	alias for $14; 
    new__height    	alias for $15;
    new__width		alias for $16; 

    new__locale          varchar default null;
    new__nls_language	 varchar default null;
    new__creation_date	 timestamp default now();
    new__context_id      integer;	

    v_item_id		 cr_items.item_id%TYPE;
    v_revision_id	 cr_revisions.revision_id%TYPE;
  begin
    new__context_id := new__parent_id;

    v_item_id := content_item__new (
      new__name,
      new__parent_id,
      new__item_id,
      new__locale,
      new__creation_date,
      new__creation_user,	
      new__context_id,
      new__creation_ip,
      ''content_item'',
      ''image'',
      null,
      new__description,
      new__mime_type,
      new__nls_language,
      null,
      ''file'' -- storage_type
    );

    -- update cr_child_rels to have the correct relation_tag
    update cr_child_rels
    set relation_tag = new__relation_tag
    where parent_id = new__parent_id
    and child_id = new__item_id
    and relation_tag = content_item__get_content_type(new__parent_id) || ''-'' || ''image'';

    v_revision_id := content_revision__new (
      new__title,
      new__description,
      new__publish_date,
      new__mime_type,
      new__nls_language,
      null,
      v_item_id,
      new__revision_id,
      new__creation_date,
      new__creation_user,
      new__creation_ip
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, new__height, new__width);

    -- update revision with image file info
    update cr_revisions
    set content_length = new__file_size,
    content = new__path
    where revision_id = v_revision_id;

    -- is_live => ''t'' not used as part of content_item.new
    -- because content_item.new does not let developer specify revision_id,
    -- revision_id is determined in advance 

    if new__is_live = ''t'' then
       PERFORM content_item__set_live_revision (v_revision_id);
    end if;

    return v_item_id;
end; ' language 'plpgsql';


-- new stuff to index only live revisions from davb

-- change triggers to index only live revisions --DaveB 2002-09-26
-- triggers queue search interface to modify search index after content
-- changes.

drop function content_search__itrg() cascade;

create or replace function content_search__itrg ()
returns opaque as '
begin
if (select live_revision from cr_items where item_id=new.item_id) = new.revision_id then	
	perform search_observer__enqueue(new.revision_id,''INSERT'');
    end if;
    return new;
end;' language 'plpgsql';

drop function content_search__dtrg() cascade;

create or replace function content_search__dtrg ()
returns opaque as '
begin
    select into v_live_revision live_revision from
	cr_items where item_id=old.item_id;
    if old.revision_id=v_live_revision then
	perform search_observer__enqueue(old.revision_id,''DELETE'');
    end if;
    return old;
end;' language 'plpgsql';

drop function content_search__utrg() cascade;

create or replace function content_search__utrg ()
returns opaque as '
declare
    v_live_revision integer;
begin
    select into v_live_revision live_revision from
	cr_items where item_id=old.revision_id;
    if old.revision_id=v_live_revision then
	insert into search_observer_queue (
            object_id,
	    event
        ) values (
old.revision_id,
            ''UPDATE''
        );
    end if;
    return new;
end;' language 'plpgsql';

-- we need new triggers on cr_items to index when a live revision
-- changes


create trigger content_search__itrg after insert on cr_revisions
for each row execute procedure content_search__itrg (); 

create trigger content_search__dtrg after delete on cr_revisions
for each row execute procedure content_search__dtrg (); 

create trigger content_search__utrg after update on cr_revisions
for each row execute procedure content_search__utrg (); 

-- LARS: REMOVED


-- content-type.sql

create or replace function content_type__trigger_insert_statement (varchar)
returns varchar as '
declare
  trigger_insert_statement__content_type   alias for $1;  
  v_table_name                             acs_object_types.table_name%TYPE;
  v_id_column                              acs_object_types.id_column%TYPE;
  cols                                     varchar default '''';
  vals                                     varchar default '''';
  attr_rec                                 record;
begin

  select 
    table_name, id_column into v_table_name, v_id_column
  from 
    acs_object_types 
  where 
    object_type = trigger_insert_statement__content_type;

  for attr_rec in select
                    attribute_name
                  from
                    acs_attributes
                  where
                    object_type = trigger_insert_statement__content_type 
  LOOP
    cols := cols || '', '' || attr_rec.attribute_name;
    vals := vals || '', new.'' || attr_rec.attribute_name;
  end LOOP;

  return ''insert into '' || v_table_name || 
    '' ( '' || v_id_column || cols || '' ) values (cr_dummy.val'' ||
    vals || '')'';
  
end;' language 'plpgsql';

