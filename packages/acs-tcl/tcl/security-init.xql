<?xml version="1.0"?>

<queryset>

<fullquery name="secret_tokens_exists">      
      <querytext>

      select case when count(*) = 0 then 0 else 1 end from secret_tokens

      </querytext>
</fullquery>

 
</queryset>
