# /packages/acs-lang/www/admin/localized-message-new.tcl
ad_page_contract {

    Displays the form for the creation of a new localized message.

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Christian Hvid
    @author Christian Eva (<christian@quest.ie> Error-handling, return / loop / cancel
    @creation-date 15 April 2002
    @cvs-id $Id$

} {
    locale
    package_key
    {message_key ""}
    {return_url {}}
}


# cjeva: changed the way the return va is handled, so that it can be called from 
# other parts of oacs and return there. So if it is called with a message-key, it will
# not display the two buttons.

set default_return [export_vars -base message-list { locale package_key }]

# We rename to avoid conflict in queries
set current_locale $locale
set default_locale en_US

set locale_label [ad_locale_get_label $current_locale]
set default_locale_label [ad_locale_get_label $default_locale]

set page_title "Create New Message"
set context [list [list "package-list?[export_vars { locale }]" $locale_label] \
                 [list "message-list?[export_vars { locale package_key show }]" $package_key] \
                 $page_title]


set next_url [export_vars -base [ad_conn url] { locale package_key return_url}]

# We check that this request is coming for the system wide default
# locale. If not, we can't allow the creation of a new localized 
# message.

if { ![string equal $current_locale $default_locale] } {
    ad_return_error "Can only create messages in the default locale" "Can only create messages in the default locale"
    ad_script_abort
}

set Lbutt [list [list Insert ok]]

if {![string length $return_url]} {
    lappend Lbutt [list Return cancel]
} else {
   set next_url $return_url
}

form create message_new \
	-edit_buttons $Lbutt
	
element create message_new package_key_display -label "Package" -datatype text \
    -widget inform -value $package_key

element create message_new message_key -label "Message key" -datatype text -widget text -html { size 50 }

element create message_new message -label "Message" -datatype text \
    -widget textarea -html { rows 6 cols 40 }

element create message_new package_key -datatype text -widget hidden

element create message_new return_url -datatype text -widget hidden -optional

# The two hidden tags that we need to pass on the key and language to the
# processing of the form
element create message_new locale -label "locale" -datatype text -widget hidden

set focus message_new.message_key
if { [form is_request message_new] } {

    element set_value message_new package_key $package_key
    element set_value message_new locale $current_locale
    element set_value message_new message_key $message_key
    element set_value message_new return_url $return_url
    if { [empty_string_p $message_key] } {
        set focus message_new.message_key
    } else {
        set focus message_new.message
    }

} else {

    # We are not getting a request, so it's a post. Get and validate
    # the values

    set button [form get_button message_new]
    if {[string match cancel $button]} {
	# go back 
	if {![string length $return_url]} { 

	    set return_url $default_return
	}
    	ad_returnredirect $return_url
    	ad_script_abort
    } 	

    form get_values message_new

    # We have to check the format of the key submitted by the user,
    # We can't accept whitespaces or tabs, only alphanumerical and "-",
    # "_" or "." characters. The 1st character can't be a "."
    if { [regexp {[^[:alnum:]\_\-\.\?]} $message_key] } {
        # We matched for a forbidden character
        element set_error message_new message_key \
            "Key can only have alphanumeric or \"-\", \"_\", \".\" or \"?\" characters"

    } 

    if { [string length $message_key] >= 200 } {

        # Oops. The length of the key is too high.
        element set_error message_new key \
            "Key can only have less than 200 characters"

    }
} 

if { [form is_valid message_new] } {

    # We get the values from the form
    form get_values message_new package_key message_key locale message

    # We use the acs-lang registration of a translation. Simple, eh?

    set err [catch {lang::message::register $locale $package_key $message_key $message} err_mess]
    if { $err } {
    	util_user_message -message $err_mess 
    	element set_error message_new package_key_display \
            $err_mess
    } else {
    
        set escaped_locale [ns_urlencode $locale]

        ##forward $return_url 
        forward $next_url
    }
}
