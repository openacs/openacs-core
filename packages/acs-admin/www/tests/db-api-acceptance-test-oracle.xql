<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="db_api_acceptance_test_get_asdf_from_footest">      
      <querytext>
      
		select asdf as i, sysdate as datestr from footest
	    
      </querytext>
</fullquery>

 
<fullquery name="">      
      <querytext>
      
		    select asdf as j, sysdate as datestr2 from footest
		
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_select_date">      
      <querytext>
       select sysdate from dual 
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      select sysdate from dual
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_get_asdf_and_date_from_footest">      
      <querytext>
      
		select asdf, sysdate as datestr from footest
	    
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_get_asdf_sysdate_42_from_footest">      
      <querytext>
      
		select asdf, sysdate as datestr, 42 as jkl from footest
	    
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      select sysdate from dual
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_get_just_asfd_and_sysdate_from_footest">      
      <querytext>
      
		select asdf, sysdate as datestr from footest
	    
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_get_simply_asdf_sysdate_and_42_from_footest">      
      <querytext>
      
		select asdf, sysdate as datestr, 42 as jkl from footest
	    
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_1">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_2">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf > :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_3">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf < :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_4">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_5">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_6">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_7">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf > :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_8">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf < :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_9">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_10">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_11">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_12">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf > :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_13">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf < :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_14">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_select_asdf_sysdate_from_food_15">      
      <querytext>
      select asdf, sysdate as datestr from footest where asdf = :asdf
      </querytext>
</fullquery>

 
<fullquery name="unused">      
      <querytext>
      BEGIN select count(*) into :1 from footest; END;
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_test_plsql_exec">      
      <querytext>
      BEGIN select * into :1 from footest; END;
      </querytext>
</fullquery>

 
<fullquery name="db_api_acceptance_obtain_sysdate">      
      <querytext>
      select sysdate from dual
      </querytext>
</fullquery>

 
</queryset>
