ad_page_contract {
    Create and mount a new Subsite/Community.

    @author Steffen Tiedemann Christensen (steffen@christensen.name)
    @creation-date 2003-09-26
} {
    node_id:integer,optional
}

if ([string equal [ad_conn package_url] "/"]) {
    set page_title "New community"
    set subsite_pretty_name "Community name"
} else {
    set page_title "New subcommunity"
    set subsite_pretty_name "Subcommunity name"
}
set context [list [list "." "Communities"] $page_title]
set focus application.instance_name

set package_key acs-subsite

ad_form -name subsite -cancel_url . -form {
    {node_id:key}
    {instance_name:text
        {label $subsite_pretty_name}
        {help_text "The name of the new community you're setting up."}
        {html {size 30}}
    }
    {folder:text,optional
        {label "URL folder name"}
        {help_text "This should be a short string, all lowercase, with hyphens instead of spaces, whicn will be used in the URL of the new application. If you leave this blank, we will generate one for you from name of the application."}
        {html {size 30}}
    }
} -on_submit {
    if { ![empty_string_p $folder] } {
        set existing_node(node_id) {}
        set errno [catch { array set existing_node [site_node::get_from_url -exact -url "[ad_conn package_url]$folder"] }]
        if { ([ad_form_new_p -key node_id] && !$errno) || (![ad_form_new_p -key node_id] && !$errno && $existing_node(node_id) != $node_id)} {
            form set_error application folder "This folder name is already used"
            break
        }
    } else {
        # Autogenerate folder name
        set parent_node_id [ad_conn node_id]
        set existing_urls [site_node::get_children -node_id $parent_node_id -element name]

        set folder [util_text_to_url -existing_urls $existing_urls -text $instance_name]
    }
} -new_data {
    if { [catch {
        site_node::instantiate_and_mount -parent_node_id [ad_conn node_id] -node_name $folder -package_name $instance_name -package_key $package_key
    } errsmg] } {
        ad_return_error "Problem Creating Application" "We had a problem creating the community."
    }
} -after_submit {
    ad_returnredirect ../$folder
    ad_script_abort
}
