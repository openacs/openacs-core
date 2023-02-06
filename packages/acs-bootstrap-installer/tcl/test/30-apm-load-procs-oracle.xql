<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="test::acs_bootstrap_installer::db_map.full_query_1">
    <querytext>
      select '$dollar_value' as d,
             :bind_value as b
             [string length a] as c
      from dual
    </querytext>
  </fullquery>

  <partialquery name="test::acs_bootstrap_installer::db_map.partial_query_1">
    <querytext>
      WHERE ROWNUM <= 1
    </querytext>
  </partialquery>

</queryset>
