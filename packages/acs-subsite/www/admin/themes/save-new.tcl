ad_page_contract {
    Save current settings as a theme with a new key and name

    @author Gustaf Neumann
    @creation-date 2017-01-20
} {
    new_theme:word,trim
    new_name:trim
} -validate {
    new_theme_valid -requires new_theme {
	if {[db_string check_exists_theme {
	    select 1 from subsite_themes where key = :new_theme
	} -default 0]} {
	    ad_complain "Theme with key '$new_theme' exists already" 
	}
    }
}

#
# Save the current setting under a new name
#
subsite::save_theme_parameters_as \
    -theme $new_theme \
    -pretty_name $new_name

#
# ... and actiate the new theme automatically
#
subsite::set_theme -theme $new_theme

ns_returnredirect "."
