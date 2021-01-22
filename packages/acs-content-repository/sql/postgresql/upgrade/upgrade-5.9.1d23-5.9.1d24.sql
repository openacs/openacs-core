--
-- Fix of change from d22-23 to add NULL value handling to deal with
-- older applications such as assement (many thanks to Guenter Ernst).
--
-- GN


--
-- Trigger to maintain latest_revision in cr_items
--
CREATE OR REPLACE FUNCTION cr_revision_latest_tr () RETURNS trigger AS $$
DECLARE
  v_latest_revision      cr_revisions.revision_id%TYPE;
BEGIN

  select latest_revision from cr_items into v_latest_revision where item_id = new.item_id;

  if v_latest_revision IS NULL or v_latest_revision <> new.revision_id then
     update cr_items set latest_revision = new.revision_id
     where item_id = new.item_id;
  end if;
  
  return new;
END;
$$ LANGUAGE plpgsql;

