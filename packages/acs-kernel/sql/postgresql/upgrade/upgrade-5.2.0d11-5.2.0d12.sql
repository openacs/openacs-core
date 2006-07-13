-- 
-- 
-- 
-- @author Victor Guerra (guerra@galileo.edu)
-- @creation-date 2006-07-13
-- @arch-tag: a071e695-59ef-45b2-9705-db1df5a80410
-- @cvs-id $Id$
--

-- renaming upgrade script, original script: upgrade-5.1.5-5.2.0a1.sql

-- procedure merge
create or replace function membership_rel__merge (integer)
returns integer as '
declare
  merge__rel_id                alias for $1;  
begin
    update membership_rels
    set member_state = ''merged''
    where rel_id = merge__rel_id;

    return 0; 
end;' language 'plpgsql';


alter table membership_rels drop constraint membership_rel_mem_ck;

alter table membership_rels add constraint membership_rel_mem_ck check (member_state in ('approved','needs approval','banned','rejected','deleted','merged'));
