--
-- Fix of change from d23-24 since trigger was fired too early (at
-- least for main usages)
--

--
-- Trigger to maintain latest_revision in cr_items
--
CREATE OR REPLACE FUNCTION cr_revision_latest_tr () RETURNS trigger AS $$
DECLARE
  v_content_type      cr_items.content_type%TYPE;
BEGIN

  select content_type from cr_items into v_content_type where item_id = new.item_id;
  --
  -- Don't set the latest revision via trigger, since other means in
  -- the xotcl-core frame work take care for it. This is not the most
  -- general solution, but improves the situation for busy sites.
  --
  if substring(v_content_type,1,2) != '::' then
     update cr_items set latest_revision = new.revision_id
     where item_id = new.item_id;
  end if;
  
  return new;
END;
$$ LANGUAGE plpgsql;

