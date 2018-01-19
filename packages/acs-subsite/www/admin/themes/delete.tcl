ad_page_contract {
    Delete the theme with the specified key

    @author Gustaf Neumann
    @creation-date 2017-01-20
} {
    theme:trim
} -validate {
    new_key_valid -requires new_key {
	if {![db_string check_exists_theme {
	    select 1 from subsite_themes where key = :theme
	} -default 0]} {
	    ad_complain "Theme with key '$theme' does not exist" 
	}
    }
}

subsite::delete_subsite_theme -key $theme

ns_returnredirect "."
ad_script_abort
