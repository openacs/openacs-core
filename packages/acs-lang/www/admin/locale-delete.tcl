# /packages/acs-lang/www/admin/locale-delete.tcl

ad_page_contract {

    Deletes a locale

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 19 march 2002
    @cvs-id $Id$
} {
    locale
} -properties {
}

set context_bar [ad_context_bar "Deleting Locale"]

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

element create locale_deleting locale -p label "Locale" \
    -datatype text -widget hidden -value $locale

if { [form is_request locale_deleting] } {

    # Finish building the form to present to the user
    db_1row select_details_locale "select locale as locale_locale,
            language as locale_language, country as locale_country,
            label as locale_label, nls_language as locale_nls_language,
            nls_territory as locale_nls_territory, nls_charset as locale_nls_charset,
            mime_charset as locale_mime_charset, default_p as locale_default_p
        from ad_locales
        where locale = :locale"
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

        db_dml delete_messages { delete from lang_messages where locale = :locale }

        db_dml delete_audit { delete from lang_messages_audit where locale = :locale }

        db_dml delete_locale { delete from ad_locales where locale = :locale }

    }

    forward "index?tab=locales"

}

if { [form is_valid locale_deleting] } {

    # We are receiving a valid submission
    set confirm_data [form export]

    append confirm_data "<input type=\"hidden\" name=\"form:confirm\" value=\"confirm\" />"

    set_file "[file dir $__adp_stub]/locale-delete-confirm"

}
