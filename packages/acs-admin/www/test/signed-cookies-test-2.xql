<?xml version="1.0"?>
<queryset>

<fullquery name="get_token_value">      
      <querytext>
      
    select token from secret_tokens
    where token_id = :token_id

      </querytext>
</fullquery>

 
</queryset>
