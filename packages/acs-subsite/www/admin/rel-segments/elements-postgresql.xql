<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_segment_info">      
      <querytext>
      
    select s.segment_name, s.group_id,
           acs_rel_type__role_pretty_plural(r.role_two) as role_pretty_plural
      from rel_segments s, acs_rel_types r
     where s.segment_id = :segment_id
       and s.rel_type = r.rel_type

      </querytext>
</fullquery>

 
</queryset>
