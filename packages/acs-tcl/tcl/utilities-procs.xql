<?xml version="1.0"?>
<queryset>

<fullquery name="ad_dbclick_check_dml.double_click_check">      
      <querytext>
      
		
		select 1 as one
		from $table_name
		where $id_column_name = :generated_id
		
	    
      </querytext>
</fullquery>

 
<fullquery name="validate_zip_code.zip_code_exists">      
      <querytext>
		    select 1
		      from dual
		     where exists (select 1
				     from zip_codes
				    where zip_code like :zip_5)
      </querytext>
</fullquery>

<fullquery name="util_email_unique_p.email_unique_p">
  <querytext>
    select count(*)
    from dual
    where not exists (select 1
                      from parties
                      where email = lower(:email))
  </querytext>
</fullquery>

</queryset>
