
create or replace package content_revision
as

function new (
  --/** Create a new revision for an item. 
  --    @author Karl Goldstein
  --    @param title        The revised title for the item
  --    @param description  A short description of this revision, 4000 characters maximum
  --    @param publish_date Publication date.
  --    @param mime_type    The revised mime type of the item, defaults to 'text/plain'
  --    @param nls_language The revised language of the item, for use with Intermedia searching
  --    @param data         The blob which contains the body of the revision
  --    @param item_id      The id of the item being revised
  --    @param revision_id  The id of the new revision. A new id will be allocated by default
  --    @param creation_date As in <tt>acs_object.new</tt>
  --    @param creation_ip   As in <tt>acs_object.new</tt>
  --    @param creation_user As in <tt>acs_object.new</tt>
  --    @return The id of the newly created revision
  --    @see {acs_object.new}, {content_item.new}
  --*/
  title         in cr_revisions.title%TYPE,
  description   in cr_revisions.description%TYPE default null,
  publish_date  in cr_revisions.publish_date%TYPE default sysdate,
  mime_type   	in cr_revisions.mime_type%TYPE default 'text/plain',
  nls_language 	in cr_revisions.nls_language%TYPE default null,
  data	        in cr_revisions.content%TYPE,
  item_id       in cr_items.item_id%TYPE,
  revision_id   in cr_revisions.revision_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  filename	in cr_revisions.filename%TYPE default null
) return cr_revisions.revision_id%TYPE;

function new (
  title         in cr_revisions.title%TYPE,
  description   in cr_revisions.description%TYPE default null,
  publish_date  in cr_revisions.publish_date%TYPE default sysdate,
  mime_type   	in cr_revisions.mime_type%TYPE default 'text/plain',
  nls_language 	in cr_revisions.nls_language%TYPE default null,
  text		in varchar2 default null,
  item_id       in cr_items.item_id%TYPE,
  revision_id   in cr_revisions.revision_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE default sysdate,
  creation_user	in acs_objects.creation_user%TYPE default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  filename	in cr_revisions.filename%TYPE default null
) return cr_revisions.revision_id%TYPE;

function copy (
  --/** Creates a new copy of a revision, including all attributes and content
  --    and content, returning the ID of the new revision
  --    @author Karl Goldstein, Michael Pih
  --    @param revision_id	The id of the revision to copy
  --    @param copy_id		The id of the new copy (default null)
  --    @param target_item_id	The id of the item which will own the copied revision. If null, the item that holds the original revision will own the copied revision. Defaults to null.
  --    @param creation_user	The id of the creation user
  --    @param creation_ip  The IP address of the creation user (default null)
  --    @return		    The id of the new revision
  --    @see {content_revision.new}
  --*/
  revision_id		in cr_revisions.revision_id%TYPE,
  copy_id		in cr_revisions.revision_id%TYPE default null,
  target_item_id	in cr_items.item_id%TYPE default null,
  creation_user		in acs_objects.creation_user%TYPE default null,
  creation_ip		in acs_objects.creation_ip%TYPE default null
) return cr_revisions.revision_id%TYPE;

procedure del (
  --/** Deletes the revision.
  --    @author Karl Goldstein
  --    @param revision_id The id of the revision to delete
  --    @see {content_revision.new}, {acs_object.delete}
  --*/
  revision_id	in cr_revisions.revision_id%TYPE
);

function get_number (
  --/** Return the revision number of the specified revision, according to 
  --    the chronological
  --    order in which revisions have been added for this item.
  --    @author Karl Goldstein
  --    @param revision_id The id the revision
  --    @return The number of the revision
  --    @see {content_revision.new}
  --*/
  revision_id   in cr_revisions.revision_id%TYPE
) return number;

function revision_name (
  --/** Return a pretty string 'revision x of y'
  --*/
  revision_id   in cr_revisions.revision_id%TYPE
) return varchar2;

procedure index_attributes(
  --/** Generates an XML document for insertion into cr_revision_attributes,
  --    which is indexed by Intermedia for searching attributes.
  --    @author Karl Goldstein
  --    @param revision_id The id of the revision to index
  --    @see {content_revision.new}
  --*/
  revision_id IN cr_revisions.revision_id%TYPE
);

