<?xml version="1.0"?>
<queryset>
  
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>
 
<fullquery name="acs-automated-testing.testcase_query">
  <querytext>
    select to_char(timestamp,'YYYY-MM-DD HH24:MI:SS') as timestamp, result, notes
    from aa_test_results
    where testcase_id = :testcase_id 
        and package_key = :package_key
    $filter
    order by test_id
  </querytext>
</fullquery>

<fullquery name="acs-automated-testing.get_testcase_fails_count">
  <querytext>
    select fails
    from aa_test_final_results
    where testcase_id = :testcase_id
  </querytext>
</fullquery>

</queryset>
