--
-- @author Lars Pind (lars@collaboraid.biz)
-- @creation-date 2003-07-03
-- 
-- Add 'admin_rel' as a permissible relationship type for application groups
--


-- Add 'admin_rel' as a permissible relationship type for application groups

insert into group_type_rels
(group_rel_type_id, group_type, rel_type)
values
(acs_object_id_seq.nextval, 'application_group', 'admin_rel');


-- Then add it to all existing application groups

insert into group_rels
    (group_rel_id, group_id, rel_type)
select nextval('t_acs_object_id_seq'), group_id, 'admin_rel'
from   groups g, acs_objects o
where  o.object_id = g.group_id
and    o.object_type = 'application_group';



