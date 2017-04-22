ad_page_contract {
    A form to help semi-automate the conversion of Tcl and adp files from using literal
    text strings to using the message catalog.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 8 October 2002
    @cvs-id $Id$  
} {
    version_id:naturalnum,notnull    
    {pre_select_files_p:boolean "1"}
    {show_status_p:boolean "0"}
    {only_text_p:boolean "0"}
    {file_type adp}
}

db_1row package_version_info {
    select pretty_name, version_name
    from apm_package_version_info
    where version_id = :version_id
}

set page_title "Message catalog lookups for adp and Tcl files of $pretty_name $version_name"
set context_bar [ad_context_bar $page_title]

set file_option_list [list]
set adp_preselect_list [list]
set package_key [apm_package_key_from_version_id $version_id]
foreach file [lsort [ad_find_all_files [acs_package_root_dir $package_key]]] {	

    set file_regexp ".${file_type}\$"
    
    if { [regexp $file_regexp $file match] } {
        set relative_path [ad_make_relative_path $file]

        # Get statistics on number of message tags
        if { $show_status_p || $only_text_p } {

            set file_id [open $file r]
            set file_contents [read $file_id]

            set number_of_message_tags [llength [lang::util::get_temporary_tags_indices $file_contents]]

            switch -- $file_type {
                adp {
                    set number_of_message_keys [llength [lang::util::get_hash_indices $file_contents]]
                    set adp_text_result_list [lang::util::replace_adp_text_with_message_tags $file report]
                    set number_of_text_snippets [llength [lindex $adp_text_result_list 0]]
                
                    set status_string "$number_of_text_snippets texts, $number_of_message_tags tags, $number_of_message_keys keys"
                }
                tcl {
                    set status_string "$number_of_message_tags tags"
                }
                sql {
                    set number_of_message_keys [llength [lang::util::get_hash_indices $file_contents]]
                    set status_string "$number_of_message_tags tags, $number_of_message_keys keys"
                }
            }

            close $file_id

        } else {
            set status_string ""
        }

        set add_file_p 1
        # If we are showing adp:s and we are only showing adp:s with texts to translate, check if
        # this file has any texts
        if { $file_type eq "adp" && $only_text_p } {
            if { $number_of_text_snippets == 0 } {
                set add_file_p 0
            }
        }

        # Checkbox label in first element and value in second
        if { $add_file_p } {
            lappend file_option_list [list "$relative_path $status_string" $relative_path]
        }

        if { $pre_select_files_p } {
            lappend adp_preselect_list $relative_path
        }

    }
}

form create file_list_form -action [ad_decode $file_type adp "version-i18n-process" "version-i18n-process-2"]

element create file_list_form version_id \
        -datatype integer \
        -widget hidden \
        -value $version_id

element create file_list_form files \
        -datatype text \
        -widget checkbox \
        -label "ADP Templates" \
        -options $file_option_list \
        -values $adp_preselect_list

set action_label "Action to take on files"
if {$file_type eq "adp"} {
    element create file_list_form file_action \
        -datatype text \
        -widget checkbox \
        -label $action_label \
        -options {{{Find human language text and replace with <# ... #> tags} replace_text} {{Replace <# ... #> tags with #...# keys and insert message into catalog} replace_tags}} \
        -values {replace_text} \
} else {
    # Tcl files or SQL files
    element create file_list_form tcl_action_inform \
            -datatype text \
            -widget inform \
            -label $action_label \
            -value "Replace tags with keys and insert into catalog"

    # We need to export the file action
    element create file_list_form file_action \
            -datatype text \
            -widget hidden \
            -value replace_tags
}

if { $pre_select_files_p } {
    set href [export_vars -base version-i18n -override {{pre_select_files_p 0}} {version_id file_type show_status_p only_text_p}]
    set pre_select_filter [subst {<a href="[ns_quotehtml $href]">Unselect all checkboxes</a>}]
} else {
    set href [export_vars -base version-i18n -override {{pre_select_files_p 1}} {version_id file_type show_status_p only_text_p}]
    set pre_select_filter [subst {<a href="[ns_quotehtml $href]">Select all checkboxes</a>}]
}

if { $show_status_p } {
    set href [export_vars -base version-i18n -override {{show_status_p 0}} {version_id file_type pre_select_files_p only_text_p}]
    set status_filter [subst {<a href="[ns_quotehtml $href]">Hide I18N status of files</a>}]
} else {
    set href [export_vars -base version-i18n -override {{show_status_p 1}} {version_id file_type pre_select_files_p only_text_p}]
    set status_filter [subst {<a href="[ns_quotehtml $href]">Show I18N status of files</a>}]
}

switch -- $file_type {
    adp {
        if { $only_text_p } {
	    set href [export_vars -base version-i18n-override {{only_text_p 0}} {pre_select_files_p version_id file_type show_status_p}]
            set text_only_filter [subst {<a href="[ns_quotehtml $href]">all adp files</a> | only adp files with translatable text}]
        } else {
	    set href [export_vars -base version-i18n -override {{only_text_p 1}} {pre_select_files_p version_id file_type show_status_p}]
            set text_only_filter [subst {<b>all adp files</b> | <a href="[ns_quotehtml $href]">only apd files with translatable text</a>}]
        }

	set href1 [export_vars -base version-i18n -override {{file_type tcl}} {version_id pre_select_files_p show_status_p only_text_p}]
	set href2 [export_vars -base version-i18n -override {{file_type sql}} {version_id pre_select_files_p show_status_p only_text_p}]
        set file_type_filter [subst {
	    <b>Show adp files</b>: $text_only_filter |
	    <a href="[ns_quotehtml $href1]">Show Tcl files</a> |
	    <a href="[ns_quotehtml $href2]">Show sql files</a>
	}]
    }
    tcl {
	set href1 [export_vars -base version-i18n -override {{file_type adp}} {version_id pre_select_files_p show_status_p only_text_p}]
	set href2 [export_vars -base version-i18n -override {{file_type sql}} {version_id pre_select_files_p show_status_p only_text_p}]
        set file_type_filter [subst {
	    <a href="[ns_quotehtml $href1]">Show adp files</a> |
	    <b>Show Tcl files</b> |
	    <a href="[ns_quotehtml $href2]">Show sql files</a>
	}]
    }
    sql {
	set href1 [export_vars -base version-i18n -override {{file_type adp}} {version_id pre_select_files_p show_status_p only_text_p}]
	set href2 [export_vars -base version-i18n -override {{file_type tcl}} {version_id pre_select_files_p show_status_p only_text_p}]
	
        set file_type_filter [subst {
	    <a href="[ns_quotehtml $href1]">Show adp files</a> |
	    <a href="[ns_quotehtml $href2]">Show Tcl files</a> |
	    <b>Show sql files</b>
	}]
    }
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
