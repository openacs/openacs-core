ad_page_contract {

    @author Peter Marklund
    @creation-date 28 January 2003
    @cvs-id $Id$  
} {
    version_id:integer,notnull    
}

db_1row package_version_info "select pretty_name, version_name from apm_package_version_info where version_id = :version_id"

set page_title "Tcl Callbacks"
set context [list [list "." "Package Manager"] [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] $page_title]

set unused_callback_types [apm_unused_callback_types -version_id $version_id]

if { [llength $unused_callback_types] > 0  } {
    set actions [list "Add callback" [export_vars -base "version-callback-add-edit" { version_id }]]
} else {
    set actions [list]
}


template::list::create \
    -name callbacks \
    -multirow callbacks \
    -actions $actions \
    -elements {
        edit {
            label {}
            sub_class narrow
            display_template {
                <img src="/resources/acs-subsite/Edit16.gif" width="16" height="16" border="0">
            } 
            link_url_eval {[export_vars -base "version-callback-add-edit" { version_id type }]}
            link_html { title "Edit callback" }
        }
        type {
            label "Type"
        }
        proc {
            label "Tcl Proc"
        }
        invoke {
            label "Invoke"
            display_template {<if @callbacks.type@ in "before-install" "after-install" "before-uninstall" "after-uninstall">Invoke</if><else><i style="color: gray;">N/A</i></else>}
            link_url_eval {[ad_decode [lsearch { before-install after-install before-uninstall after-uninstall } $type] -1 {} [export_vars -base "version-callback-invoke" { version_id type }]]}
            link_html { title "Invoke this callback proc now. Be careful!" }
            html { align center }
        }
        delete {
            label {}
            sub_class narrow
            display_template {
                <img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" border="0">
            } 
            link_url_eval {[export_vars -base "version-callback-delete" { version_id type }]}
            link_html { title "Delete callback" }
        }
    }

db_multirow callbacks get_all_callbacks {
    select version_id,
           type,
           proc
    from apm_package_callbacks
    where version_id = :version_id
    order by type
}

ad_return_template
