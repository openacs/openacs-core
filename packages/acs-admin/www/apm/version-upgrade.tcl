ad_page_contract {

    Upgrades an older version of a package to one that a newer version that is locally
    maintained.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date Thu Oct 12 17:45:38 2000
    @cvs-id $Id$
} {
    version_id
}
apm_version_info $version_id

# Disable all previous versions of this packae.
apm_version_upgrade $version_id

# Instruct user to run SQL upgrade scripts.

doc_body_append "[apm_header "Upgrading to $pretty_name $version_name"]
<p>
$pretty_name $version_name has been enabled.  Please run any necessary
SQL upgrade scripts to finish updating the data model and restart
the server.
[ad_footer]
"
