ad_page_contract {

    top level list of forums

    @author Ben Adida (ben@openforce.net)
    @creation-date 2002-05-24
    @cvs-id $Id$

} {
    {page ""}
    {page_size 25}
    {orderby "username,asc"}
}


set user_id [ad_conn user_id]

template::list::create \
    -name bouncing_users \
    -multirow bouncing_users \
    -key forum_id \
    -elements {
	username {
	    label "[_ acs-subsite.Username]"
	}
	full_name {
	    label "[_ acs-subsite.Name]"
	    display_template {<pre>@bouncing_users.full_name;noquote@</pre>}
	}
	unbounce_link {
	    label ""
	    display_template {<a href="@bouncing_users.unbounce_link;noquote@">[_ acs-mail-lite.Unbounce]</a>}
	}
    } -orderby {
	username {
	    orderby_asc "username asc"
	    orderby_desc "username desc"
	    default_direction asc
	} 
        full_name {
	    orderby_asc "full_name asc"
	    orderby_desc "full_name desc"
	    default_direction asc
	} 
    }


db_multirow -extend {unbounce_link} bouncing_users select_bouncing_users {} {
    set return_url [ad_return_url]
    set unbounce_link [export_vars -base "/register/restore-bounce" -url {user_id return_url}]
}

set context [list [list "." "Users"] "[_ acs_mail_lite.Bouncing_users]"]
