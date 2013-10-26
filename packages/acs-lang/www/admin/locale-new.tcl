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

set countries_list [db_list_of_lists select_countries {}]
element create locale_creation country \
    -label "Country" \
    -datatype text \
    -widget select \
    -options $countries_list

set languages_list [db_list_of_lists select_languages {}]
element create locale_creation language \
    -label "Language" \
    -datatype text \
    -widget select \
    -options $languages_list

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
    -label "MIME Charset" -datatype text -value "UTF8"

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

    # label is built from language and country
    set label "[lang::util::language_label -language $language] ($country)"
    append locale $language "_" $country

    db_transaction {

        # If there is already a default for this language, then it will remain
        # the current one. We don't change that.
        set default_p "f"

        # We first make sure that there is no default for this language
        set is_default_p [db_string select_default {}]
        if { $is_default_p == 0 } {
            # There is a no default for this language
            set default_p "t"
        }

        db_dml insert_locale {}
    }
    forward "index?tab=locales"

}
