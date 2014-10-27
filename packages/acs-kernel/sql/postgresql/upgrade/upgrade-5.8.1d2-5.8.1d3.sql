CREATE OR REPLACE FUNCTION acs_group__delete(
   delete__group_id integer
) RETURNS integer AS $$
DECLARE
  row                           record;
BEGIN
 
   -- Delete all the relations of any type to this group
   for row in select r.rel_id, t.package_name
                 from acs_rels r, acs_object_types t
                where r.rel_type = t.object_type
                  and (r.object_id_one = delete__group_id
                       or r.object_id_two = delete__group_id) 
   LOOP
      execute 'select ' ||  row.package_name || '__delete(' || row.rel_id || ')';
   end loop;
 
   -- Delete all segments defined for this group
   for row in  select segment_id 
                 from rel_segments 
                where group_id = delete__group_id 
   LOOP
       PERFORM rel_segment__delete(row.segment_id);
   end loop;

   --Lets clear the groups table first
   delete from groups
   where group_id = delete__group_id;

   PERFORM party__delete(delete__group_id);

   return 0; 
END;
$$ LANGUAGE plpgsql;
