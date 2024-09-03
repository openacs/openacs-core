--
-- Add revision_id as the second column to order by, as an educated guess in
-- case creation_date is the same.
--
-- This can happen if different revisions were created inside a single
-- transaction.
--

--
-- procedure content_revision__get_number/1
--
CREATE OR REPLACE FUNCTION content_revision__get_number(
   get_number__revision_id integer
) RETURNS integer AS $$
DECLARE
  v_revision                         cr_revisions.revision_id%TYPE;
  v_row_count                        integer default 0;
  rev_cur                            record;
BEGIN
  for rev_cur in select
                   revision_id
                 from
                   cr_revisions r, acs_objects o
                 where
                   item_id = (select item_id from cr_revisions
                               where revision_id = get_number__revision_id)
                 and
                   o.object_id = r.revision_id
                 order by
                   o.creation_date,
                   r.revision_id
  LOOP
    v_row_count := v_row_count + 1;
    if rev_cur.revision_id = get_number__revision_id then
       return v_row_count;
       exit;
    end if;
  end LOOP;

  return null;

END;
$$ LANGUAGE plpgsql stable strict;
