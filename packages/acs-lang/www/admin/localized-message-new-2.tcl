# /packages/gp-lang/www/gpadmin/localized-message-new-2.tcl
ad_page_contract {

    Displays the form for the user to upload a file that is refered
    from a localized message

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 15 April 2002
    @cvs-id $Id$

} {
    locales
    key
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
    "Upload file"]

template::form create message_file_upload -action localized-message-new-3 \
    -html {enctype multipart/form-data}

template::element create message_file_upload locales -label "Locale" \
    -datatype text -widget hidden -value $locale_user

template::element create message_file_upload key -label "key" \
    -datatype text -widget hidden -value $key

template::element create message_file_upload key_display -label "Key" \
    -datatype text -widget inform

template::element create message_file_upload message_display -label "Message" \
    -datatype text -widget inform

template::element create message_file_upload upload_file -label "Image file" \
    -datatype text -widget file

template::element create message_file_upload return_url -label "Return URL" \
    -datatype text -widget hidden

if { [template::form is_request message_file_upload] } {

    template::element set_properties message_file_upload message_display -value [_ $locale_user $key]
    template::element set_properties message_file_upload key_display -value $key
    template::element set_properties message_file_upload return_url -value $return_url

} 

db_release_unused_handles
