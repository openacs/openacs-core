DROP FUNCTION IF EXISTS content_item__set_live_revision(integer);
DROP FUNCTION IF EXISTS content_item__set_live_revision(integer, character varying);

select define_function_args('content_item__set_live_revision','revision_id,publish_status;ready,publish_date;now()');
--
-- procedure content_item__set_live_revision/2
--
CREATE OR REPLACE FUNCTION content_item__set_live_revision(
   set_live_revision__revision_id integer,
   set_live_revision__publish_status varchar default 'ready',
   set_live_revision__publish_date timestamptz default now()
) RETURNS integer AS $$
DECLARE
BEGIN

  update
    cr_items
  set
    live_revision = set_live_revision__revision_id,
    publish_status = set_live_revision__publish_status
  where
    item_id = (select
                 item_id
               from
                 cr_revisions
               where
                 revision_id = set_live_revision__revision_id);

  update
    cr_revisions
  set
    publish_date = set_live_revision__publish_date
  where
    revision_id = set_live_revision__revision_id;

  return 0; 
END;
$$ LANGUAGE plpgsql;

