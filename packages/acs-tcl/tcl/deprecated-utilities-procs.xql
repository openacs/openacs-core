<?xml version="1.0"?>
<queryset>

<fullquery name="nmc_GetNewIDNumber.id_number_update">      
      <querytext>
      update id_numbers set :id_name = :id_name + 1
      </querytext>
</fullquery>

 
<fullquery name="nmc_GetNewIDNumber.nmc_getnewidnumber">      
      <querytext>
      select unique :id_name from id_numbers
      </querytext>
</fullquery>

 
</queryset>
