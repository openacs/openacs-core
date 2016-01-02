<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
 
<fullquery name="aa_log_result.test_result_insert">
  <querytext>
     insert into aa_test_results
                      (testcase_id, package_key, test_id, timestamp, result,
                       notes)
              values (:aa_testcase_id, :aa_package_key, :aa_testcase_test_id,
                      sysdate, :test_result, :test_notes)
  </querytext>
</fullquery>

<fullquery name="aa_log_final.testcase_result_insert">
  <querytext>
    insert into aa_test_final_results
                    (testcase_id, package_key, timestamp, passes, fails)
    values (:aa_testcase_id, :aa_package_key, sysdate, :test_passes, :test_fails)
  </querytext>
</fullquery>

</queryset>
