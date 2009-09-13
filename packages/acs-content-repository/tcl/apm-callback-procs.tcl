# /packages/acs-content-repository/tcl/apm-callback-procs.tcl

ad_library {

    APM callbacks library

    @creation-date July 2009
    @author  Emmanuelle Raffenne (eraffenne@gmail.com)
    @cvs-id $Id$

}

namespace eval content {}
namespace eval content::apm {}

ad_proc -public content::apm::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    APM callback executed on package upgrade.
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {  
            5.5.1d1 5.5.1d2 {    
                set mimetype_list [list \
                                       {"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" "xlsx" "Microsoft Office Excel"} \
                                       {"application/vnd.openxmlformats-officedocument.spreadsheetml.template" "xltx" "Microsoft Office Excel Template"} \
                                       {"application/vnd.openxmlformats-officedocument.presentationml.presentation" "pptx" "Microsoft Office PowerPoint Presentation"} \
                                       {"application/vnd.openxmlformats-officedocument.presentationml.slideshow" "ppsx" "Microsoft Office PowerPoint Slideshow"} \
                                       {"application/vnd.openxmlformats-officedocument.presentationml.template" "potx" "Microsoft Office PowerPoint Template"} \
                                       {"application/vnd.openxmlformats-officedocument.wordprocessingml.document" "docx" "Microsoft Office Word"} \
                                       {"application/vnd.openxmlformats-officedocument.wordprocessingml.template" "dotx" "Microsoft Office Word Template"}]

                foreach elm $mimetype_list {
                    cr_create_mime_type \
                        -mime_type [lindex $elm 0]  \
                        -extension [lindex $elm 1]  \
                        -description [lindex $elm 2]
                }
            }
        }
}
