ad_page_contract {
    Show internationalization status for a certain package version.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 8 October 2002
    @cvs-id $Id$  
} {
    version_id:integer,notnull    
    {pre_select_files_p "1"}
    {show_status_p "0"}
}

db_1row package_version_info "select pretty_name, version_name from apm_package_version_info where version_id = :version_id"

set page_title "Internationalization of $pretty_name $version_name"
set context_bar [ad_context_bar $page_title]

set adp_file_option_list [list]
set adp_preselect_list [list]
set package_key [apm_package_key_from_version_id $version_id]
foreach file [lsort [ad_find_all_files [acs_package_root_dir $package_key]]] {	
    
    if { [regexp {\.adp$} $file match] } {
        set relative_path [ad_make_relative_path $file]

        # Get statistics on number of message tags
        if { $show_status_p } {
            set adp_file_id [open $file r]
            set adp_file_contents [read $adp_file_id]
            set number_of_message_tags [llength [lang::util::get_adp_message_indices $adp_file_contents]]
            set number_of_message_keys [llength [lang::util::get_hash_indices $adp_file_contents]]
            set adp_text_result_list [lang::util::replace_adp_text_with_message_tags $file report]
            set number_of_text_snippets [llength [lindex $adp_text_result_list 0]]

            close $adp_file_id
            
            set status_string "$number_of_text_snippets texts, $number_of_message_tags tags, $number_of_message_keys keys"
        } else {
            set status_string ""
        }

        # Checkbox label in first element and value in second
        lappend adp_file_option_list [list "$relative_path $status_string" $relative_path]

        if { $pre_select_files_p } {
            lappend adp_preselect_list $relative_path
        }

    }
}

form create adp_list_form -action "version-i18n-process"

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

element create adp_list_form adp_action \
        -datatype text \
        -widget checkbox \
        -label "Action to take on files" \
        -options {{{Replace text with tags} replace_text} {{Replace tags with keys and insert into catalog} replace_tags}} \
        -values {replace_text replace_tags} \
        -section action_section

if { [form is_valid adp_list_form] } {
    # The form was submitted
    # Take action on selected adp:s
    
    set adp_file_list [element get_values adp_list_form adp_files]

    set action_list [element get_values adp_list_form adp_action]
    set replace_text_p [ad_decode [lsearch -exact $action_list replace_text] "-1" "0" "1"]
    set replace_tags_p [ad_decode [lsearch -exact $action_list replace_tags] "-1" "0" "1"]

    foreach adp_file $adp_file_list {
        if { $replace_text_p } {
            ns_log Notice "Replacing text in file $adp_file with message tags"
        }

        if { $replace_tags_p } {
            ns_log Notice "Replacing tags in file $adp_file with keys and doing insertion into message catalog"
        }
    }

    ad_returnredirect "version-i18n?version_id=$version_id"
    ad_script_abort
}

if { $pre_select_files_p } {
    set pre_select_filter "<a href=\"version-i18n?version_id=$version_id&pre_select_files_p=0\">Unselect all files</a>"
} else {
    set pre_select_filter "<a href=\"version-i18n?version_id=$version_id&pre_select_files_p=1\">Select all files</a>"
}

if { $show_status_p } {
    set status_filter "<a href=\"version-i18n?version_id=$version_id&pre_select_files_p=$pre_select_files_p&show_status_p=0\">Hide I18N status of files</a>"
} else {
    set status_filter "<a href=\"version-i18n?version_id=$version_id&pre_select_files_p=$pre_select_files_p&show_status_p=1\">Show I18N status of files</a>"
}

ad_return_template
