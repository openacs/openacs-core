<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="rel_segments_new.create_rel_segment">      
      <querytext>
      
      declare
      begin 
	:1 := rel_segment.new(segment_name => :segment_name,
                                  group_id => :group_id,
                                  context_id => :context_id,
                                  rel_type => :rel_type,
                                  creation_user => :creation_user,
                                  creation_ip => :creation_ip
                                 );
      end;
    
      </querytext>
</fullquery>

 
<fullquery name="rel_segments_delete.constraint_delete">      
      <querytext>
      
	    begin rel_constraint.del(:constraint_id); end;
	
      </querytext>
</fullquery>

 
<fullquery name="rel_segments_delete.rel_segment_delete">      
      <querytext>
      
	begin rel_segment.del(:segment_id); end;
    
      </querytext>
</fullquery>

 
</queryset>
