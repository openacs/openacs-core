<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rel_segments_new.create_rel_segment">      
      <querytext>
--      FIX ME PLSQL
--      declare
--      begin
                select rel_segment__new(
                        :segment_name,          -- segment_name
                        :group_id,              -- group_id
                        :context_id,            -- context_id
                        :rel_type,              -- rel_type
                        :creation_user,         -- creation_user
                        :creation_ip            -- creation_ip
                                 );
--      end;

      </querytext>
</fullquery>


<fullquery name="rel_segments_delete.constraint_delete">
      <querytext>
--      FIX ME PLSQL
                select rel_segment__delete(:constraint_id);

      </querytext>
</fullquery>


<fullquery name="rel_segments_delete.rel_segment_delete">
      <querytext>
--      FIX ME PLSQL
	        select rel_segment__delete(:segment_id);

      </querytext>
</fullquery>


</queryset>
