<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="alerts_list_2">      
      <querytext>
      
    select cea.valid_p,
           ad.domain,
           cea.alert_id,
           cea.expires,
           cea.frequency,
           cea.alert_type,
           cea.category,
           cea.keywords
    from   classified_email_alerts cea, ad_domains ad
    where  user_id = :user_id
    and    ad.domain_id = cea.domain_id
    and    sysdate <= expires
    order by expires desc
      </querytext>
</fullquery>

 
</queryset>
