ad_page_contract {

    Displays the localized message from the database for translation (displays
    an individual message)

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 30 October 2001
    @cvs-id $Id$

} {
    locales
    {translated_p}
    key
} -properties {
}

request create
request set_param key -datatype keyword -optional
request set_param locales -datatype keyword -optional

if { [exists_and_not_null locales] } {
    set locale_user $locales
} else {
    set locale_user [ad_locale_locale_from_lang [ad_locale user language]]
}
#  AS - doesn't work
#  set encoding_charset [ad_locale charset $locale_user]
#  ns_setformencoding $encoding_charset
#  ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=$encoding_charset"

set return_url "display-localized-messages?grouper_key="

# we get the grouper (the first string before the first '.' in the key)
set grouper_key [string range $key 0 [expr ([string first "." $key] - 1)]]

append return_url [ns_urlencode $grouper_key]
append return_url "&locales=[ns_urlencode $locales]&translated_p=$translated_p"

set tab [ns_urlencode "localized-messages"]

set context_bar [ad_context_bar [list "index?tab=$tab" "Locales & Messages"] \
    [list "display-grouped-messages?tab=$tab&locales=$locales" "Listing"] \
    [list $return_url "Messages"] "Edit"]


# This has an ugly smell: But let's hardcode the default to en_US

set default_locale en_US

# The part that deals with images is removed - so all messages are treated
# as simple text.

template::form create message_editing

template::element create message_editing original_message \
    -label "Original Message" -datatype text -widget inform

template::element create message_editing message -label "Message" \
    -datatype text -widget textarea -html { rows 6 cols 40 }

# The two hidden tags that we need to pass on the key and language to the
# processing of the form

template::element create message_editing key -label "key" -datatype text -widget hidden

template::element create message_editing locales -label "locale" -datatype text -widget hidden

template::element create message_editing translated_p -label "translated_p" -datatype text -widget hidden -value $translated_p

 set locale_label [ad_locale_get_label $locale_user]

# Header Stuff ... We make sure that this page doesn't get cached.
set header_stuff "<meta http-equiv=\"Pragma\" content=\"no-cache\" />" 

if { [template::form is_request message_editing] } {

    set sql_select_original_message "
        select message
        from lang_messages
        where key = :key and locale = :default_locale "

    set sql_select_translated_message "
        select message as translated_message
        from lang_messages
        where key = :key and locale = :locale_user"

    # Let's get the original message (in english)
    db_1row select_original_message $sql_select_original_message

    # let's get the translated message (we use 0or1row since the message
    # might not exists
    db_0or1row select_translated_message $sql_select_translated_message

    if { [exists_and_not_null translated_message] } {

        template::element set_properties message_editing message -value $translated_message

    } else {

        template::element set_properties message_editing message -value "No Translation Available"

    }
   
    template::element set_properties message_editing key -value $key
    template::element set_properties message_editing locales -value $locale_user
    template::element set_properties message_editing original_message -value $message

} else {

    # We are not processing a request, therefor it's a submission. Get the values
    # from the form and validate them

    template::form get_values message_editing
    if { $message == "" } {

        template::element set_error message_editing message "Message is required"
        set sql_select_original_message "
            select message
            from lang_messages
            where key = :key and locale = :default_locale "
        db_1row select_original_message $sql_select_original_message

        template::element set_properties message_editing original_message -value $message

    }

}

if { [template::form is_valid message_editing] } {

    # We get the values from the form
    template::form get_values message_editing key
    template::form get_values message_editing locales
    template::form get_values message_editing message

    # We use the gp-lang registration of a translation. Simple, eh?
    _mr $locales $key $message

    # Even if the country code is 2 chars, we avoid problems...
    set escaped_locale [ns_urlencode $locales]

    template::forward $return_url

}

db_release_unused_handles
