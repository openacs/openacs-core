# /packages/gp-lang/www/gpadmin/locale-delete.tcl

ad_page_contract {

    Deletes a locale

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 19 march 2002
    @cvs-id $Id$
} {
    locales
} -properties {
}

# Get the locale for the user so that we 'spit' the content back in the
# proper locale
set locale_user [ad_locale_locale_from_lang [ad_locale user language]]

#  AS - doesn't work
#  set encoding_charset [ad_locale charset $locale_user]
#  ns_setformencoding $encoding_charset
#  ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=$encoding_charset"

set context_bar [ad_context_bar "Deleting Locales"]

form create locale_deleting

# It's a request, not a submission of the form

element create locale_deleting country -label "Country (2 digit ISO-code)" \
        -datatype text -widget text -html { maxLength 2 size 2 }

element create locale_deleting language -label "Language (2 digit ISO-code)" \
        -datatype text -widget text -html { maxLength 2 size 2 }

element create locale_deleting label -label "Label" -datatype text

element create locale_deleting nls_language -label "NLS Language" \
    -datatype text -widget text

element create locale_deleting nls_territory -label "NLS Territory" \
    -datatype text -widget text

element create locale_deleting nls_charset -label "NLS Charset" \
    -datatype text -widget text

element create locale_deleting mime_charset \
    -label "MIME Charset" -datatype text

element create locale_deleting default_p -label "Default" \
    -datatype text -widget hidden  

element create locale_deleting locales -p label "Locales" \
    -datatype text -widget hidden -value $locales

if { [form is_request locale_deleting] } {

    # Finish building the form to present to the user
    db_1row select_details_locale "select locale as locale_locale,
            language as locale_language, country as locale_country,
            label as locale_label, nls_language as locale_nls_language,
            nls_territory as locale_nls_territory, nls_charset as locale_nls_charset,
            mime_charset as locale_mime_charset, default_p as locale_default_p
        from ad_locales
        where locale = :locales"
    element set_properties locale_deleting label -value $locale_label
    element set_properties locale_deleting language -value $locale_language
    element set_properties locale_deleting country -value $locale_country
    element set_properties locale_deleting nls_language -value $locale_nls_language
    element set_properties locale_deleting nls_territory -value $locale_nls_territory
    element set_properties locale_deleting nls_charset -value $locale_nls_charset
    element set_properties locale_deleting mime_charset -value $locale_mime_charset
    element set_properties locale_deleting default_p -value $locale_default_p

}

if { [ns_queryexists form:confirm] } {

    db_transaction {

        db_dml delete_locale "delete from ad_locales where locale = :locales"

    }

    forward "index?tab=locales"

}

if { [form is_valid locale_deleting] } {

    # We are receiving a valid submission
    set confirm_data [form export]

    append confirm_data "<input type=\"hidden\" name=\"form:confirm\" value=\"confirm\" />"

    set_file "[file dir $__adp_stub]/locale-delete-confirm"

}

db_release_unused_handles
