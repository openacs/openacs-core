<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="name">      
      <querytext>
      select acs_object.name(:object_id) from dual
      </querytext>
</fullquery>

 
<fullquery name="parties">      
      <querytext>
      
  select party_id, acs_object.name(party_id) as name
  from parties

      </querytext>
</fullquery>

 
</queryset>
