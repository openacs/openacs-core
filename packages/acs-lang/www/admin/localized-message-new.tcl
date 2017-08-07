# /packages/acs-lang/www/admin/localized-message-new.tcl
ad_page_contract {

    Displays the form for the creation of a new localized message.

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Christian Hvid
    @creation-date 15 April 2002
    @cvs-id $Id$

} {
    locale
    package_key
    {message_key ""}
    {return_url:localurl {[export_vars -base message-list { locale package_key }]}}
}


# We rename to avoid conflict in queries
set current_locale $locale
set default_locale en_US

set locale_label [lang::util::get_label $current_locale]
set default_locale_label [lang::util::get_label $default_locale]

set page_title "Create New Message"
set context [list [list [export_vars -base package-list { locale }] $locale_label] \
                 [list [export_vars -base message-list { locale package_key show }] $package_key] \
                 $page_title]




# We check that this request is coming for the system wide default
# locale. If not, we can't allow the creation of a new localized 
# message.

if { $current_locale ne $default_locale } {
    ad_return_error "Can only create messages in the default locale" "Can only create messages in the default locale"
    ad_script_abort
}

form create message_new

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

if { [form is_request message_new] } {

    element set_value message_new package_key $package_key
    element set_value message_new locale $current_locale
    element set_value message_new message_key $message_key
    element set_value message_new return_url $return_url
    if { $message_key eq "" } {
        set focus message_new.message_key
    } else {
        set focus message_new.message
    }

} else {

    # We are not getting a request, so it's a post. Get and validate
    # the values

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

    lang::message::register $locale $package_key $message_key $message

    set escaped_locale [ns_urlencode $locale]

    forward $return_url

}

set focus ""

ad_return_template
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
