<?xml version="1.0"?>
<queryset>

 
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
