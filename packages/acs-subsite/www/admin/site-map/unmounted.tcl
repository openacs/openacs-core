ad_page_contract {

    Display all readable unmounted packages

    @author bquinn@arsdigita.com
    @creation-date 2000-09-12
    @cvs-id $Id$

}

doc_body_append "[ad_header "Unmounted Packages"]
<h2>Unmounted Packages </h2>
[ad_context_bar [list "index" "Site Map"] "Unmounted Packages"]
<hr>

The following application packages are not mounted anywhere.  You can delete an unmounted package 
by clicking the \"delete\" option.  
<ul>
"

set user_id [ad_conn user_id]

db_foreach packages_normal_select {} {
    doc_body_append "<li>$name \[<a href=\"instance-delete?[export_url_vars package_id]\" onclick=\"return confirm('Are you sure you want to delete package $name');\">delete</a>\]"
} if_no_rows {
    doc_body_append "<i>There are no unmounted packages</i>"
}

doc_body_append "</ul> <p />

The following services are singleton packages and are usually not meant to
be mounted anywhere.  Be careful not to delete a service that is in use as this
can potentially break the system.

<ul>"

db_foreach packages_singleton_select {} {
    doc_body_append "<li>$name \[<a href=\"instance-delete?[export_url_vars package_id]\" onclick=\"return confirm('Are you sure you want to delete package $name');\">delete</a>\]"
} if_no_rows {
    doc_body_append "<i>There are no unmounted singleton packages</li>"
}

doc_body_append "
</ul>

[ad_footer]
"
