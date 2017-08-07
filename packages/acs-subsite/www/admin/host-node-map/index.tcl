ad_page_contract {
    @author Mark Dettinger (mdettinger@arsdigita.com)
    @author Michael Steigman (michael@steigman.net)
    @creation-date 2000-10-24
    @cvs-id $Id$
} {
    {parent_node_id:naturalnum ""}
}

set page_title [_ acs-subsite.Host_Node_Map]
set context [list $page_title]

template::list::create \
    -name host_node_pairs \
    -multirow host_node_pairs \
    -key node_id \
    -elements {
	host {
	    label "[_ acs-subsite.Hostname]"
	}
	node_id {
	    label "[_ acs-subsite.Root_Node]"
	} 
	url {
	    label "[_ acs-subsite.Root_URL]"
	}
	delete_url {
	    display_template "<if @host_node_pairs.delete_url@ not nil><a href=\"@host_node_pairs.delete_url@\" title=\"Delete this mapping\">delete</a></if>"
	}
    }
	    
template::multirow create host_node_pairs host node_id url delete_url
template::multirow append host_node_pairs \
    [ns_config ns/server/[ns_info server]/module/nssock Hostname] \
    [db_string root_id {}] \
    "/" \
    ""

db_multirow -extend {delete_url} -append host_node_pairs select_host_node_pairs {} {
    set delete_url [export_vars -base delete {host node_id}]
}


if {$parent_node_id eq ""} {
    set parent_node_id [site_node::get_node_id -url "/"]
}

set node_list [list]
foreach node_id [site_node::get_children -element node_id -node_id $parent_node_id] {
    set has_children_p [expr {[site_node::get_children -element node_id -node_id $node_id] ne ""}]
    set url [site_node::get_element -node_id $node_id -element url]
    if {$has_children_p} {
        set url "<a href='?parent_node_id=$node_id'>$url</a>"
    }
    lappend node_list [list $url $node_id]
}
set sorted_node_list [lsort -dictionary $node_list]

ad_form -name add_host_node_mapping -export {parent_node_id} -form {
    {host:text(text)
	{label "[_ acs-subsite.Hostname]"}
	{html {size 40}}
	{value "mydomain.com"}
	{help_text "[_ acs-subsite.Hostname_must_be_unique]"}
    }
    {root:text(radio)
	{label "[_ acs-subsite.Root_Node]"}
	{options $sorted_node_list}
	{help_text "[_ acs-subsite.Site_node_you_would_like_to_map_hostname_to]"}
    }
    {submit:text(submit)
	{label "[_ acs-subsite.Add_Pair]"}
    }
} -validate {
    {host
	{![db_string check_host {select 1 from host_node_map where host = :host} -default 0]}
         "Host must be unique"
    }
} -on_submit {
    util_memoize_flush_regexp "rp_lookup_node_from_host"
    db_flush_cache -cache_key_pattern security-locations-host-names
    db_flush_cache -cache_key_pattern ad_get_host_node_map

    db_dml host_node_insert {}
} -after_submit {
    ad_returnredirect index
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
