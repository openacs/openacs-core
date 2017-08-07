<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="drop_relationship_type">      
      <querytext>
	select acs_rel_type__drop_type(:rel_type,'t')
      </querytext>
</fullquery>

 
<fullquery name="drop_type_table">      
      <querytext>
        drop table $table_name
      </querytext>
</fullquery>

 
<fullquery name="select_rel_ids">      
      <querytext>
        select r.rel_id
          from acs_rels r
        where acs_permission__permission_p(r.rel_id, :user_id, 'delete')
          and r.rel_type = :rel_type
      </querytext>
</fullquery>

 
<fullquery name="select_segment_id">      
      <querytext>
        select s.segment_id
          from rel_segments s
        where acs_permission__permission_p(s.segment_id, :user_id, 'delete')
          and s.rel_type = :rel_type
      </querytext>
</fullquery>

 
</queryset>
