------------------------------------------------------------
-- Set up an index with INSO filtering on the content column
------------------------------------------------------------

set serveroutput on

declare
  v_exists integer;
begin

  -- Check whether the preference already exists
  select decode(count(*),0,0,1) into v_exists from ctx_user_preferences
    where pre_name = 'CONTENT_FILTER_PREF';

  if v_exists = 0 then

    dbms_output.put_line('Creating content filter preference...');

    ctx_ddl.create_preference
      (
	preference_name => 'CONTENT_FILTER_PREF',
	object_name     => 'INSO_FILTER'
      );

  end if;

end;
/

create index cr_rev_content_index on cr_revisions ( content )
  indextype is ctxsys.context
  parameters ('FILTER content_filter_pref' );

-- DRB: Use the "online" version if you have Oracle Enterprise Edition
-- alter index cr_rev_content_index rebuild online parameters ('sync');
alter index cr_rev_content_index rebuild  parameters ('sync');

------------------------------------------------------------
-- Set up an XML index for searching attributes
------------------------------------------------------------

-- To find the word company in the title only:

-- select revision_id,score(1) 
-- from cr_revision_attributes
-- where contains(attributes, 'company WITHIN title', 1) > 0;

-- use a direct datastore rather than setting up a user datastore
-- this avoids having to generate an XML document for every
-- revision every time the index is rebuilt.  It also avoids the
-- cumbersome manual process of setting up a user datastore.

create or replace package content_search is

  procedure update_attribute_index;

end content_search;
/
show errors

create or replace package body content_search is

procedure update_attribute_index is
begin

  for c1 in (select revision_id from cr_revisions r where not exists (
    select 1 from cr_revision_attributes a 
      where a.revision_id = r.revision_id)) loop

    content_revision.index_attributes(c1.revision_id);
    commit;

  end loop;

end update_attribute_index;

end;
/
show errors

declare
  v_exists integer;
begin

  -- Check whether the section group already exists
  select decode(count(*),0,0,1) into v_exists from ctx_user_section_groups
    where sgp_name = 'AUTO';

  if v_exists = 0 then

    dbms_output.put_line('Creating auto section group for attribute index...');

    ctx_ddl.create_section_group('auto', 'AUTO_SECTION_GROUP');

  end if;
end;
/

create index cr_rev_attribute_index on cr_revision_attributes ( attributes )
  indextype is ctxsys.context
  parameters ('filter ctxsys.null_filter section group auto' );

begin
  content_search.update_attribute_index;
end;
/
show errors

-- DRB: Use the "online" version if you have Oracle Enterprise Edition
-- alter index cr_rev_attribute_index rebuild online parameters ('sync');
alter index cr_rev_attribute_index rebuild parameters ('sync');

