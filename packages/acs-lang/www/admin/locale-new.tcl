# /packages/acs-lang/www/admin/locale-new.tcl

ad_page_contract {

    Creates a new locale

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 15 march 2002
    @cvs-id $Id$
}


set locale_user [ad_conn locale]

set page_title "Create Locale"
set context [list $page_title]

form create locale_creation 

# The v$nls_valid_values view contains all the valid NLS values
# for the oracle instance. It is up to the user to select the correct
# values (combinations of language, territories and character sets. More
# information on this view can be found in the docs at http://tahiti.oracle.com/
# look for the PDF file of Oracle 8i "national language support guide"

catch {
    set nls_values_list [db_list_of_lists select_nls_values {select parameter, value from v$nls_valid_values order by parameter, value}]

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

element create locale_creation country -label "Country (2 digit ISO 3166 code)" \
    -datatype text -widget text -html { maxLength 2 size 2 }

element create locale_creation language -label "Language (2 digit ISO 639-1 code, or 3 digit ISO 639-2 code)" \
    -datatype text -widget text -html { maxLength 3 size 3 }

element create locale_creation label -label "Label" -datatype text

if { [info exists list_nls_language] } {

    element create locale_creation nls_language -label "NLS Language" \
            -datatype text -widget select -options $list_nls_language
    
    element create locale_creation nls_territory -label "NLS Territory" \
            -datatype text -widget select -options $list_nls_territory
    
    element create locale_creation nls_charset -label "NLS Charset" \
            -datatype text -widget select -options $list_nls_charset

} else {

    element create locale_creation nls_language -label "NLS Language" \
            -datatype text -widget text
    
    element create locale_creation nls_territory -label "NLS Territory" \
            -datatype text -widget text
    
    element create locale_creation nls_charset -label "NLS Charset" \
            -datatype text -widget text
}
    
element create locale_creation mime_charset \
    -label "MIME Charset" -datatype text

if { [form is_request locale_creation] } {

    # Finish building the form to present to the user
    # Since it's a standard form and no special values need to
    # set up, we do nothing! :)

} else {

    # If we are not building a request form, we are processing a submission.
    # Get the values from the form and validate them

    form get_values locale_creation

}

if { [form is_valid locale_creation] } {

    # We are receiving a valid submission
    form get_values locale_creation

    append locale $language "_" $country

    db_transaction {

        # If there is already a default for this language, then it will remain
        # the current one. We don't change that.
        set default_p "f"

        # We first make sure that there is no default for this language
        set is_default_p [db_string select_default "select count(*) from
            ad_locales where language = :language and default_p = 't'"]
        if { $is_default_p == "0" } {
            # There is a no default for this language
            set default_p "t"
        }

        db_dml insert_locale "insert into ad_locales (
            locale, language, country, variant, label, nls_language,
            nls_territory, nls_charset, mime_charset, default_p, enabled_p) values (
            :locale, :language, :country, NULL, :label, :nls_language,
            :nls_territory, :nls_charset, :mime_charset, :default_p, 'f')"

    }
    forward "index?tab=locales"

}
