ad_page_contract {
	
} {
	textarea_id:naturalnum,notnull
	community_id:naturalnum,notnull
} 

# select the correct language file for htmlarea

switch [lang::user::language -site_wide] {
	en -
	de {
		set htmlarea_lang_file [lang::user::language -site_wide] 
	}
	default {
		set htmlarea_lang_file "en"
	}
}



ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
