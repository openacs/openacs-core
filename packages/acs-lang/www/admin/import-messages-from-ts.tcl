ad_page_contract {
    Import messages from catalog files to the database.

    @author Peter Marklund
} {
    locale
    {package_key ""}
    {return_url "/acs-lang/admin"}
}


if {![acs_user::site_wide_admin_p]} {
    ad_return_warning "Permission denied" "Sorry, only site-wide administrators are allowed to import message catalog files to the database."
    ad_script_abort
}

# Determine if we are dealing only with one package key.
if { ![empty_string_p $package_key] } {
    set package_key_list $package_key
    set single_package_p 1
} else {
    set single_package_p 0
    set package_key_list [apm_enabled_packages]
}

set translation_server "http://translate.openacs.org"

set conflict_count 0

set errors_list ""

set count_type_list [list processed added updated deleted]

foreach type $count_type_list {
    set message_count_total($type) 0
}

foreach package_key $package_key_list {
    # Get the translation information for each package.

    # Initialize the message_count array
    foreach type $count_type_list {
	set message_count($type) 0
    }    
    set message_count(errors) [list]    

    # Skip the package if it has no catalog files at all
    if { ![file exists [lang::catalog::package_catalog_dir $package_key]] } {
	continue
    }
    
    # Get the translations from the translation server. On error skip it.
    set message_information [ad_httpget -url [export_vars -base "$translation_server/acs-lang/download-messages"  {package_key locale}]]
    if {[regexp "<title>Server Error</title>" $message_information]} {
	append errors_list "<li>No Translation on $translation_server for package $package_key"
	continue
    }

    array set catalog_array [lang::catalog::parse $message_information]
    
    # Get the messages array, and the list of message keys to iterate over
    
    array set messages_array [lindex [array get catalog_array messages] 1]
    set messages_array_names [array names messages_array]
    
    # Get the descriptions array
    
    array set descriptions_array [lindex [array get catalog_array descriptions] 1]
    
    # Register messages
    
    array set message_count [lang::catalog::import_messages \
				 -file_messages_list [array get messages_array] \
				 -package_key $package_key \
				 -locale $locale]

    # Register descriptions
    
    foreach message_key $messages_array_names {
	if {[info exists descriptions_array($message_key)]} {
	    with_catch errmsg {
	    lang::message::update_description \
		-package_key $catalog_array(package_key) \
		-message_key $message_key \
		-description $descriptions_array($message_key)
	    } {
		global errorInfo
		ns_log Error "Registering description for key ${package_key}.${message_key} in locale $locale failed with error message \"$errmsg\"\n\n$errorInfo"
	    }
    }
    }
    
    set package_conflict_count [lang::message::conflict_count \
			    -package_key $package_key \
			    -locale $locale]
    if {$package_conflict_count > 0} {
	append errors_list "<li> [join $message_count(errors) "</li><li>"]</li>"
	incr conflict_count $package_conflict_count
    }

    # Increase the total messages counted
    foreach type $count_type_list {
	incr message_count_total($type) $message_count($type)
    }

    array unset catalog_array
    array unset messages_array
    array unset descriptions_array
}

if ![empty_string_p $errors_list] {
    set errors_list "<ul>$errors_list</ul>"
}

set package_key ""

set conflict_url [export_vars \
		      -base message-conflicts {package_key locale}]
