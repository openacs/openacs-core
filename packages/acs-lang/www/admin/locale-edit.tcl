ad_page_contract {

    Edits a locale

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>

    Modified by Christian Hvid

    @creation-date 19 march 2002
    @cvs-id $Id$
} {
    locale
}

# Get the locale for the user so that we 'spit' the content back in the
# proper locale

set locale_user [ad_conn locale]

#  AS - doesn't work
#  set encoding_charset [ad_locale charset $locale_user]
#  ns_setformencoding $encoding_charset
#  ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=$encoding_charset"

set page_title "Edit Locale"
set context [list $page_title]

form create locale_editing

# It's a request, not a submission of the form

#
# LARS:
# Hm.. this is Oracle-specific. Need to figure out what to do with this for PostgreSQL.
#

# The v$nls_valid_values view contains all the valid NLS values
# for the oracle instance. It is up to the user to select the correct
# values (combinations of language, territories and character sets. More
# information on this view can be found in the docs at http://tahiti.oracle.com/
# look for the PDF file of Oracle 8i "national language support guide"

catch {
    set nls_values_list [db_list_of_lists select_nls_values {select parameter, value 
    from v$nls_valid_values order by parameter, value}]

    foreach nls_value $nls_values_list {
        set value [lindex $nls_value 1]
        switch [lindex $nls_value 0] {
            LANGUAGE {
                lappend list_nls_language "\"$value\" \"$value\""
            }
            TERRITORY {
                lappend list_nls_territory "\"$value\" \"$value\""
            }
            CHARACTERSET {
                lappend list_nls_charset "\"$value\" \"$value\""
            }
        }
    }
}


# Greenpeace had a table of contries and languages and their two-digit ISO-code
# but not so in ACS-LANG - here you must provide the two-digit ISO-code

element create locale_editing country -label "Country (2 digit ISO-code)" \
        -datatype text -widget text -html { maxLength 2 size 2 }

element create locale_editing language -label "Language (2 digit ISO-code)" \
        -datatype text -widget text -html { maxLength 2 size 2 }

element create locale_editing label -label "Label" -datatype text

if { [info exists list_nls_language] } {
    element create locale_editing nls_language -label "NLS Language" \
            -datatype text -widget select -options $list_nls_language

    element create locale_editing nls_territory -label "NLS Territory" \
            -datatype text -widget select -options $list_nls_territory
    
    element create locale_editing nls_charset -label "NLS Charset" \
            -datatype text -widget select -options $list_nls_charset
} else {
    element create locale_editing nls_language -label "NLS Language" \
            -datatype text -widget text

    element create locale_editing nls_territory -label "NLS Territory" \
            -datatype text -widget text
    
    element create locale_editing nls_charset -label "NLS Charset" \
            -datatype text -widget text
}

element create locale_editing mime_charset \
    -label "MIME Charset" -datatype text

element create locale_editing default_p -label "Default" \
    -datatype text -widget hidden  

element create locale_editing locale -p label "Locale" \
    -datatype text -widget hidden -value $locale

if { [form is_request locale_editing] } {

    # Finish building the form to present to the user
    db_1row select_details_locale "select locale as locale_locale,
            language as locale_language, country as locale_country,
            label as locale_label, nls_language as locale_nls_language,
            nls_territory as locale_nls_territory, nls_charset as locale_nls_charset,
            mime_charset as locale_mime_charset, default_p as locale_default_p
        from ad_locales
        where locale = :locale"
    element set_properties locale_editing label -value $locale_label
    element set_properties locale_editing language -value $locale_language
    element set_properties locale_editing country -value $locale_country
    element set_properties locale_editing nls_language -value $locale_nls_language
    element set_properties locale_editing nls_territory -value $locale_nls_territory
    element set_properties locale_editing nls_charset -value $locale_nls_charset
    element set_properties locale_editing mime_charset -value $locale_mime_charset
    element set_properties locale_editing default_p -value $locale_default_p

} else {

    # If we are not building a request form, we are processing a submission.
    # Get the values from the form and validate them

    form get_values locale_editing

    set locale_label [lang::util::get_label $locale]

    if { $label == "" } {
        element set_error locale_editing label "Label is required"
    }
    if { $mime_charset == "" } {
        element set_error locale_editing mime_charset "Mime charset is required"
    }

}

if { [form is_valid locale_editing] } {

    # We are receiving a valid submission
    form get_values locale_editing

    db_transaction {

        db_dml update_locale "update ad_locales set
            language = :language, country = :country, label = :label,
            nls_language = :nls_language, nls_territory = :nls_territory,
            nls_charset = :nls_charset, mime_charset = :mime_charset,
            default_p = :default_p
            where locale = :locale"

    }
    db_flush_cache -cache_key_pattern ad_lang_mime_charset_$locale
    forward "index?tab=locales"

}
