# /packages/gp-lang/www/gpadmin/localized-message-new.tcl
ad_page_contract {

    Displays the form for the creation of a new localized message.

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 15 April 2002
    @cvs-id $Id$

} {
    locales
    grouper_key
} -properties {
}

# check the permission
set package_id [ad_conn package_id]
set permission_p [ad_permission_p $package_id nro_admin]

if { !$permission_p } {
    ad_returnredirect "/gp-admin"
}

# We check that this request is coming for the system wide default
# locale. If not, we can't allow the creation of a new localized 
# message.

if { [exists_and_not_null locales] } {
    set locale_user $locales
} else {
    set locale_user [ad_locale_locale_from_lang [ad_locale user language]]
}

set default_locale [ad_parameter DefaultLocale]

if { $locale_user != $default_locale } {

   # ooops!
   # We should let the user know about this ... shouldn't we? noooooo... :)
   set encoded_locale [ns_urlencode $locale_user]
   ad_returnredirect "display-grouped-messages?locales=$encoded_locale"

}

set locale_label [ad_locale_get_label $locale_user]

#  AS - doesn't work
#  set encoding_charset [ad_locale charset $locale_user]
#  ns_setformencoding $encoding_charset
#  ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=$encoding_charset"

append return_url "display-grouped-messages?locales=" [ns_urlencode $locale_user]

set tab [ns_urlencode "localized-messages"]

set context_bar [ad_context_bar [list "index?tab=$tab" "Locales & Messages"] \
    [list "display-grouped-messages?tab=$tab&locales=$locales" "Listing"] \
    "New"]

template::form create message_new

template::element create message_new grouper_key_display -label "categorizer" -datatype text \
    -widget inform -value $grouper_key

template::element create message_new key -label "key" -datatype text -widget text

template::element create message_new message -label "Message" -datatype text \
    -widget textarea -html { rows 6 cols 40 }

template::element create message_new is_image_p -label "Is this an image?" \
    -datatype text -widget radio -options { {"yes" "t"} {"no" "f"} }

template::element create message_new grouper_key -label "grouper_key" \
    -datatype text -widget hidden

# The two hidden tags that we need to pass on the key and language to the
# processing of the form
template::element create message_new locales -label "locale" -datatype text -widget hidden

if { [template::form is_request message_new] } {

    template::element set_properties message_new grouper_key -value $grouper_key
    template::element set_properties message_new locales -value $locale_user
    template::element set_properties message_new is_image_p -value "f"

} else {

    # We are not getting a request, so it's a post. Get and validate
    # the values

    template::form get_values message_new

    # We have to check the format of the key submitted by the user,
    # We can't accept whitespaces or tabs, only alphanumerical and "-",
    # "_" or "." characters. The 1st character can't be a "."
    if { [regexp {[^[:alnum:]\_\-\.\?]} $key] } {

        # We matched for a forbidden character
        template::element set_error message_new key \
            "Key can only have alphanumeric or \"-\", \"_\", \".\" or \"?\" characters"

    } 

    if { [string length $key] >= 80 } {

        # Oops. The length of the key is too high.
        template::element set_error message_new key \
            "Key can only have less than 80 characters"

    }

    # If the user selected the radio button saying that this is an image,
    # we make sure that the message contains a correct filename (no spaces
    # and the file extension is either jpeg, jpg, gif or png)
    if { $is_image_p == "t" } {
        set message_tmp [string tolower $message]
        if { ![regexp {([[:alnum:]\_\-]+)(\.jpeg|\.jpg|\.gif|\.png)$} $message_tmp] } {
            # If we are here it's because the regular expression didn't match
            # It seems like the user is creating a wrongly formatted message
            template::element set_error message_new message \
                "If uploading an image, the message must be the filename. We can only
                accept GIF, JPG or PNG at the moment."
        }
    }
} 

if { [template::form is_valid message_new] } {

    # We get the values from the form
    template::form get_values message_new grouper_key
    template::form get_values message_new key
    template::form get_values message_new locales
    template::form get_values message_new message
    template::form get_values message_new is_image_p

    # Let's create the proper key
    append real_key $grouper_key "." $key

    # We use the gp-lang registration of a translation. Simple, eh?
    if { $is_image_p == "t" } {

        # Since the user will be uploading in the next few screens an image and
        # the message will be the filename we use to store the file in the
        # filesystem, to make it unique, we prepend the key and the locale to
        # the file.

        set message_lowercase [string tolower $message]

        append message_to_store $real_key "_" $locales "_" $message_lowercase

        _mr $locales $real_key $message_to_store

    } elseif { $is_image_p == "f" } {

        # Since the user is not uploading an image, we don't mess around
        # with the message.

        _mr $locales $real_key $message

    }

    set escaped_locale [ns_urlencode $locales]

    db_release_unused_handles

    # We check if the user told us that this was an image, if it is we
    # redirect him/her to the second step where he/she can upload the
    # image. If not, we send the user back to the listing of grouped
    # messages for this locale.

    if { $is_image_p == "t" } {

        set return_url "localized-message-new-2?key="
        append return_url [ns_urlencode $real_key] "&locales=" $escaped_locale

    } 

    template::forward $return_url

}

db_release_unused_handles
