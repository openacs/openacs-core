<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="binding_install">      
      <querytext>
         select acs_sc_binding__new(:contract_id,:impl_id)
      </querytext>
</fullquery>
 
</queryset>

