ad_page_contract {

    Deinstalls a package from the filesystem, but leaves the database intact.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Fri Oct 13 08:45:58 2000
    @cvs-id $Id$
} {
    version_id:naturalnum
}

apm_version_info $version_id

set title "Deinstall"
set context [list [list "/acs-admin/apm/" "Package Manager"] \
		 [list "version-view?version_id=$version_id" "$pretty_name $version_name"] \
		 $title]

db_transaction {
    doc_body_append "<ul>"
    apm_package_deinstall -callback apm_doc_body_callback $package_key
    doc_body_append "</ul>"
} on_error {
    if {![apm_version_installed_p $version_id] } {
	ad_return_complaint 1 "Database Error: The database returned the following error
	message <pre><blockquote>[ad_quotehtml $errmsg]</blockquote></pre>"
    }
}

append body "<p>Return to the <a href='index'>index</a>"





