<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
 
<fullquery name="acs-automated-testing.results_query">
  <querytext>
    select testcase_id, package_key,
           to_char(timestamp,'MM/DD/YYYY HH:MI:SS') timestamp,
           passes, fails
    from aa_test_final_results
  </querytext>
</fullquery>

</queryset>
