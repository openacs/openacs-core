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
      
  select p.party_id, 
         acs_object.name(p.party_id) || nvl2(p.email, ' ('||p.email||')', '') as name
  from   parties p
  order  by upper(acs_object.name(p.party_id))

      </querytext>
</fullquery>

 
</queryset>
