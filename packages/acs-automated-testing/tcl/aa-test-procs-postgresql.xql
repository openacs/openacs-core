<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="aa_log_result.test_result_insert">
  <querytext>
     insert into aa_test_results
                      (testcase_id, package_key, test_id, timestamp,
                       result, notes)
              values (:aa_testcase_id, :aa_package_key, :aa_testcase_test_id,
                      current_timestamp, :test_result, :test_notes)
  </querytext>
</fullquery>

<fullquery name="aa_log_final.testcase_result_insert">
  <querytext>
    insert into aa_test_final_results
                    (testcase_id, package_key, timestamp, passes, fails)
    values (:aa_testcase_id, :aa_package_key, current_timestamp, :test_passes, :test_fails)
  </querytext>
</fullquery>


<fullquery name="aa_get_first_url.first_url">
  <querytext>
   select site_node__url(node_id) as url
   from site_nodes
   where object_id in (select package_id from apm_packages
                       where package_key = :package_key)
   limit 1
   </querytext>
</fullquery>

</queryset>
