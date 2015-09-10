ad_page_contract {
   
    @author Emmanuelle Raffenne (eraffenne@gmail.com)
    @creation-date 22-feb-2010
    @cvs-id $Id$

} {    
    mime_type:notnull
}

set mime_type_label [db_string get_mime_type {} -default $mime_type]

set doc(title) "Extensions Mapped to $mime_type_label"
set context [list [list "./" "Mime Types"] $doc(title)]

set return_url [export_vars -base "extensions" {mime_type}]

set actions [list "Add extension" [export_vars -base "map" {mime_type return_url}] ""]

template::list::create \
    -name extensions \
    -multirow extensions \
    -actions $actions \
    -elements {
        mime_type {
            label "MIME type"
        }
        extension {
            label "Extension"
        }
        action {
            label "Action"
            link_url_col action_url
        }
    }

db_multirow -extend {action action_url} extensions get_extensions {} {
    set action_url [export_vars -base "unmap" {mime_type extension return_url}]
    set action "Unmap"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
