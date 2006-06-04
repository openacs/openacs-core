-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2005-11-29
-- @arch-tag: 2e1f8368-2c55-49fb-9b34-9cd6564288e1
-- @cvs-id $Id$
--

alter table site_nodes_selection drop constraint site_nodes_sel_id_fk;
alter table site_nodes_selection add constraint site_nodes_sel_id_fk foreign key (node_id) references acs_objects(object_id) on delete cascade;
