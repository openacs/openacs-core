<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="segments_exists_p">      
      <querytext>
      
    select case when exists 
                   (select 1 from rel_segments s where s.segment_id <> :segment_id)
           then 1 else 0 end
      from dual

      </querytext>
</fullquery>

 
</queryset>
