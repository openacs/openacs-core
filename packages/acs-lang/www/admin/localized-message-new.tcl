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
} -properties {
}


# We check that this request is coming for the system wide default
# locale. If not, we can't allow the creation of a new localized 
# message.

if {[info exists locale]} {
    set locale_user $locale
} else {
    set locale_user [ad_conn locale]
}

set default_locale en_US

if { $locale_user != $default_locale } {
   # ooops!
   # We should let the user know about this ... shouldn't we? noooooo... :)
   set encoded_locale [ns_urlencode $locale_user]
   ad_returnredirect "display-grouped-messages?locale=$encoded_locale"

}

set locale_label [ad_locale_get_label $locale_user]

append return_url "display-grouped-messages?locale=" [ns_urlencode $locale_user]

set tab [ns_urlencode "localized-messages"]

set context_bar [ad_context_bar [list "index?tab=$tab" "Locales & Messages"] \
    [list "display-grouped-messages?tab=$tab&locale=$locale" "Listing"] \
    "New"]

template::form create message_new

template::element create message_new package_key_display -label "Package" -datatype text \
    -widget inform -value $package_key

template::element create message_new message_key -label "Message key" -datatype text -widget text

template::element create message_new message -label "Message" -datatype text \
    -widget textarea -html { rows 6 cols 40 }

template::element create message_new package_key -datatype text -widget hidden

# The two hidden tags that we need to pass on the key and language to the
# processing of the form
template::element create message_new locale -label "locale" -datatype text -widget hidden

if { [template::form is_request message_new] } {

    template::element set_properties message_new package_key -value $package_key
    template::element set_properties message_new locale -value $locale_user

} else {

    # We are not getting a request, so it's a post. Get and validate
    # the values

    template::form get_values message_new

    # We have to check the format of the key submitted by the user,
    # We can't accept whitespaces or tabs, only alphanumerical and "-",
    # "_" or "." characters. The 1st character can't be a "."
    if { [regexp {[^[:alnum:]\_\-\.\?]} $message_key] } {
        # We matched for a forbidden character
        template::element set_error message_new message_key \
            "Key can only have alphanumeric or \"-\", \"_\", \".\" or \"?\" characters"

    } 

    if { [string length $message_key] >= 200 } {

        # Oops. The length of the key is too high.
        template::element set_error message_new key \
            "Key can only have less than 200 characters"

    }
} 

if { [template::form is_valid message_new] } {

    # We get the values from the form
    template::form get_values message_new package_key
    template::form get_values message_new message_key
    template::form get_values message_new locale
    template::form get_values message_new message

    # We use the acs-lang registration of a translation. Simple, eh?

    lang::message::register $locale $package_key $message_key $message

    set escaped_locale [ns_urlencode $locale]

    template::forward $return_url

}
