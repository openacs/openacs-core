ad_page_contract {
    Do message key extraction for a certain APM package version.
    First let the user choose which adps to extract message keys from
    and then do the actual extraction. Redirects back to viewing the
    package version.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 1 October 2002
    @cvs-id $Id$  
} {
    version_id:integer,notnull
    
}

set page_title "Select adp Files to Extract Message Keys From"
set context_bar [ad_context_bar $page_title]

# Create a list of adp files
set adp_file_option_list [list]
set adp_preselect_list [list]
set package_key [apm_package_key_from_version_id $version_id]
foreach file [lsort [ad_find_all_files [acs_package_root_dir $package_key]]] {	
    set relative_path [ad_make_relative_path $file]
    
    if { [regexp {\.adp$} $file match] } {
        # Checkbox label in first element and value in second
        lappend adp_file_option_list [list $relative_path $relative_path]
        lappend adp_preselect_list $relative_path
    }
}

form create adp_list_form

element create adp_list_form version_id \
        -datatype integer \
        -widget hidden \
        -value $version_id

element create adp_list_form adp_files \
        -datatype text \
        -widget checkbox \
        -label "ADP Templates" \
        -options $adp_file_option_list \
        -values $adp_preselect_list

if { [form is_valid adp_list_form] } {
    # The form was submitted, process the adps

    set adp_files [element get_values adp_list_form adp_files]

    lang::util::extract_keys_from_adps $adp_files
    
    ad_returnredirect "version-view?version_id=$version_id"
    ad_script_abort
}

ad_return_template
