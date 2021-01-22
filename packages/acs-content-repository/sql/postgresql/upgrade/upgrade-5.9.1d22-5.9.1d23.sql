--
-- Reduced generation of dead tuples in postgres.
--
-- Background: In the old version, the fields latest and live
-- revisions were updated always via two separate DML statements.
-- Every update causes in PostgreSQL (tested against pg 9.6) one more
-- dead tuple, such that on busy systems, we see 30k + dead tuples per
-- hour. These dead tuples in turn cause more auto vacuum operations
-- and can lead to abandoned query plans.
--
-- This change can reduce the number of dead tuples on cr_items into
-- half, by allowing both fields to be set in one operation (namely
-- content_item__set_live_revision). This function has an optional 4th
-- argument that can cause this optimization. For legacy applications,
-- nothing changes.
--
-- Btw: since all commonly used applications use the live revision, the
-- fallback of the latest_revision is unused. One can consider to
-- remove the cr_revision_latest_tr, at least on on certain
-- installations.
--
-- GN


DROP FUNCTION IF EXISTS content_item__set_live_revision(integer, character varying, timestamp with time zone);

select define_function_args('content_item__set_live_revision','revision_id,publish_status;ready,publish_date;now(),is_latest;f');
--
-- procedure content_item__set_live_revision/1..4
--
CREATE OR REPLACE FUNCTION content_item__set_live_revision(
   p__revision_id integer,
   p__publish_status varchar default 'ready',
   p__publish_date timestamptz default now(),
   p__is_latest boolean default false
) RETURNS integer AS $$
DECLARE
BEGIN

  if p__is_latest then
    update cr_items
      set
            live_revision = p__revision_id,
    	    publish_status = p__publish_status,
            latest_revision = p__revision_id   
      where
	    item_id = (select item_id
               from   cr_revisions
               where  revision_id = p__revision_id);
  else
    update cr_items
      set
            live_revision = p__revision_id,
    	    publish_status = p__publish_status
      where
	    item_id = (select item_id
               from   cr_revisions
               where  revision_id = p__revision_id);
  end if;
   
  update cr_revisions
  set
    publish_date = p__publish_date
  where
    revision_id = p__revision_id;

  return 0; 
END;
$$ LANGUAGE plpgsql;


--
-- Trigger to maintain latest_revision in cr_items
--
CREATE OR REPLACE FUNCTION cr_revision_latest_tr () RETURNS trigger AS $$
DECLARE
  v_latest_revision      cr_revisions.revision_id%TYPE;
BEGIN

  select latest_revision from cr_items into v_latest_revision where item_id = new.item_id;

  if v_latest_revision <> new.revision_id then
     update cr_items set latest_revision = new.revision_id
     where item_id = new.item_id;
  end if;
  
  return new;
END;
$$ LANGUAGE plpgsql;

