ad_library {
    Interface to the ACS for the ArsDigita Templating System
    Procedures in this file only make sense if you use the template system
    together with the ArsDigita Community System
    
    @author Christian Brechbuehler <christian@arsdigita.com>
    
    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


ad_proc -public ad_return_template {
    -string:boolean
    {template ""}
} {
    This function is a wrapper for sundry template:: procs. Will set the 
    template for the current page to the file named in 'template'. 

    @param template Name of template file 

    @param string If specified, will return the resulting page to the caller
    string instead sending it to the connection.
} {
    if {$template ne ""} {
        template::set_file \
            [template::util::url_to_file $template [ad_conn file]]
    }
    
    if { $string_p } {
        return [template::adp_parse \
                    [template::util::url_to_file $template [ad_conn file]] {}]
    }
}

ad_proc -public ad_parse_template {
    {-params ""}
    template
} {
    Return a string containing the parsed and evaluated template to the caller.

    @param params The parameters to pass to the template. Note that pass-by-reference params must be in the page namespace, they cannot be in a local procedure, or any other namespace.

    @param template The template file name.

    Example:

    <code>set page [ad_parse_template -params {errmsg {custom_message "My Message"}} some-template]</code>

    @param template Name of template file
} {
    set template_params [list]
    foreach param $params {
        switch [llength $param] {
            1 { lappend template_params "&" [lindex $param 0] }
            2 { lappend template_params [lindex $param 0] [lindex $param 1] }
            default { return -code error [_ acs-templating.Template_parser_error_in_parameter_list] }
        }
    }
    return [uplevel [list template::adp_parse [template::util::url_to_file $template [ad_conn file]] $template_params]]
}


ad_proc -public ad_return_exception_template {
    {-status 500}
    {-params ""}
    template
} {
    Return an exception template and abort the current script.

    @param status The HTTP status to return, by default HTTP 500 (Error)
    @param params The parameters to pass to the template.
    @param template The template file name.

    Example:

    <code>ad_return_exception_template -params {errmsg {custom_message "My Message"}} some-template</code>
} {
    ns_return $status text/html [ad_parse_template -params $params $template]
    ad_script_abort
}

ad_proc -public get_server_root {} {
    Get the server root directory (supposing we run under ACS)
} {
    return $::acs::rootdir
}


ad_proc adp_parse_ad_conn_file {} {
    
    Handle a request for an adp and/or Tcl file in the template system
    based on the current setting of [ad_conn file]. This file is
    registered via rp_register_extension_handler

    @see rp_register_extension_handler
} {
    set ::template::parse_level ""
    #ns_log debug "adp_parse_ad_conn_file => file '[file rootname [ad_conn file]]'"
    template::reset_request_vars

    #
    # [ad_conn file] is always an absolute name, remove the
    # acs::rootdir, compute the template and add the acs::rootdir
    # again.
    #
    set absolute_file [ad_conn file]
    set relative_name [string range $absolute_file [string length $::acs::rootdir] end]
    set themed_template $::acs::rootdir/[template::themed_template [file rootname $relative_name]]
    set parsed_template [template::adp_parse $themed_template {}]

    if {$parsed_template ne ""} {
        
        #
        # acs-lang translator mode
        #

        if { [lang::util::translator_mode_p] } {
            set apm_package_url [apm_package_url_from_key "acs-lang"]
            
            # Attempt to move all message keys outside of tags
            while { [regsub -all {(<[^>]*)(\x02\(\x01[^\x01]*\x01\)\x02)([^>]*>)} $parsed_template {\2\1\3} parsed_template] } {}
            
            # Attempt to move all message keys outside of <select>...</select> statements
            regsub -all -nocase {(<option\s[^>]*>[^<]*)(\x02\(\x01[^\x01]*\x01\)\x02)([^<]*</option[^>]*>)} $parsed_template {\2\1\3} parsed_template

            while { [regsub -all -nocase {(<select[^>]*>[^<]*)(\x02\(\x01[^\x01]*\x01\)\x02)} $parsed_template {\2\1} parsed_template] } {}

            set start 0
            while { [regexp -nocase -indices -start $start {(<select[^\x02]*)(\x02\(\x01[^\x01]*\x01\)\x02)} $parsed_template indices select_idx message_idx] } {
                set select [string range $parsed_template [lindex $select_idx 0] [lindex $select_idx 1]]

                if { [string first "</select" [string tolower $select]] != -1 } {
                    set start [lindex $indices 1]
                } else {
                    set before [string range $parsed_template 0 [lindex $indices 0]-1]
                    set message [string range $parsed_template [lindex $message_idx 0] [lindex $message_idx 1]]
                    set after [string range $parsed_template [lindex $indices 1]+1 end]
                    set parsed_template "${before}${message}${select}${after}"
                }
            }

            # TODO: We could also move message keys out of <head>...</head>

            while { [regexp -indices {\x02\(\x01([^\x01]*)\x01\)\x02} $parsed_template indices key] } {
                set before [string range $parsed_template 0 [lindex $indices 0]-1]
                set after [string range $parsed_template [lindex $indices 1]+1 end]

                set key [string range $parsed_template [lindex $key 0] [lindex $key 1]]
                lassign [split $key "."] package_key message_key

                set edit_url [export_vars -base "${apm_package_url}admin/edit-localized-message" { 
                    { locale {[ad_conn locale]} } package_key message_key { return_url [ad_return_url] } }]

                if { [lang::message::message_exists_p [ad_conn locale] $key] } {
                    set edit_link [subst {<a href="[ns_quotehtml $edit_url]" title="$key" style="color: green;"><b>o</b></a>}]
                } else {
                    if { [lang::message::message_exists_p "en_US" $key] } {
                        # Translation missing in this locale
                        set edit_link [subst {<a href="[ns_quotehtml $edit_url]" title="$key" style="background-color: yellow; color: red;"><b>*</b></a>}]
                    } else {
                        # Message key missing entirely
                        set new_url [export_vars -base "${apm_package_url}admin/localized-message-new" { 
                            { locale en_US } package_key message_key { return_url [ad_return_url] }
                        }]
                        set edit_link [subst {<a href="[ns_quotehtml $new_url]" title="$key" style="background-color: red; color: white;"><b>@</b></a>}]
                    }
                }

                set parsed_template "${before}${edit_link}${after}"
            }
        }

        set mime_type [template::get_mime_type]
        set header_preamble [template::get_mime_header_preamble $mime_type]
        doc_return 200 $mime_type "$header_preamble$parsed_template"
    } else {
        db_release_unused_handles
    }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

