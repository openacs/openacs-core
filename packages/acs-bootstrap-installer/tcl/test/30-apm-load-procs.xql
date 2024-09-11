<?xml version="1.0"?>

<queryset>

  <fullquery name="test::acs_bootstrap_installer::db_map.full_query_2">
    <querytext>
      select '$dollar_value' as d,
             :bind_value as b
             [string length a] as c
      from dual as generic
    </querytext>
  </fullquery>

  <partialquery name="test::acs_bootstrap_installer::db_map.partial_query_2">
    <querytext>
      fetch first 1 rows only
    </querytext>
  </partialquery>

</queryset>
