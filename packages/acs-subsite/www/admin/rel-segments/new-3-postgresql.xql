<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="segments_exists_p">      
      <querytext>
      
    select case when exists 
                   (select 1 from rel_segments s where s.segment_id <> :segment_id)
           then 1 else 0 end
      

      </querytext>
</fullquery>

 
</queryset>
