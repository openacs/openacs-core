<?xml version="1.0"?>
<queryset>
  
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="acs-automated-testing.testcase_query">
  <querytext>
    select timestamp, result, notes
      from aa_test_results
      where testcase_id = :testcase_id and
            package_key = :package_key
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