function export_xml (
  revision_id IN cr_revisions.revision_id%TYPE
) return cr_xml_docs.doc_id%TYPE;

function write_xml (
  revision_id IN number,
  clob_loc IN clob
) return number as language
  java
name
  'com.arsdigita.content.XMLExchange.exportRevision(
     java.lang.Integer, oracle.sql.CLOB
  ) return int';

function import_xml (
  item_id IN cr_items.item_id%TYPE,
  revision_id IN cr_revisions.revision_id%TYPE,
  doc_id IN number
) return cr_revisions.revision_id%TYPE;

function read_xml (
  item_id IN number,
  revision_id IN number,
  clob_loc IN clob
) return number as language
  java
name
  'com.arsdigita.content.XMLExchange.importRevision(
     java.lang.Integer, java.lang.Integer, oracle.sql.CLOB
  ) return int';

procedure to_html (
  --/** Converts a revision uploaded as a binary document to html
  --    @author Karl Goldstein
  --    @param revision_id The id of the revision to index
  --*/
  revision_id IN cr_revisions.revision_id%TYPE
);

procedure replace(
  revision_id number, search varchar2, replace varchar2)
as language 
  java 
name 
  'com.arsdigita.content.Regexp.replace(
    int, java.lang.String, java.lang.String
   )';

function is_live (
  -- /** Determine if the revision is live
  --   @author Karl Goldstein, Stanislav Freidin
  --   @param revision_id The id of the revision to check
  --   @return 't' if the revision is live, 'f' otherwise
  --   @see {content_revision.is_latest}
  --*/
  revision_id in cr_revisions.revision_id%TYPE
) return varchar2;

function is_latest (
  -- /** Determine if the revision is the latest revision
  --   @author Karl Goldstein, Stanislav Freidin
  --   @param revision_id The id of the revision to check
  --   @return 't' if the revision is the latest revision for its item, 'f' otherwise
  --   @see {content_revision.is_live}
  --*/
  revision_id in cr_revisions.revision_id%TYPE
) return varchar2;

procedure to_temporary_clob (
  revision_id in cr_revisions.revision_id%TYPE
);

procedure content_copy (
  -- /** Copies the content of the specified revision to the content
  --   of another revision
  --   @author Michael Pih
  --   @param revision_id The id of the revision with the content to be copied
  --   @param revision_id The id of the revision to be updated, defaults to the
  --   latest revision of the item with which the source revision is 
  --   associated.
  --*/
  revision_id	       in cr_revisions.revision_id%TYPE,
  revision_id_dest     in cr_revisions.revision_id%TYPE default null
);

end content_revision;
/
show errors


create or replace package body content_revision
as

function new (
  title         in cr_revisions.title%TYPE,
  description   in cr_revisions.description%TYPE default null,
  publish_date  in cr_revisions.publish_date%TYPE default sysdate,
  mime_type   	in cr_revisions.mime_type%TYPE default 'text/plain',
  nls_language 	in cr_revisions.nls_language%TYPE default null,
  data	        in cr_revisions.content%TYPE,
  item_id       in cr_items.item_id%TYPE,
  revision_id   in cr_revisions.revision_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE default sysdate,
  creation_user	in acs_objects.creation_user%TYPE default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  filename	in cr_revisions.filename%TYPE default null

) return cr_revisions.revision_id%TYPE is

  v_revision_id integer;
  v_content_type acs_object_types.object_type%TYPE;

begin

  v_content_type := content_item.get_content_type(item_id);

  v_revision_id := acs_object.new(
      object_id     => revision_id,
      object_type   => v_content_type, 
      creation_date => creation_date, 
      creation_user => creation_user, 
      creation_ip   => creation_ip, 
      context_id    => item_id
  );

  insert into cr_revisions (
    revision_id, title, description, mime_type, publish_date,
    nls_language, content, item_id, filename
  ) values (
    v_revision_id, title, description, mime_type, publish_date,
    nls_language, data, item_id, filename
  );

  return v_revision_id;

end new;

