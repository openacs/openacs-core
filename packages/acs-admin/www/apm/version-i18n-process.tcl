ad_page_contract {
    Internationalize a certain adp file (the next one in the list). Give the user the possibility to
    determine which texts should be substituted and which keys should be used.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 8 October 2002
    @cvs-id $Id$  
} {
    version_id:integer,notnull    
    {files:multiple}
    {file_action:multiple}
}

db_1row package_version_info "select pretty_name, version_name from apm_package_version_info where version_id = :version_id"

set page_title "Internationalization of $pretty_name $version_name"
set context_bar [ad_context_bar $page_title]

# Figure out which actions to take on the selected adp:s
set replace_text_p [ad_decode [lsearch -exact $file_action replace_text] "-1" "0" "1"]
set replace_tags_p [ad_decode [lsearch -exact $file_action replace_tags] "-1" "0" "1"]

# If no texts should be replaced we need not give the user a choice of keys to use and
# can go straight to the processing
set redirect_url "version-i18n-process-2?[export_vars -url {version_id files:multiple file_action:multiple}]"
if { ! $replace_text_p } {

    ad_returnredirect $redirect_url
    ad_script_abort
}

# Process one adp at a time interactively
set file [lindex $files 0]

set full_file_name "[acs_root_dir]/$file"

set adp_report_list [lang::util::replace_adp_text_with_message_tags "[acs_root_dir]/$file" report]
set adp_replace_list [lindex $adp_report_list 0]
set adp_no_replace_list [lindex $adp_report_list 1]

if { [llength $adp_replace_list] == 0 } {
    # There are no replacements to choose keys for so go straight to the processing result page
    ad_returnredirect $redirect_url
    ad_script_abort
}

multirow create replacements key text

foreach key_pair $adp_replace_list {
    multirow append replacements [lindex $key_pair 0] [lindex $key_pair 1]
}

set hidden_form_vars [export_vars -form {version_id files:multiple file_action:multiple}]

ad_return_template
