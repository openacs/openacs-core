<?xml version="1.0"?>

<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>

  <fullquery name="acs_sc_binding_exists_p.binding_exists_p">
    <querytext>
      select acs_sc_binding__exists_p(:contract,:impl)
    </querytext>
  </fullquery>

</queryset>
