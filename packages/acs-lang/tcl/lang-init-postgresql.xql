<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
 
<fullquery name="select_lang_keys">
    <querytext>
        select key ,trim(trailing from lang) as lang ,message
	from lang_messages
    </querytext>
</fullquery>
	        
</queryset>
	                            