function new (
  title         in cr_revisions.title%TYPE,
  description   in cr_revisions.description%TYPE default null,
  publish_date  in cr_revisions.publish_date%TYPE default sysdate,
  mime_type   	in cr_revisions.mime_type%TYPE default 'text/plain',
  nls_language 	in cr_revisions.nls_language%TYPE default null,
  text		in varchar2 default null,
  item_id       in cr_items.item_id%TYPE,
  revision_id   in cr_revisions.revision_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE default sysdate,
  creation_user	in acs_objects.creation_user%TYPE default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  filename	in cr_revisions.filename%TYPE default null
) return cr_revisions.revision_id%TYPE is

  v_revision_id integer;
  blob_loc cr_revisions.content%TYPE;

begin

  blob_loc := empty_blob();

  v_revision_id := content_revision.new(
      title         => title,
      description   => description,
      publish_date  => publish_date,
      mime_type     => mime_type,
      nls_language  => nls_language,
      data          => blob_loc,
      item_id       => item_id, 
      revision_id   => revision_id,
      creation_date => creation_date,
      creation_user => creation_user,
      creation_ip   => creation_ip,
      filename      => filename
  );

  select 
    content into blob_loc
  from 
    cr_revisions 
  where 
    revision_id = v_revision_id
  for update;

  string_to_blob(text, blob_loc);

  return v_revision_id;

end new;

procedure copy_attributes (
  content_type  in acs_object_types.object_type%TYPE,
  revision_id	in cr_revisions.revision_id%TYPE,
  copy_id	in cr_revisions.revision_id%TYPE
) is

  v_table_name acs_object_types.table_name%TYPE;
  v_id_column acs_object_types.id_column%TYPE;

  cursor attr_cur is
    select
      attribute_name
    from
      acs_attributes
    where
      object_type = copy_attributes.content_type;

  cols varchar2(2000) := '';

begin

  select table_name, id_column into v_table_name, v_id_column
  from acs_object_types where object_type = copy_attributes.content_type;

  for attr_rec in attr_cur loop
    cols := cols || ', ' || attr_rec.attribute_name;
  end loop;

  execute immediate 'insert into ' || v_table_name || 
    ' ( ' || v_id_column || cols || ' ) ( select ' || copy_id || cols ||
    ' from ' || v_table_name || ' where ' || v_id_column || ' = ' || 
    revision_id || ')';
  
end copy_attributes;

function copy (
  revision_id		in cr_revisions.revision_id%TYPE,
  copy_id		in cr_revisions.revision_id%TYPE default null,
  target_item_id	in cr_items.item_id%TYPE default null,
  creation_user		in acs_objects.creation_user%TYPE default null,
  creation_ip		in acs_objects.creation_ip%TYPE default null
) return cr_revisions.revision_id%TYPE 
is 
  v_copy_id		cr_revisions.revision_id%TYPE;
  v_target_item_id	cr_items.item_id%TYPE;

  -- get the content_type and supertypes
  cursor type_cur is
    select                                                
      object_type
    from                                                
      acs_object_types                                  
    where                                               
      object_type ^= 'acs_object'                       
    and                                                 
      object_type ^= 'content_revision'                 
    connect by                                          
      prior supertype = object_type                     
    start with                                          
      object_type = (                                   
        select object_type from acs_objects where object_id = copy.revision_id
      )
    order by
      level desc;

begin
  -- use the specified item_id or the item_id of the original revision 
  --   if none is specified
  if target_item_id is null then
    select item_id into v_target_item_id from cr_revisions 
      where revision_id = copy.revision_id;
  else
    v_target_item_id := target_item_id;
  end if;

  -- use the copy_id or generate a new copy_id if none is specified
  --   the copy_id is a revision_id
  if copy_id is null then
    select acs_object_id_seq.nextval into v_copy_id from dual;
  else
    v_copy_id := copy_id;
  end if;

  -- create the basic object
  insert into acs_objects ( 
    object_id, object_type, context_id, security_inherit_p, 
    creation_user, creation_date, creation_ip,
    last_modified, modifying_user, modifying_ip
  ) ( select 
    v_copy_id, object_type, v_target_item_id, security_inherit_p, 
    copy.creation_user, sysdate, copy.creation_ip,
    sysdate, copy.creation_user, copy.creation_ip from
    acs_objects where object_id = copy.revision_id
  );
  
  -- create the basic revision (using v_target_item_id)
  insert into cr_revisions (
    revision_id, title, description, publish_date, mime_type, 
    nls_language, content, item_id, content_length
  ) ( select 
        v_copy_id, title, description, publish_date, mime_type, nls_language, 
	content, v_target_item_id, content_length 
      from 
        cr_revisions 
      where
        revision_id = copy.revision_id
  );

  -- iterate over the ancestor types and copy attributes
  for type_rec in type_cur loop
    copy_attributes(type_rec.object_type, copy.revision_id, v_copy_id);
  end loop;

  return v_copy_id;
