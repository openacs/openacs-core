-- PATCH 267, BUG 775 Randy O'Meara
-- procedure delete
-- function acs_group_delete in file
-- acs-kernel/sql/postgresql/groups-body-create.sql attempts to delete
-- associated relational segments before removing any active relations on
-- those segments. The group delete request is not successful and the
-- following error is returned.
-- ERROR:  party_member_party_fk referential integrity violation - key in
--   parties still referenced from party_approved_member_map
--

create or replace function acs_group__delete (integer)
returns integer as '
declare
  delete__group_id              alias for $1;  
  row                           record;
begin
 
   -- Delete all the relations of any type to this group
   for row in select r.rel_id, t.package_name
                 from acs_rels r, acs_object_types t
                where r.rel_type = t.object_type
                  and (r.object_id_one = delete__group_id
                       or r.object_id_two = delete__group_id) 
   LOOP
      execute ''select '' ||  row.package_name || ''__delete('' || row.rel_id || '')'';
   end loop;
 
   -- Delete all segments defined for this group
   for row in  select segment_id 
                 from rel_segments 
                where group_id = delete__group_id 
   LOOP
       PERFORM rel_segment__delete(row.segment_id);
   end loop;

   PERFORM party__delete(delete__group_id);

   return 0; 
end;' language 'plpgsql';
