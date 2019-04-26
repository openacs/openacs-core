begin;

-- Rename old portraits saved in the past as not children of their
-- respective user_id
update cr_items set
       name = name || '-old'
  where item_id in (
     select i.item_id
       from cr_items i,
            users u,
            acs_rels a
      where a.object_id_two = i.item_id
       and a.object_id_one = u.user_id
       and i.parent_id <> u.user_id
       and a.rel_type = 'user_portrait_rel'
       and i.name like 'portrait-of-user-%'
       and i.name not like '%-old'
  );

end;
