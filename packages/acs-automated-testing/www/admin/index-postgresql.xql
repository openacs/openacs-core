<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="acs-automated-testing.results_query">
  <querytext>
    select testcase_id, package_key,
           timestamp,
           passes, fails
    from aa_test_final_results
  </querytext>
</fullquery>

</queryset>
