<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "http://www.thecodemill.biz/repository/xql.dtd">
<!--  -->
<!-- @author Victor Guerra (guerra@galileo.edu) -->
<!-- @creation-date 2005-02-06 -->
<!-- @arch-tag: d0117c72-fd55-4faa-b2cb-89ec5ce0c0ef -->
<!-- @cvs-id $Id$ -->

<queryset>
  <fullquery name="get_user_info">
    <querytext>
      
      select p.first_names||' '||p.last_name as user_name, pa.email as user_email 
      from persons p, parties pa
      where pa.party_id = p.person_id
      and p.person_id = :user_id
      
    </querytext>
  </fullquery>
  <fullquery name = "search_bug">
    <querytext>
      select bug_id
      from bt_auto_bugs
      where error_file =:error_file
      and package_id = :bug_package_id
    </querytext>
  </fullquery>
  <fullquery name = "insert_auto_bug">
    <querytext>
      insert into bt_auto_bugs(bug_id, package_id, error_file)
      values (:bug_id, :bug_package_id, :error_file)
    </querytext>
  </fullquery>
  <fullquery name = "increase_reported_times">
    <querytext>
        update bt_auto_bugs 
	set times_reported = times_reported + 1 
	where bug_id = :bug_id 
   </querytext>
  </fullquery>
  <fullquery name = "select_times_reported">
    <querytext>
      select times_reported 
      from bt_auto_bugs
      where bug_id = :bug_id 
    </querytext>
  </fullquery>

</queryset>