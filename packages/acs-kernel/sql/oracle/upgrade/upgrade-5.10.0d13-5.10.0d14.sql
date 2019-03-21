begin;

-- This upgrade is just a stub and should be reviewed/tested before
-- uncommenting

-- update (
--  select i.parent_id, u.user_id
--    from cr_items i
--         users u,
--         acs_rels a
--   where a.object_id_two = i.item_id
--     and a.object_id_one = u.user_id
--     and i.parent_id <> u.user_id
--     and a.rel_type = 'user_portrait_rel'
--     and not exists (select 1 from cr_items ei, acs_rels er
--                      where er.object_id_two = ei.item_id
--                        and er.object_id_one = u.user_id
--                        and er.rel_type = 'user_portrait_rel'
--                        and parent_id = u.user_id)) portraits
--    set portraits.parent_id = portraits.user_id;

-- -- Delete the old broken portraits (optional)
-- select content_item.delete(i.item_id)
--   from cr_items i,
--        users u,
--        acs_rels a
--  where a.object_id_two = i.item_id
--   and a.object_id_one = u.user_id
--   and i.parent_id <> u.user_id
--   and a.rel_type = 'user_portrait_rel';

end;
