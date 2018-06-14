<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="acs_sc_binding_exists_p.binding_exists_p">
    <querytext>
      select acs_sc_binding.exists_p(:contract,:impl) from dual
    </querytext>
  </fullquery>
  
</queryset>
