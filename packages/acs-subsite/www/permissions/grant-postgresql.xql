<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="name">      
      <querytext>
      select acs_object__name(:object_id) 
      </querytext>
</fullquery>

 
<fullquery name="parties">      
      <querytext>
      
  select p.party_id, 
         acs_object__name(p.party_id)|| coalesce(' ('||p.email||')', '') as name
  from   parties p
  order  by upper(acs_object__name(p.party_id))

      </querytext>
</fullquery>

 
</queryset>