end copy;

procedure del (
  revision_id	in cr_revisions.revision_id%TYPE
) is
  v_item_id         cr_items.item_id%TYPE;
  v_latest_revision cr_revisions.revision_id%TYPE;
  v_live_revision   cr_revisions.revision_id%TYPE;

begin

  -- Get item id and latest/live revisions
  select item_id into v_item_id from cr_revisions 
    where revision_id = content_revision.del.revision_id;

  select 
    latest_revision, live_revision
  into 
    v_latest_revision, v_live_revision
  from 
    cr_items
  where 
    item_id = v_item_id;

  -- Recalculate latest revision
  if v_latest_revision = content_revision.del.revision_id then
    declare
      cursor c_revision_cur is
        select r.revision_id from cr_revisions r, acs_objects o
         where o.object_id = r.revision_id
           and r.item_id = v_item_id
           and r.revision_id <> content_revision.del.revision_id
        order by o.creation_date desc;
    begin
      open c_revision_cur;
      fetch c_revision_cur into v_latest_revision;
      if c_revision_cur%NOTFOUND then
        v_latest_revision := null;        
      end if;
      close c_revision_cur;
    
      update cr_items set latest_revision = v_latest_revision
        where item_id = v_item_id;
    end;
  end if; 
 
  -- Clear live revision
  if v_live_revision = content_revision.del.revision_id then
    update cr_items set live_revision = null
      where item_id = v_item_id;   
  end if; 

  -- Clear the audit
  delete from cr_item_publish_audit
    where old_revision = content_revision.del.revision_id
       or new_revision = content_revision.del.revision_id;

  -- Delete the revision
  acs_object.del(revision_id);

end del;

function get_number (
  revision_id   in cr_revisions.revision_id%TYPE
) return number is

  cursor rev_cur is
    select
      revision_id
    from 
      cr_revisions r, acs_objects o
    where
      item_id = (select item_id from cr_revisions 
                      where revision_id = get_number.revision_id)
    and
      o.object_id = r.revision_id
    order by
      o.creation_date;

  v_number integer;
  v_revision cr_revisions.revision_id%TYPE;

begin

  open rev_cur;
  loop 

    fetch rev_cur into v_revision;

    if v_revision = get_number.revision_id then
      v_number := rev_cur%ROWCOUNT;
      exit;
    end if;

  end loop;
  close rev_cur;

  return v_number;

end get_number;

function revision_name(
  revision_id IN cr_revisions.revision_id%TYPE
) return varchar2 is

  v_text varchar2(500);
  v_sql  varchar2(500);

begin

  v_sql := 'select ''Revision '' || content_revision.get_number(r.revision_id) || '' of '' || (select count(*) from cr_revisions where item_id = r.item_id) || '' for item: '' || content_item.get_title(item_id)
  from cr_revisions r
  where r.revision_id = ' || revision_name.revision_id;

  execute immediate v_sql into v_text;

  return v_text;

end revision_name;

procedure index_attributes(
  revision_id IN cr_revisions.revision_id%TYPE
) is

  clob_loc clob;
  v_revision_id cr_revisions.revision_id%TYPE;

begin

  insert into cr_revision_attributes (
    revision_id, attributes
  ) values (
    revision_id, empty_clob()
  ) returning attributes into clob_loc;

  v_revision_id := write_xml(revision_id, clob_loc);  

end index_attributes;

function import_xml (
  item_id IN cr_items.item_id%TYPE,
  revision_id IN cr_revisions.revision_id%TYPE,
  doc_id IN number
) return cr_revisions.revision_id%TYPE is

  clob_loc clob;
  v_revision_id cr_revisions.revision_id%TYPE;

begin

  select doc into clob_loc from cr_xml_docs where doc_id = import_xml.doc_id;
  v_revision_id := read_xml(item_id, revision_id, clob_loc);  

  return v_revision_id;

end import_xml;

