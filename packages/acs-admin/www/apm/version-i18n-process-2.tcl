ad_page_contract {
    Internationalize a certain adp or Tcl file.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 8 October 2002
    @cvs-id $Id$  
} {
    version_id:naturalnum,notnull    
    {files:multiple,notnull}
    {file_action:multiple}
    {number_of_keys:integer,notnull ""}
    {replace_p:boolean,array ""}
    {message_keys:array ""}
    skip_button:optional
}

if { [info exists skip_button] } {
    # The user wants to skip the file so remove it from the file and redirect
    # to processing the next one
    set remaining_files [lrange $files 1 end]
    if { [llength $remaining_files] > 0 } {
        ad_returnredirect [export_vars -base version-i18n-process {version_id {files:multiple $remaining_files} file_action:multiple}]
    } else {
        ad_returnredirect [export_vars -base version-i18n {version_id}]
    }
    ad_script_abort
}

# Create the message key list
# The list is needed since replace_adp_tags_with_message_tags proc below takes a list of
# keys to do replacements with where an empty key  means no replacement.
set message_key_list [list]
for { set counter 1 } { $counter <= $number_of_keys } { incr counter } {
    if { [info exists replace_p($counter)] } {
        if { ([info exists message_keys($counter)] && $message_keys($counter) ne "") } {
            lappend message_key_list $message_keys($counter)
        } else {
            ad_return_complaint 1 "<li>Message key number $counter is empty. Cannot replace text with empty key</li>"
            ad_script_abort
        }
    } else {
        # Empty string indicates no replacement
        lappend message_key_list ""
    }
}

set next_file [lindex $files 0]

set page_title "Internationalizing file $next_file"
set context_bar [ad_context_bar $page_title]

# Figure out which actions to take on the selected adp:s
set replace_text_p [ad_decode [lsearch -exact $file_action replace_text] "-1" "0" "1"]
set replace_tags_p [ad_decode [lsearch -exact $file_action replace_tags] "-1" "0" "1"]

# We need either or both of the actions to be selected
if { (! $replace_text_p) && (! $replace_tags_p) } {
    ad_return_complaint 1 "Invalid HTML Parameters: you must choose an action to take on selected adp files, either replace_text or replace_tags or both."
    ad_script_abort
}

# Do text replacement
if { $replace_text_p } {
    # Process the next file in the list
    set text_file $next_file
    set number_of_processed_files 1

    ns_log Notice "Replacing text in file $text_file with message tags"
    append processing_html_result "<h3>Text replacements for $text_file</h3>"
    set adp_text_result_list [lang::util::replace_adp_text_with_message_tags "$::acs::rootdir/$text_file" write $message_key_list]
    set text_replacement_list [lindex $adp_text_result_list 0]
    set text_untouched_list [lindex $adp_text_result_list 1]

    append processing_html_result "<b>Replaced [llength $text_replacement_list] texts</b>: <br>"
    foreach text_replacement $text_replacement_list {
        append processing_html_result "replaced text \"[lindex $text_replacement 1]\" using key [lindex $text_replacement 0] <br>"
    }

    if { [llength $text_untouched_list] > 0 } {
        append processing_html_result "<br> [llength $text_untouched_list] pieces of text were left untouched. Please take note of these texts and do any necessary translations by manually inserting <#message_key text#> tags in the adp file (the message keys should contain only letters and underscores). At a later stage you can then run the action \"Replace tags with text and insert into catalog\" on the file. The texts to consider for translation are: <br>"
    } else {
        append processing_html_result "<br> [llength $text_untouched_list] pieces of text were left untouched."
    }
    foreach untouched_text $text_untouched_list {
        append processing_html_result "\"$untouched_text\" <br>"
    }
}

# Do tag replacement
set total_number_of_replacements "0"
if { $replace_tags_p } {
    if { $replace_text_p } {
        # We are also replacing text, so only process one adp file
        set tags_files $next_file
        set number_of_processed_files 1
    } else {
        # We are only doing tag replacement, so process all files
        set tags_files $files
        set number_of_processed_files [llength $files]
    }

    foreach file $tags_files {
        ns_log Notice "Replacing tags in file $file with keys and doing insertion into message catalog"
        append processing_html_result "<h3>Message tag replacements for $file</h3>"

        set number_of_replacements [lang::util::replace_temporary_tags_with_lookups $file]
        set total_number_of_replacements [expr {$total_number_of_replacements + $number_of_replacements}]

        append processing_html_result "Did $number_of_replacements replacements, see the log file for details"
    }
}    

# Remove the processed file from the file list.
set files [lrange $files $number_of_processed_files end]

# The proceed link will be to the next adp file if there is one and back to the I18N page
# if we're done
set proceed_url_export_vars [export_vars {version_id files:multiple file_action:multiple}]
if { [llength $files] > 0 } {
    # There are no more files to process so present a link back to the i18n page for this version
    set proceed_url "version-i18n-process?${proceed_url_export_vars}"
    set proceed_label "<b>Process next adp file</b>"

} else {
    # There are more files to process. This means we are doing text replacements
    # so present a link back to the page for choosing keys for the next adp file
    set proceed_url "version-i18n?${proceed_url_export_vars}"
    set proceed_label "Return to the I18N page for this package"

    # If we are done with message tag replacement, that means we have added new messages
    # so reload the cache
    if { $replace_tags_p && $total_number_of_replacements > 0 } {
        lang::message::cache
    }
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
