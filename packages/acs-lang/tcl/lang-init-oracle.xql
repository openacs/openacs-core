<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_lang_keys">      
      <querytext>
	select key 
	,rtrim(lang) as lang 
	,message 
	from lang_messages
      </querytext>
</fullquery>

 
</queryset>
