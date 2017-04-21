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
  filename	in cr_revisions.filename%TYPE default null,
  package_id	in acs_objects.package_id%TYPE default null
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
  package_id	in acs_objects.package_id%TYPE default null,
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
  filename	in cr_revisions.filename%TYPE default null,
  package_id	in acs_objects.package_id%TYPE default null

) return cr_revisions.revision_id%TYPE is

  v_revision_id integer;
  v_package_id acs_objects.package_id%TYPE;
  v_content_type acs_object_types.object_type%TYPE;

begin

  v_content_type := content_item.get_content_type(item_id);

  if package_id is null then
    v_package_id := acs_object.package_id(item_id);
  else
    v_package_id := package_id;
  end if;

  v_revision_id := acs_object.new(
      object_id     => revision_id,
      object_type   => v_content_type,
      title         => title,
      package_id    => v_package_id,
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
  package_id	in acs_objects.package_id%TYPE default null,
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
      package_id    => package_id,
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
    last_modified, modifying_user, modifying_ip,
    title, package_id
  ) ( select 
    v_copy_id, object_type, v_target_item_id, security_inherit_p, 
    copy.creation_user, sysdate, copy.creation_ip,
    sysdate, copy.creation_user, copy.creation_ip,
    title, package_id from
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

create or replace package content_type AUTHID CURRENT_USER as
--/** This package is used to manipulate content types and attributes
--    
--*/

procedure create_type (
  --/** Create a new content type. Automatically create the attribute table
  --    for the type if the table does not already exist.
  --    @author Karl Goldstein
  --    @param content_type  The name of the new type
  --    @param supertype     The supertype, defaults to content_revision
  --    @param pretty_name   Pretty name for the type, singular
  --    @param pretty_plural Pretty name for the type, plural
  --    @param table_name    The name for the attribute table, defaults to
  --                         the name of the supertype
  --    @param id_column     The primary key for the table, defaults to 'XXX'
  --    @param name_method   As in <tt>acs_object_type.create_type</tt>
  --    @see {acs_object_type.create_type}
  --*/
  content_type		in acs_object_types.object_type%TYPE,
  supertype		in acs_object_types.object_type%TYPE 
                           default 'content_revision',
  pretty_name		in acs_object_types.pretty_name%TYPE,
  pretty_plural	        in acs_object_types.pretty_plural%TYPE,
  table_name		in acs_object_types.table_name%TYPE default null,
  id_column		in acs_object_types.id_column%TYPE default 'XXX',
  name_method           in acs_object_types.name_method%TYPE default null
);

procedure drop_type (
  --/** First drops all attributes related to a specific type, then drops type
  --    the given type.
  --    @author Simon Huynh
  --    @param content_type  The content type to be dropped
  --    @param drop_children_p If 't', then the sub-types
  --    of the given content type and their associated tables
  --    are also dropped.
  --*/
  content_type		in acs_object_types.object_type%TYPE,
  drop_children_p	in char default 'f',
  drop_table_p		in char default 'f'

);


function create_attribute (
  --/** Create a new attribute for the specified type. Automatically create
  --    the column for the attribute if the column does not already exist.
  --    @author Karl Goldstein
  --    @param content_type   The name of the type to alter
  --    @param attribute_name The name of the attribute to create
  --    @param pretty_name    Pretty name for the new attribute, singular
  --    @param pretty_plural  Pretty name for the new attribute, plural
  --    @param default_value  The default value for the attribute, defaults to null
  --    @return The id of the newly created attribute
  --    @see {acs_object_type.create_attribute}, {content_type.create_type}
  --*/
  content_type		in acs_attributes.object_type%TYPE,
  attribute_name	in acs_attributes.attribute_name%TYPE,
  datatype		in acs_attributes.datatype%TYPE,
  pretty_name		in acs_attributes.pretty_name%TYPE,
  pretty_plural	in acs_attributes.pretty_plural%TYPE default null,
  sort_order		in acs_attributes.sort_order%TYPE default null,
  default_value	in acs_attributes.default_value%TYPE default null,
  column_spec           in varchar2  default 'varchar2(4000)'
) return acs_attributes.attribute_id%TYPE;

procedure drop_attribute (
  --/** Drop an existing attribute. If you are using CMS, make sure to
  --    call <tt>cm_form_widget.unregister_attribute_widget</tt> before calling
  --    this function.
  --    @author Karl Goldstein
  --    @param content_type   The name of the type to alter
  --    @param attribute_name The name of the attribute to drop
  --    @param drop_column    If 't', will also alter the table and remove
  --         the column where the attribute is stored. The default is 'f'
  --         (leaves the table untouched).
  --    @see {acs_object.drop_attribute}, {content_type.create_attribute},
  --         {cm_form_widget.unregister_attribute_widget}
  --*/
  content_type		in acs_attributes.object_type%TYPE,
  attribute_name	in acs_attributes.attribute_name%TYPE,
  drop_column           in varchar2 default 'f'
);

procedure register_template (
  --/** Register a template for the content type. This template may be used
  --    to render all items of that type.
  --    @author Karl Goldstein
  --    @param content_type  The type for which the template is to be registered
  --    @param template_id   The ID of the template to register
  --    @param use_context   The context in which the template is appropriate, such
  --                         as 'admin' or 'public'
  --    @param is_default    If 't', this template becomes the default template for
  --                         the type, default is 'f'.
  --    @see {content_item.register_template}, {content_item.unregister_template}, 
  --         {content_item.get_template}, {content_type.unregister_template},
  --         {content_type.set_default_template}, {content_type.get_template}
  --*/
  content_type  in cr_type_template_map.content_type%TYPE,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE,
  is_default    in cr_type_template_map.is_default%TYPE default 'f'
);

procedure set_default_template (
  --/** Make the registered template a default template. The default template
  --    will be used to render all items of the type for which no individual
  --    template is registered.
  --    @author Karl Goldstein
  --    @param content_type  The type for which the template is to be made default
  --    @param template_id   The ID of the template to make default
  --    @param use_context   The context in which the template is appropriate, such
  --                         as 'admin' or 'public'
  --    @see {content_item.register_template}, {content_item.unregister_template}, 
  --         {content_item.get_template}, {content_type.unregister_template},
  --         {content_type.register_template}, {content_type.get_template}
  --*/
  content_type  in cr_type_template_map.content_type%TYPE,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE
);

function get_template (
  --/** Retrieve the appropriate template for rendering items of the specified type.
  --    @author Karl Goldstein
  --    @param content_type  The type for which the template is to be retrieved
  --    @param use_context   The context in which the template is appropriate, such
  --                         as 'admin' or 'public'
  --    @return The ID of the template to use
  --    @see {content_item.register_template}, {content_item.unregister_template}, 
  --         {content_item.get_template}, {content_type.unregister_template},
  --         {content_type.register_template}, {content_type.set_default_template}
  --*/
  content_type  in cr_type_template_map.content_type%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE
) return cr_templates.template_id%TYPE;

procedure unregister_template (
  --/** Unregister a template.  If the unregistered template was the default template,
  --    the content_type can no longer be rendered in the use_context,
  --    @author Karl Goldstein
  --    @param content_type  The type for which the template is to be unregistered
  --    @param template_id   The ID of the template to unregister
  --    @param use_context   The context in which the template is to be unregistered
  --    @see {content_item.register_template}, {content_item.unregister_template}, 
  --         {content_item.get_template}, {content_type.set_default_template},
  --         {content_type.register_template}, {content_type.get_template}
  --*/
  content_type  in cr_type_template_map.content_type%TYPE default null,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE default null
);

procedure refresh_view (
  --/** Create a view for the type which joins all attributes of the type, 
  --    including the inherited attributes.  The view is named 
  --    "<table name for content_type>X"
  --    Called by create_attribute and create_type.
  --    @author Karl Goldstein
  --    @param content_type  The type for which the view is to be created.
  --    @see {content_type.create_type}
  --*/
  content_type  in cr_type_template_map.content_type%TYPE
);

procedure register_relation_type (
  --/** Register a relationship between a content type and another object
  --    type.  This may then be used by the content_item.is_valid_relation
  --    function to validate any relationship between an item and another
  --    object.
  --    @author Karl Goldstein
  --    @param content_type  The type of the item from which the relationship
  --                          originated.
  --    @param target_type   The type of the item to which the relationship
  --                          is targeted.
  --    @param relation_tag  A simple token used to identify a set of
  --                          relations.
  --    @param min_n          The minimun number of relationships of this type
  --                          which an item must have to go live.
  --    @param max_n          The minimun number of relationships of this type
  --                          which an item must have to go live.
  --    @see {content_type.unregister_relation_type}
  --*/
  content_type  in cr_type_relations.content_type%TYPE,
  target_type   in cr_type_relations.target_type%TYPE,
  relation_tag  in cr_type_relations.relation_tag%TYPE default 'generic',
  min_n         in integer default 0,
  max_n         in integer default null
);

procedure unregister_relation_type (
  --/** Unregister a relationship between a content type and another object
  --    type.
  --    @author Karl Goldstein
  --    @param content_type  The type of the item from which the relationship
  --                          originated.
  --    @param target_type   The type of the item to which the relationship
  --                          is targeted.
  --    @param relation_tag  A simple token used to identify a set of
  --                          relations.
  --    @see {content_type.register_relation_type}
  --*/
  content_type in cr_type_relations.content_type%TYPE,
  target_type  in cr_type_relations.target_type%TYPE,
  relation_tag in cr_type_relations.relation_tag%TYPE default null
);

procedure register_child_type (
  --/** Register a parent-child relationship between a content type
  --    and another object
  --    type.  This may then be used by the content_item.is_valid_relation
  --    function to validate the relationship between an item and a potential
  --    child.
  --    @author Karl Goldstein
  --    @param content_type  The type of the item from which the relationship
  --                          originated.
  --    @param child_type    The type of the child item.
  --    @param relation_tag  A simple token used to identify a set of
  --                          relations.
  --    @param min_n         The minimun number of parent-child
  --                          relationships of this type
  --                          which an item must have to go live.
  --    @param max_n         The minimun number of relationships of this type
  --                          which an item must have to go live.
  --    @see {content_type.register_relation_type}, {content_type.register_child_type}
  --*/
  parent_type  in cr_type_children.parent_type%TYPE,
  child_type    in cr_type_children.child_type%TYPE,
  relation_tag  in cr_type_children.relation_tag%TYPE default 'generic',
  min_n         in integer default 0,
  max_n         in integer default null
);

procedure unregister_child_type (
  --/** Register a parent-child relationship between a content type
  --    and another object
  --    type.  This may then be used by the content_item.is_valid_relation
  --    function to validate the relationship between an item and a potential
  --    child.
  --    @author Karl Goldstein
  --    @param parent_type   The type of the parent item.
  --    @param child_type    The type of the child item.
  --    @param relation_tag  A simple token used to identify a set of
  --                          relations.
  --    @see {content_type.register_relation_type}, {content_type.register_child_type}
  --*/
  parent_type  in cr_type_children.parent_type%TYPE,
  child_type   in cr_type_children.child_type%TYPE,
  relation_tag in cr_type_children.relation_tag%TYPE default null
);

procedure register_mime_type (
  content_type  in cr_content_mime_type_map.content_type%TYPE,
  mime_type	in cr_content_mime_type_map.mime_type%TYPE
);

procedure unregister_mime_type (
  content_type  in cr_content_mime_type_map.content_type%TYPE,
  mime_type	in cr_content_mime_type_map.mime_type%TYPE
);

function is_content_type (
  object_type   in acs_object_types.object_type%TYPE
) return char;

procedure rotate_template (
  --/** Sets the default template for a content type and registers all the
  --    previously existing items of that content type to the original 
  --    template
  --    @author Michael Pih
  --    @param template_id The template that will become the default 
  --      registered template for the specified content type and use context
  --    @param v_content_type The content type
  --    @param use_context The context in which the template will be used
  --*/
  template_id     in cr_templates.template_id%TYPE,
  v_content_type    in cr_items.content_type%TYPE,
  use_context     in cr_type_template_map.use_context%TYPE
);

-- Create or replace a trigger on insert for simplifying addition of
-- revisions for any content type

procedure refresh_trigger (
  content_type  in acs_object_types.object_type%TYPE
);

end content_type;
/
show errors;

create or replace package body content_type is

procedure create_type (
    content_type	in acs_object_types.object_type%TYPE,
    supertype		in acs_object_types.object_type%TYPE 
                           default 'content_revision',
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    table_name		in acs_object_types.table_name%TYPE default null,
    id_column		in acs_object_types.id_column%TYPE default 'XXX',
    name_method           in acs_object_types.name_method%TYPE default null
) is

  table_exists integer;
  v_supertype_table acs_object_types.table_name%TYPE;
  v_count       integer;
begin

  if (supertype != 'content_revision') and (content_type != 'content_revision') then
    select count(*)
    into  v_count
    from  acs_object_type_supertype_map
    where object_type = create_type.supertype
    and   ancestor_type = 'content_revision';

    if v_count = 0 then
        raise_application_error(-20000, 'Content types can only be created as subclasses of content_revision or a derivation thereof. ' || supertype || ' is not a subclass oc content_revision.');
    end if;
  end if;


 -- create the attribute table if not already created

  select decode(count(*),0,0,1) into table_exists from user_tables 
    where table_name = upper(create_type.table_name);

  if table_exists = 0 then
    select table_name into v_supertype_table from acs_object_types
      where object_type = create_type.supertype;

    execute immediate 'create table ' || table_name || ' (' ||
      id_column  || ' integer primary key references ' || 
      v_supertype_table || ')';
  end if;

  acs_object_type.create_type (
    supertype     => create_type.supertype,
    object_type   => create_type.content_type,
    pretty_name   => create_type.pretty_name,
    pretty_plural => create_type.pretty_plural,
    table_name    => create_type.table_name,
    id_column     => create_type.id_column,
    name_method   => create_type.name_method
  );

  refresh_view(content_type);

end create_type;

procedure drop_type (
  content_type		in acs_object_types.object_type%TYPE,
  drop_children_p	in char default 'f',
  drop_table_p		in char default 'f'
) is


  cursor attribute_cur is
    select
      attribute_name
    from
      acs_attributes
    where
      object_type = drop_type.content_type;

  cursor child_type_cur is 
    select 
      object_type
    from 
      acs_object_types
    where
      supertype = drop_type.content_type;
     
  table_exists integer;
  v_table_name varchar2(50);
  is_subclassed_p char;

begin


  -- first we'll rid ourselves of any dependent child types, if any , along with their
  -- own dependent grandchild types
  select 
    decode(count(*),0,'f','t') into is_subclassed_p 
  from 
    acs_object_types 
  where supertype = drop_type.content_type;

  -- this is weak and will probably break;
  -- to remove grand child types, the process will probably
  -- require some sort of querying for drop_type 
  -- methods within the children's packages to make
  -- certain there are no additional unanticipated
  -- restraints preventing a clean drop

  if drop_children_p = 't' and is_subclassed_p = 't' then

    for child_rec in child_type_cur loop
      drop_type( 
        content_type => child_rec.object_type,
	drop_children_p => 't' );
    end loop;

  end if;

  -- now drop all the attributes related to this type
  for attr_row in attribute_cur loop
    drop_attribute(
     content_type => drop_type.content_type,
      attribute_name => attr_row.attribute_name
    );
  end loop;

  -- we'll remove the associated table if it exists
  select 
    decode(count(*),0,0,1) into table_exists 
  from 
    user_tables u, acs_object_types objet
  where 
    objet.object_type = drop_type.content_type and
    u.table_name = upper(objet.table_name);

  if table_exists = 1 and drop_table_p = 't' then
    select 
      table_name into v_table_name 
    from 
      acs_object_types 
    where
      object_type = drop_type.content_type;

    -- drop the input/output views for the type
    -- being dropped.
    -- FIXME: does the trigger get dropped when the 
    -- view is dropped?  This did not exist in the 4.2 release,
    -- and it needs to be tested.

       
    execute immediate 'drop view ' || v_table_name || 'x';
    execute immediate 'drop view ' || v_table_name || 'i';

    execute immediate 'drop table ' || v_table_name;

  end if;

  acs_object_type.drop_type(
    object_type   => drop_type.content_type
  );

end drop_type;


function create_attribute (
  content_type		in acs_attributes.object_type%TYPE,
  attribute_name	in acs_attributes.attribute_name%TYPE,
  datatype		in acs_attributes.datatype%TYPE,
  pretty_name		in acs_attributes.pretty_name%TYPE,
  pretty_plural		in acs_attributes.pretty_plural%TYPE default null,
  sort_order		in acs_attributes.sort_order%TYPE default null,
  default_value		in acs_attributes.default_value%TYPE default null,
  column_spec           in varchar2 default 'varchar2(4000)'
) return acs_attributes.attribute_id%TYPE is

   v_attr_id	acs_attributes.attribute_id%TYPE;
   v_table_name acs_object_types.table_name%TYPE;
   v_column_exists integer;

begin

 -- add the appropriate column to the table
 begin
   select upper(table_name) into v_table_name from acs_object_types
     where object_type = create_attribute.content_type;
 exception when no_data_found then
   raise_application_error(-20000, 'Content type ''' || content_type || 
      ''' does not exist in content_type.create_attribute');
 end;

 select decode(count(*),0,0,1) into v_column_exists from user_tab_columns
   where table_name = v_table_name
   and column_name = upper(attribute_name);

 if v_column_exists = 0 then
   execute immediate 'alter table ' || v_table_name || ' add ' || 
      attribute_name || ' ' || column_spec;
 end if;

 v_attr_id := acs_attribute.create_attribute (
   object_type => create_attribute.content_type,
   attribute_name => create_attribute.attribute_name,
   datatype => create_attribute.datatype,
   pretty_name => create_attribute.pretty_name,
   pretty_plural => create_attribute.pretty_plural,
   sort_order => create_attribute.sort_order,
   default_value => create_attribute.default_value
 );

 refresh_view(content_type);

 return v_attr_id;

end create_attribute;


procedure drop_attribute (
  content_type		in acs_attributes.object_type%TYPE,
  attribute_name	in acs_attributes.attribute_name%TYPE,
  drop_column           in varchar2 default 'f'
)
is
   v_attr_id acs_attributes.attribute_id%TYPE;
   v_table   acs_object_types.table_name%TYPE;
begin

  -- Get attribute information 
  begin
    select 
      upper(t.table_name), a.attribute_id 
    into 
      v_table, v_attr_id
    from 
      acs_object_types t, acs_attributes a
    where 
      t.object_type = drop_attribute.content_type
    and 
      a.object_type = drop_attribute.content_type
    and
      a.attribute_name = drop_attribute.attribute_name;
  exception when no_data_found then
    raise_application_error(-20000, 'Attribute ' || content_type || ':' || 
       attribute_name || ' does not exist in content_type.drop_attribute');
  end;

  -- Drop the attribute
  acs_attribute.drop_attribute(content_type, attribute_name);

  -- Drop the column if necessary
  if drop_column = 't' then
    begin
      execute immediate 'alter table ' || v_table || ' drop column ' ||
	attribute_name;
    exception when others then
      raise_application_error(-20000, 'Unable to drop column ' || 
       v_table || '.' || attribute_name || ' in content_type.drop_attribute');  
    end;
  end if;  

  refresh_view(content_type);

end drop_attribute;

procedure register_template (
  content_type  in cr_type_template_map.content_type%TYPE,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE,
  is_default	in cr_type_template_map.is_default%TYPE default 'f'
) is
  v_template_registered integer;
begin
  select 
    count(*) into v_template_registered
  from
    cr_type_template_map
  where
    content_type = register_template.content_type
  and
    use_context =  register_template.use_context
  and
    template_id =  register_template.template_id;

  -- register the template
  if v_template_registered = 0 then
    insert into cr_type_template_map (
      template_id, content_type, use_context, is_default
    ) values (
      template_id, content_type, use_context, is_default
    );

  -- update the registration status of the template
  else

    -- unset the default template before setting this one as the default
    if register_template.is_default = 't' then
      update cr_type_template_map
        set is_default = 'f'
        where content_type = register_template.content_type
        and use_context = register_template.use_context;
    end if;

    update cr_type_template_map
      set is_default =    register_template.is_default
      where template_id = register_template.template_id
      and content_type =  register_template.content_type
      and use_context =   register_template.use_context;

  end if;
end register_template;


procedure set_default_template (
  content_type  in cr_type_template_map.content_type%TYPE,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE
) is

begin

  update cr_type_template_map
    set is_default = 't'
    where template_id = set_default_template.template_id
    and content_type = set_default_template.content_type
    and use_context = set_default_template.use_context;

  -- make sure there is only one default template for
  --   any given content_type/use_context pair
  update cr_type_template_map
    set is_default = 'f'
    where template_id ^= set_default_template.template_id
    and content_type = set_default_template.content_type
    and use_context = set_default_template.use_context
    and is_default = 't';

end set_default_template;

function get_template (
  content_type  in cr_type_template_map.content_type%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE
) return cr_templates.template_id%TYPE
is
  v_template_id cr_templates.template_id%TYPE;
begin
  select
    template_id
  into
    v_template_id
  from
    cr_type_template_map
  where
    content_type = get_template.content_type
  and
    use_context = get_template.use_context
  and
    is_default = 't';

  return v_template_id;

exception
  when NO_DATA_FOUND then 
    return null;
end get_template;

procedure unregister_template (
  content_type  in cr_type_template_map.content_type%TYPE default null,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE default null
) is
begin

  if unregister_template.use_context is null and 
     unregister_template.content_type is null then

    delete from cr_type_template_map
      where template_id = unregister_template.template_id;

  elsif unregister_template.use_context is null then

    delete from cr_type_template_map
      where template_id = unregister_template.template_id
      and content_type = unregister_template.content_type;

  elsif unregister_template.content_type is null then

    delete from cr_type_template_map
      where template_id = unregister_template.template_id
      and use_context = unregister_template.use_context;

  else

    delete from cr_type_template_map
      where template_id = unregister_template.template_id
      and content_type = unregister_template.content_type
      and use_context = unregister_template.use_context;

  end if;

end unregister_template;

-- Helper function for refresh_trigger (below) to generate the
-- insert statement for a particular content type;

function trigger_insert_statement (
  content_type  in acs_object_types.object_type%TYPE
) return varchar2 is

  v_table_name acs_object_types.table_name%TYPE;
  v_id_column acs_object_types.id_column%TYPE;

  cursor attr_cur is
    select
      attribute_name
    from
      acs_attributes
    where
      object_type = trigger_insert_statement.content_type;

  cols varchar2(2000) := '';
  vals varchar2(2000) := '';

begin

  select table_name, id_column into v_table_name, v_id_column
  from acs_object_types where 
    object_type = trigger_insert_statement.content_type;

  for attr_rec in attr_cur loop
    cols := cols || ', ' || attr_rec.attribute_name;
    vals := vals || ', :new.' || attr_rec.attribute_name;
  end loop;

  return 'insert into ' || v_table_name || 
    ' ( ' || v_id_column || cols || ' ) values ( new_revision_id' ||
    vals || ')';
  
end trigger_insert_statement;

-- Create or replace a trigger on insert for simplifying addition of
-- revisions for any content type

procedure refresh_trigger (
  content_type  in acs_object_types.object_type%TYPE
) is

  tr_text varchar2(10000) := '';
  v_table_name acs_object_types.table_name%TYPE;

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
      object_type = refresh_trigger.content_type
    order by
      level desc;

begin

  -- get the table name for the content type (determines view name)

  select table_name into v_table_name
  from acs_object_types where object_type = refresh_trigger.content_type;

  -- start building trigger code

  tr_text := '

create or replace trigger ' || v_table_name || 't 
  instead of insert on ' || v_table_name || 'i 
  for each row 
declare
  new_revision_id integer;
begin

  if :new.item_id is null then
    raise_application_error(-20000, ''item_id is required when inserting into ' || 
    v_table_name || 'i '');
  end if;

  if :new.text is not null then

    new_revision_id := content_revision.new(
                   revision_id   => :new.revision_id,
                   title         => :new.title,
                   description   => :new.description,
                   mime_type     => :new.mime_type,
                   nls_language  => :new.nls_language,
                   item_id       => content_symlink.resolve(:new.item_id),
                   creation_ip   => :new.creation_ip,
                   creation_user => :new.creation_user, 
                   text          => :new.text,
                   package_id    => :new.object_package_id
    );

  else

    new_revision_id := content_revision.new(
                   revision_id   => :new.revision_id,
                   title         => :new.title,
                   description   => :new.description,
                   mime_type     => :new.mime_type,
                   nls_language  => :new.nls_language,
                   item_id       => content_symlink.resolve(:new.item_id),
                   creation_ip   => :new.creation_ip,
                   creation_user => :new.creation_user, 
                   data          => :new.data,
                   package_id    => :new.object_package_id
    );

  end if;';

  -- add an insert statement for each subtype in the hierarchy for this type

  for type_rec in type_cur loop
    tr_text := tr_text || '
' || trigger_insert_statement(type_rec.object_type) || ';
';

  end loop;

  -- end building the trigger code
  tr_text := tr_text || '
end ' || v_table_name || 't;';

  -- (Re)create the trigger
  execute immediate tr_text;

end refresh_trigger;

-- Create or replace a view joining all attribute tables

procedure refresh_view (
  content_type  in cr_type_template_map.content_type%TYPE
) is

  -- exclude the BLOB column because it will make it impossible
  -- to do a select *

  cursor join_cur is
    select
      distinct lower(table_name) as table_name,
      id_column, level
    from
      acs_object_types
    where
      object_type <> 'acs_object'
    and
      object_type <> 'content_revision'
    and lower(table_name) <> 'acs_objects'
    and lower(table_name) <> 'cr_revisions'
    start with
      object_type = refresh_view.content_type
    connect by
      object_type = prior supertype;

  cols varchar2(1000);
  tabs varchar2(1000);
  joins varchar2(1000) := '';
 
  v_table_name varchar2(40);

begin

  for join_rec in join_cur loop

    cols := cols || ', ' || join_rec.table_name || '.*';
    tabs := tabs || ', ' || join_rec.table_name;
    joins := joins || ' and acs_objects.object_id = ' || 
             join_rec.table_name || '.' || join_rec.id_column;

  end loop;

  select table_name into v_table_name from acs_object_types
    where object_type = content_type;

  -- create the input view (includes content columns)

  execute immediate 'create or replace view ' || v_table_name ||
    'i as select acs_objects.object_id,
 acs_objects.object_type,
 acs_objects.title as object_title,
 acs_objects.package_id as object_package_id,
 acs_objects.context_id,
 acs_objects.security_inherit_p,
 acs_objects.creation_user,
 acs_objects.creation_date,
 acs_objects.creation_ip,
 acs_objects.last_modified,
 acs_objects.modifying_user,
 acs_objects.modifying_ip,
 cr.revision_id, cr.title, cr.item_id,
    cr.content as data, cr_text.text,
    cr.description, cr.publish_date, cr.mime_type, cr.nls_language' || 
    cols || 
    ' from acs_objects, cr_revisions cr, cr_text' || tabs || ' where 
    acs_objects.object_id = cr.revision_id ' || joins;

  -- create the output view (excludes content columns to enable SELECT *)

  execute immediate 'create or replace view ' || v_table_name ||
    'x as select acs_objects.object_id,
 acs_objects.object_type,
 acs_objects.title as object_title,
 acs_objects.package_id as object_package_id,
 acs_objects.context_id,
 acs_objects.security_inherit_p,
 acs_objects.creation_user,
 acs_objects.creation_date,
 acs_objects.creation_ip,
 acs_objects.last_modified,
 acs_objects.modifying_user,
 acs_objects.modifying_ip,
 cr.revision_id, cr.title, cr.item_id,
    cr.description, cr.publish_date, cr.mime_type, cr.nls_language,
    i.name, i.parent_id' || 
    cols || 
    ' from acs_objects, cr_revisions cr, cr_items i, cr_text' || tabs || 
    ' where acs_objects.object_id = cr.revision_id 
      and cr.item_id = i.item_id' || joins;

  refresh_trigger(content_type);

exception
  when others then
    dbms_output.put_line('Error creating attribute view or trigger for ' ||
                         content_type);
end refresh_view;

procedure register_child_type (
  parent_type  in cr_type_children.parent_type%TYPE,
  child_type    in cr_type_children.child_type%TYPE,
  relation_tag  in cr_type_children.relation_tag%TYPE default 'generic',
  min_n         in integer default 0,
  max_n         in integer default null
) is

  v_exists integer;

begin

  select decode(count(*),0,0,1) into v_exists 
    from cr_type_children
    where parent_type = register_child_type.parent_type
    and child_type = register_child_type.child_type
    and relation_tag = register_child_type.relation_tag;

  if v_exists = 0 then

    insert into cr_type_children (
      parent_type, child_type, relation_tag, min_n, max_n
    ) values (
      parent_type, child_type, relation_tag, min_n, max_n
    );

  else

    update cr_type_children set
      min_n = register_child_type.min_n,
      max_n = register_child_type.max_n
    where 
      parent_type = register_child_type.parent_type
    and 
      child_type = register_child_type.child_type
    and
      relation_tag = register_child_type.relation_tag;

  end if;
      
end register_child_type;

procedure unregister_child_type (
  parent_type  in cr_type_children.parent_type%TYPE,
  child_type   in cr_type_children.child_type%TYPE,
  relation_tag in cr_type_children.relation_tag%TYPE default null
) is

begin

  delete from 
    cr_type_children
  where 
    parent_type = unregister_child_type.parent_type
  and 
    child_type = unregister_child_type.child_type
  and
    relation_tag = unregister_child_type.relation_tag;

end unregister_child_type;

procedure register_relation_type (
  content_type  in cr_type_relations.content_type%TYPE,
  target_type   in cr_type_relations.target_type%TYPE,
  relation_tag  in cr_type_relations.relation_tag%TYPE default 'generic',
  min_n         in integer default 0,
  max_n         in integer default null
) is
  v_exists integer;
begin

  -- check if the relation type exists
  select 
    decode(count(*),0,0,1) into v_exists 
  from 
    cr_type_relations
  where 
    content_type = register_relation_type.content_type
  and
    target_type = register_relation_type.target_type
  and 
    relation_tag = register_relation_type.relation_tag;

  -- if the relation type does not exist, insert a row into cr_type_relations
  if v_exists = 0 then
    insert into cr_type_relations (
      content_type, target_type, relation_tag, min_n, max_n
    ) values (
      content_type, target_type, relation_tag, min_n, max_n
    );

  -- otherwise, update the row in cr_type_relations
  else
    update cr_type_relations set
      min_n = register_relation_type.min_n,
      max_n = register_relation_type.max_n
    where 
      content_type = register_relation_type.content_type
    and 
      target_type = register_relation_type.target_type
    and
      relation_tag = register_relation_type.relation_tag;

  end if;
end register_relation_type;

procedure unregister_relation_type (
  content_type in cr_type_relations.content_type%TYPE,
  target_type   in cr_type_relations.target_type%TYPE,
  relation_tag in cr_type_relations.relation_tag%TYPE default null
) is

begin

  delete from 
    cr_type_relations
  where 
    content_type = unregister_relation_type.content_type
  and 
    target_type = unregister_relation_type.target_type
  and
    relation_tag = unregister_relation_type.relation_tag;

end unregister_relation_type;

procedure register_mime_type (
  content_type  in cr_content_mime_type_map.content_type%TYPE,
  mime_type	in cr_content_mime_type_map.mime_type%TYPE
) is 
  v_valid_registration  integer;
begin

  -- check if this type is already registered  
  select
    count(*) into v_valid_registration
  from 
    cr_mime_types
  where 
    not exists ( select 1
                 from
	           cr_content_mime_type_map
                 where
                   mime_type = register_mime_type.mime_type
                 and
                   content_type = register_mime_type.content_type )
  and
    mime_type = register_mime_type.mime_type;

  if v_valid_registration = 1 then
    
    insert into cr_content_mime_type_map (
      content_type, mime_type
    ) values (
      register_mime_type.content_type, register_mime_type.mime_type
    );

  end if;

end register_mime_type;


procedure unregister_mime_type (
  content_type  in cr_content_mime_type_map.content_type%TYPE,
  mime_type	in cr_content_mime_type_map.mime_type%TYPE
) is
begin

  delete from cr_content_mime_type_map
    where content_type = unregister_mime_type.content_type
    and mime_type = unregister_mime_type.mime_type;

end unregister_mime_type;

function is_content_type (
  object_type   in acs_object_types.object_type%TYPE
) return char is

  v_is_content_type char(1) := 'f';

begin

  if object_type = 'content_revision' then

    v_is_content_type := 't';

  else
    
    select decode(count(*),0,'f','t') into v_is_content_type
    from acs_object_type_supertype_map
    where object_type = is_content_type.object_type 
    and ancestor_type = 'content_revision';

  end if;
  
  return v_is_content_type;

end is_content_type;



procedure rotate_template ( 
  template_id       in cr_templates.template_id%TYPE,
  v_content_type    in cr_items.content_type%TYPE,
  use_context       in cr_type_template_map.use_context%TYPE
) is
  v_template_id cr_templates.template_id%TYPE;

  -- items that have an associated default template but not at the item level
  cursor c_items_cursor is
    select
      item_id
    from
      cr_items i, cr_type_template_map m
    where
      i.content_type = rotate_template.v_content_type
    and
      m.use_context = rotate_template.use_context
    and
      i.content_type = m.content_type
    and
      not exists ( select 1
                   from
                     cr_item_template_map
                   where
                     item_id = i.item_id
                   and
                     use_context = rotate_template.use_context );
begin

  -- get the default template
  select
    template_id into v_template_id
  from
    cr_type_template_map
  where
    content_type = rotate_template.v_content_type
  and
    use_context = rotate_template.use_context
  and
    is_default = 't';

  if v_template_id is not null then

    -- register an item-template to all items without an item-template
    for v_items_val in c_items_cursor loop

      content_item.register_template ( 
         item_id     => v_items_val.item_id, 
         template_id => v_template_id,
         use_context => rotate_template.use_context
      );
    end loop;
  end if;

  -- register the new template as the default template of the content type
  if v_template_id ^= rotate_template.template_id then
    content_type.register_template(
        content_type => rotate_template.v_content_type,
        template_id  => rotate_template.template_id,
        use_context  => rotate_template.use_context,
        is_default   => 't'
    );
  end if;

end rotate_template;


end content_type;
/
show errors

-- Refresh the attribute triggers

begin

  for type_rec in (select object_type,table_name from acs_object_types
    connect by supertype = prior object_type 
    start with object_type = 'content_revision') loop
        if table_exists(type_rec.table_name) then
            content_type.refresh_view(type_rec.object_type);
        end if; 
  end loop;

end;
/
show errors;
