<?xml version="1.0"?>
<queryset>

<fullquery name="ad_user_class_description.category_id">      
      <querytext>
        select category from categories where category_id = :category_id

      </querytext>
</fullquery>

<fullquery name="ad_user_class_description.country_code">      
      <querytext>

        select country_name from country_codes where iso = :country_code

      </querytext>
</fullquery>

<fullquery name="ad_user_class_description.usps_abbrev">      
      <querytext>

        select state_name from states where usps_abbrev = :usps_abbrev

      </querytext>
</fullquery>

<fullquery name="ad_user_class_description.group_id">      
      <querytext>

        select group_name from groups where group_id = :group_id

      </querytext>
</fullquery>

<fullquery name="ad_user_class_description.registration_during_month">      
      <querytext>

        select to_char(to_date(:registration_during_month,'YYYYMM'),'fmMonth YYYY') from dual

      </querytext>
</fullquery>

<fullquery name="ad_user_class_description.user_class_id">      
      <querytext>

        select name from user_classes where user_class_id = :user_class_id

      </querytext>
</fullquery>
 
</queryset>
