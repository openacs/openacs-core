<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="binding_install">      
      <querytext>
         begin
           acs_sc_binding.new(
             contract_id => :contract_id,
             impl_id => :impl_id);
         end;
      </querytext>
</fullquery>

 
</queryset>
