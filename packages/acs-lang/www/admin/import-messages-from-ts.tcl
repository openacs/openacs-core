ad_page_contract {
    Import messages from catalog files to the database.

    @author Peter Marklund
} {
    locale
    package_key
    {return_url "/acs-lang/admin"}
}


if {![acs_user::site_wide_admin_p]} {
    ad_return_warning "Permission denied" "Sorry, only site-wide administrators are allowed to import message catalog files to the database."
    ad_script_abort
}

set message_count(processed) 0
set message_count(added) 0
set message_count(updated) 0
set message_count(deleted) 0
set message_count(errors) [list]

set translation_server "http://cognovis.theservice.de:8002"
array set catalog_array [lang::catalog::parse [ad_httpget -url [export_vars -base "$translation_server/acs-lang/download-messages"  {package_key locale}]]]

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

set conflict_count [lang::message::conflict_count \
                        -package_key $package_key \
                        -locale $locale]

set errors_list "<ul> <li>
 [join $message_count(errors) "</li><li>"] </ul>
"

set conflict_url [export_vars \
		      -base message-conflicts {package_key locale}]
