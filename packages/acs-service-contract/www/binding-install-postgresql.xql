<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="binding_install">      
      <querytext>
         select acs_sc_binding__new(cast(:contract_id as integer), cast(:impl_id as integer))
      </querytext>
</fullquery>
 
</queryset>