function export_xml (
  revision_id IN cr_revisions.revision_id%TYPE
) return cr_xml_docs.doc_id%TYPE is

  clob_loc clob;
  v_doc_id cr_xml_docs.doc_id%TYPE;
  v_revision_id cr_revisions.revision_id%TYPE;

begin

  insert into cr_xml_docs (doc_id, doc) 
    values (cr_xml_doc_seq.nextval, empty_clob())
    returning doc_id, doc into v_doc_id, clob_loc;

  v_revision_id := write_xml(revision_id, clob_loc);  

  return v_doc_id;

end export_xml;

procedure to_html (
  revision_id IN cr_revisions.revision_id%TYPE
) is

 tmp_clob clob;
 blob_loc blob;

begin

  ctx_doc.filter('cr_doc_filter_index', revision_id, tmp_clob, false);

  select 
    content into blob_loc
  from 
    cr_revisions 
  where 
    revision_id = to_html.revision_id
  for update;

 clob_to_blob(tmp_clob, blob_loc);

 dbms_lob.freetemporary(tmp_clob);

end to_html;

function is_live (
  revision_id in cr_revisions.revision_id%TYPE
) return varchar2
is
  v_ret varchar2(1);
begin

  select 't' into v_ret from cr_items
    where live_revision = is_live.revision_id;

  return v_ret;

exception when no_data_found then
  return 'f';
end is_live;

function is_latest (
  revision_id in cr_revisions.revision_id%TYPE
) return varchar2
is
  v_ret varchar2(1);
begin

  select 't' into v_ret from cr_items
    where latest_revision = is_latest.revision_id;

  return v_ret;

exception when no_data_found then
  return 'f';
end is_latest;

procedure to_temporary_clob (
  revision_id in cr_revisions.revision_id%TYPE
) is
  b blob;
  c clob;

begin

  insert into cr_content_text (
    revision_id, content
  ) values (
    revision_id, empty_clob()
  ) returning content into c;

  select content into b from cr_revisions 
    where revision_id = to_temporary_clob.revision_id;

  blob_to_clob(b, c);

end to_temporary_clob;




-- revision_id is the revision with the content that is to be copied
procedure content_copy (
  revision_id	       in cr_revisions.revision_id%TYPE,
  revision_id_dest     in cr_revisions.revision_id%TYPE default null
) is
  v_item_id             cr_items.item_id%TYPE;
  v_content_length	integer;
  v_revision_id_dest	cr_revisions.revision_id%TYPE;
  v_filename            cr_revisions.filename%TYPE;
  v_content             blob;
begin

  select
    content_length, item_id
  into
    v_content_length, v_item_id
  from
    cr_revisions
  where
    revision_id = content_copy.revision_id;

  -- get the destination revision
  if content_copy.revision_id_dest is null then
    select
      latest_revision into v_revision_id_dest
    from
      cr_items
    where
      item_id = v_item_id;
  else
    v_revision_id_dest := content_copy.revision_id_dest;
  end if;


  -- only copy the content if the source content is not null
  if v_content_length is not null and v_content_length > 0 then

    /* The internal LOB types - BLOB, CLOB, and NCLOB - use copy semantics, as 
       opposed to the reference semantics which apply to BFILEs.
       When a BLOB, CLOB, or NCLOB is copied from one row to another row in 
       the same table or in a different table, the actual LOB value is
       copied, not just the LOB locator. */

    select 
      filename, content_length
    into 
      v_filename, v_content_length
    from 
      cr_revisions
    where
      revision_id = content_copy.revision_id;

    -- need to update the file name after the copy,
    -- if this content item is in CR file storage.  The file name is based
    -- off of the item_id and revision_id and it will be invalid for the 
    -- copied revision.

    update cr_revisions       
      set content = (select content from cr_revisions where revision_id = content_copy.revision_id),
          filename = v_filename,
          content_length = v_content_length
      where revision_id = v_revision_id_dest;
  end if;

end content_copy;



end content_revision;
/
show errors

-- Trigger to maintain latest_revision in cr_items

create or replace trigger cr_revision_latest_tr 
after insert on cr_revisions for each row
begin
  update cr_items set latest_revision = :new.revision_id
  where item_id = :new.item_id;
end cr_revision_latest_tr;
/
show errors


