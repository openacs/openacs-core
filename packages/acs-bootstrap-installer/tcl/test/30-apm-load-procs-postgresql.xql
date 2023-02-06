<?xml version="1.0"?>

<queryset>
  <rdbms><type>postgresql</type><version>11</version></rdbms>

  <fullquery name="test::acs_bootstrap_installer::db_map.full_query_1">
    <querytext>
      select '$dollar_value' as d,
             :bind_value as b
             [string length a] as c
    </querytext>
  </fullquery>

  <partialquery name="test::acs_bootstrap_installer::db_map.partial_query_1">
    <querytext>
      limit 1
    </querytext>
  </partialquery>

</queryset>
