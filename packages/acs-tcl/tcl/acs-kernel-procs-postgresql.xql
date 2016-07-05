<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="ad_acs_require_basic_schemata.has_schema">      
  <querytext>
    SELECT exists (
       SELECT 1 FROM information_schema.schemata
       WHERE schema_name = :schema_name
    )
  </querytext>
</fullquery>


</queryset>
