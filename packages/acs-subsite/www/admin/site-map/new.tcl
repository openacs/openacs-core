ad_page_contract {

    @author Rafael Schloming (rhs@mit.edu)
    @creation-date 2000-09-09
    @cvs-id $Id$

} {
    parent_id:naturalnum,notnull
    name:notnull
    node_type:notnull
    {expand:integer,multiple {}}
    {root_id:naturalnum,notnull {}}
} -validate {
    name_root_ck -requires name:notnull {
        if {[string match "*/*" $name]} {
            ad_complain
        }
    }
    name_duplicate_ck -requires name_root_ck {
        if {[db_string site_node_duplicate_name_root_ck {} -default 0]} {
            ad_complain
        }
    }
    node_type_ck -requires node_type:notnull {
        switch $node_type {
            folder {
                set directory_p t
                set pattern_p t
            }
            file {
                set directory_p f
                set pattern_p f
            }
            default {
                ad_complain
            }
        }
    }
} -errors {
    name_root_ck {Folder or file names cannot contain '/'}
    name_duplicate_ck {The URL mapping you are creating is already in use.  Please delete the other one or change your URL.}
    node_type_ck {The node type you specified is invalid}
}

set user_id [ad_conn user_id]
set ip_address [ad_conn peeraddr]

db_transaction {
    set node_id [site_node::new \
        -name $name \
        -parent_id $parent_id \
        -directory_p $directory_p \
        -pattern_p $pattern_p \
    ]
} on_error {
    ad_return_complaint \
        "Error Creating Site Node" \
        "The following error was generated when attempting to create the site node:
        <blockquote><pre>
                [ad_quotehtml $errmsg]
        </pre></blockquote>"
}

if {[lsearch $expand $parent_id] == -1} {
    lappend expand $parent_id
}

ad_returnredirect [export_vars -base . {expand:multiple root_id}]
