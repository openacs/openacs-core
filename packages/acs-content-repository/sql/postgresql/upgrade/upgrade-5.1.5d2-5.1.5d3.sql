-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2005-02-27
-- @arch-tag: 0c2560da-f1ba-4fd7-b02d-608cd4d35f47
-- @cvs-id $Id$
--
-- fix bug#2298
create or replace function content_revision__del (integer)
returns integer as '
declare
  delete__revision_id    alias for $1;  
  v_item_id              cr_items.item_id%TYPE;
  v_latest_revision      cr_revisions.revision_id%TYPE;
  v_live_revision        cr_revisions.revision_id%TYPE;
  v_rec                  record;                                      
begin

  -- Get item id and latest/live revisions
  select item_id into v_item_id from cr_revisions 
    where revision_id = delete__revision_id;

  select 
    latest_revision, live_revision
  into 
    v_latest_revision, v_live_revision
  from 
    cr_items
  where 
    item_id = v_item_id;

  -- Recalculate latest revision
  if v_latest_revision = delete__revision_id then
      for v_rec in 
          select r.revision_id
            from cr_revisions r, acs_objects o
           where o.object_id = r.revision_id
             and r.item_id = v_item_id
             and r.revision_id <> delete__revision_id
        order by o.creation_date desc 
      LOOP

          v_latest_revision := v_rec.revision_id;
          exit;
      end LOOP;
      if NOT FOUND then
         v_latest_revision := null;        
      end if;
      
      update cr_items set latest_revision = v_latest_revision
      where item_id = v_item_id;    
  end if; 
 
  -- Clear live revision
  if v_live_revision = delete__revision_id then
    update cr_items set live_revision = null
      where item_id = v_item_id;   
  end if; 

  -- Clear the audit
  delete from cr_item_publish_audit
    where old_revision = delete__revision_id
       or new_revision = delete__revision_id;

  -- Delete the revision
  PERFORM acs_object__delete(delete__revision_id);

  return 0; 
end;' language 'plpgsql';
