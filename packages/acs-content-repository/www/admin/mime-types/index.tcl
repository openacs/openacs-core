ad_page_contract {
   
    @author Emmanuelle Raffenne (eraffenne@gmail.com)
    @creation-date 22-feb-2010
    @cvs-id $Id$

} {
    { extension_p:boolean 0 }
    { orderby:token "mime_type" }
}

set return_url [export_vars -base "index" {extension_p orderby}]

set actions [list "Create MIME type" [export_vars -base "new" {return_url}] ""]

if { $extension_p } {

    set doc(title) "MIME Type Extension Map"

    lappend actions "Show MIME types only" [export_vars -base "./" {{extension_p 0}}] ""

    set elms {
        extension {
            label "Mapped extension"
            orderby "map.extension"
        }
        mime_type {
            label "MIME type"
            link_url_col extensions_url
            html {title  "Manage mapped extensions for this MIME type"}
            orderby "mime.mime_type"
        }
        label {
            label "Description"
            link_url_col extensions_url
            html {title  "Manage mapped extensions for this MIME type"}
            orderby "mime.label"
        }
        action {
            label "Action"
            link_url_col action_url
        }
    }

} else {

    set doc(title) "MIME Types"

    lappend actions "Show extension map" [export_vars -base "./" {{extension_p 1}}] ""

    set elms {
        mime_type {
            label "MIME type"
            link_url_col extensions_url
            html {title  "Manage mapped extensions for this MIME type"}
            orderby "mime_type"
        }
        label {
            label "Description"
            link_url_col extensions_url
            html {title  "Manage mapped extensions for this MIME type"}
            orderby "label"
        }
        extension {
            label "Default extension"
            orderby "extension"
        }
    }

}

template::list::create \
    -name mime_types \
    -multirow mime_types \
    -actions $actions \
    -orderby_name orderby \
    -bulk_action_export_vars {extension_p} \
    -elements $elms \
    -filters { extension_p }

if { $extension_p } {

    db_multirow -extend {extensions_url action action_url} mime_types get_mime_type_map {} {
        set extensions_url [export_vars -base "extensions" {mime_type}]
        if { $extension ne "" } {
            set action "unmap"
            set action_url [export_vars -base "unmap" {return_url extension mime_type}]
        }
    }

} else {

    db_multirow -extend {extensions_url} mime_types get_mime_types {} {
        set extensions_url [export_vars -base "extensions" {mime_type}]
    }

}

set context [list $doc(title)]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
