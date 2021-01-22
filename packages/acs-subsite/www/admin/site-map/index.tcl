ad_page_contract {

    @author rhs@mit.edu
    @author bquinn@arsidigta.com
    @creation-date 2000-09-09
    @cvs-id $Id$

} {
    {expand:integer,multiple ""}
    {new_parent:integer ""}
    {new_type ""}
    {root_id:naturalnum ""}
    {new_application:integer ""}
    {rename_application:integer {}}
}

if {$root_id eq ""} {
    set root_id [ad_conn node_id]
}

# We do a check for the admin privilege because a user could have
# admin privilege on a site_node that has other site_nodes beneath it
# that the user does not have admin privilege on.  If we don't do this
# check, the user could end up making changes on site_nodes that he
# does not have the admin privilege for.

array set node [site_node::get -node_id $root_id]
set parent_id $node(parent_id)
set object_id $node(object_id)

if {$object_id ne ""} {
    permission::require_permission -object_id $object_id -privilege admin
}

# if {$new_parent ne ""} {
#     set onload "document.new_parent.name.focus();document.new_parent.name.select();"
# } elseif {$new_application ne ""} {
#     set onload "document.new_application.instance_name.focus();document.new_application.instance_name.select();"
# } elseif {$rename_application ne ""} {
#     set onload "document.rename_application.instance_name.focus();document.rename_application.instance_name.select();"
# } else {
#     set onload ""
# }
#
# if {$onload ne ""} {
#     template::add_body_handler -event onload -script $onload
# }
#
#template::add_body_script -script {
#    function check_checkbox () {
#        window.document.nodes.node_id.checked = 'true';
#    }
#}


set parent_link [export_vars -base . {expand:multiple {root_id $parent_id}}]

set doc(title) [_ acs-subsite.Site_Map]
set context [list $doc(title)]

set user_id [ad_conn user_id]

set subsite_number [db_string count_subsites {
    select count(*) from apm_packages where package_key = 'acs-subsite'
}]
#
# Not sure, what the intentions was to omit all(!) subsites if there
# are more than 100. e.g. http://openacs.org/bugtracker/openacs/bug?bug_number=3174
# Subsite-omitting is deactivated for the time being.
#
if {0 && $subsite_number > 100} {
    set too_many_subsites_p 1
    set where_limit "where p.package_key <> 'acs-subsite'"
} else {
    set too_many_subsites_p 0
    set where_limit ""
}

db_foreach path_select {} {
    if {$node_id != $root_id && $admin_p == "t"} {
        append head [subst {<a href="[ns_quotehtml [export_vars -base . {expand:multiple {root_id $node_id}}]]">}]
    }
    if {$name eq ""} {
        append head "$obj_name:"
    } else {
        append head $name
    }

    if {$node_id != $root_id && $admin_p == "t"} {
        append head "</a>"
    }

    if {$directory_p == "t"} {
        append head "/"
    }
} if_no_rows {
    append head "&nbsp;"
}

if {[llength $expand] == 0} {
    lappend expand $root_id
    if { $parent_id ne "" } {
        lappend expand $parent_id
    }
}

template::list::create \
    -name nodes \
    -multirow nodes \
    -key node_id \
    -elements {
        name {
            label "URL"
            html "align left"
            display_template {
                <if @nodes.node_id@ ne -99999>
                  <a name="@nodes.node_id@">@nodes.tree_indent;noquote@</a>
                <if @nodes.expand_mode@ eq 1>
                  (<a href="?@nodes.expand_url@#@nodes.node_id@">+</a>)
                </if>
                <if @nodes.expand_mode@ eq 2>
                  (<a href="?@nodes.expand_url@#@nodes.node_id@">-</a>)
                </if>
                <if @nodes.instance_url@ ne none>
                  <a href="@nodes.name_url@">@nodes.name;noquote@</a>
                </if><else>
                  @nodes.name;noquote@
                </else>
                <if @nodes.action_type@ eq "new_folder">
                <form name="new_parent" action="new">
                <div>@nodes.tree_indent;noquote@
                @nodes.action_form_part;noquote@
                <input name="name" type="text" size="8" value="Untitled">
                <input type="submit" value="New"></div>
                </form>
                </if>
                </if>
                <else>
                  @nodes.name;noquote@
                </else>
            }
        } instance {
            label "Instance"
            html "align left"
            display_template {
                <if @nodes.action_type@ eq "new_app">
                <form name="new_application" action="package-new">
                <div><input name="instance_name" type="text" size="8" value="">
                @nodes.action_form_part;noquote@
                <input type="submit" value="New"></div>
                </form>
                </if>
                <if @nodes.action_type@ eq "rename_app">
                <form name="rename_application" action="rename">
                <div><input name="instance_name" type="text" value="@nodes.instance@">
                @nodes.action_form_part;noquote@
                <input type="submit" value="Rename"></div>
                </form>
                </if>
                <else>
                <a href="@nodes.instance_url@">@nodes.instance;noquote@</a>
                </else>
            }
        } type {
            label "Package Type"
            html "align left"
            display_template {
                @nodes.type;noquote@
            }
        } actions {
            label "Action"
            html "align left"
            display_template {
                <if @nodes.add_folder_url@ ne "">
                  <a href="@nodes.add_folder_url@#add">[_ acs-subsite.add_folder]</a>
                </if>
                <if @nodes.new_app_url@ ne "">
                  <a href="@nodes.new_app_url@#new">[_ acs-subsite.new_application]</a>
                </if>
                <if @nodes.unmount_url@ ne "">
                  <a href="@nodes.unmount_url@">[_ acs-subsite.unmount]</a>
                </if>
                <if @nodes.mount_url@ ne "">
                  <a href="@nodes.mount_url@">[_ acs-subsite.mount]</a>
                </if>
                <if @nodes.rename_url@ ne "">
                  <a href="@nodes.rename_url@#rename">[_ acs-subsite.rename]</a>
                </if>
                <if @nodes.delete_url@ ne "">
                <a href="@nodes.delete_url@" id="@nodes.delete_id;literal@">[_ acs-subsite.delete]</a>
                </if>
                <if @nodes.parameters_url@ ne "">
                  <a href="@nodes.parameters_url@">[_ acs-subsite.parameters]</a>
                </if>
                <if @nodes.permissions_url@ ne "">
                  <a href="@nodes.permissions_url@">[_ acs-subsite.permissions]</a>
                </if>
                <if @nodes.extra_form_part@ ne "">
                  @nodes.extra_form_part;noquote@
                </if>
            }
        }
    }

multirow create nodes \
    node_id expand_mode expand_url tree_indent name name_url instance instance_url type \
    action_type action_form_part add_folder_url new_app_url unmount_url mount_url \
    rename_url delete_url parameters_url permissions_url extra_form_part delete_id

set open_nodes [list]

db_foreach nodes_select {} {
    set add_folder_url ""
    set new_app_url ""
    set unmount_url ""
    set mount_url ""
    set rename_url ""
    set delete_url ""
    set parameters_url ""
    set permissions_url ""

    if { $parent_id ni $open_nodes && $parent_id ne "" && $mylevel > 2 } { continue }

    if {$directory_p == "t"} {
        set add_folder_url [export_vars -base . {expand:multiple root_id node_id {new_parent $node_id} {new_type folder}}]
        if {$object_id eq ""} {
            set mount_url [export_vars -base mount {expand:multiple root_id node_id}]
            set new_app_url [export_vars -base . {expand:multiple root_id {new_application $node_id}}]
        } else {
            # This makes sure you can't unmount the thing that is serving the page you're looking at.
            if {[ad_conn node_id] != $node_id} {
                set unmount_url [export_vars -base unmount {expand:multiple root_id node_id}]
            }

            # Add a link to control permissioning
            if {$object_admin_p} {
                set permissions_url [export_vars -base "../../permissions/one" {object_id}]
                set rename_url [export_vars -base . {expand:multiple root_id {rename_application $node_id}}]
                set delete_url [export_vars -base instance-delete {{package_id $object_id} root_id}]
            }
            # Is the object a package?
            if {$package_id ne ""} {
                if {$object_admin_p && ($parameter_count > 0)} {
                    set parameters_url [export_vars -base "/shared/parameters" { package_id {return_url {[ad_return_url]} } }]
                }
            }
        }
    }

    if {[ad_conn node_id] != $node_id && $n_children == 0 && $object_id eq ""} {
        set delete_url [export_vars -base delete {expand:multiple root_id node_id}]
    }

    # use the indent variable to hold current indent level we'll use it later to indent stuff at the end by the amount of the last node
    set indent ""
    for {set i 0} {$i < 3*$mylevel} {incr i} {
        append indent "&nbsp;"
    }

    set expand_mode 0
    if {!$root_p && $n_children > 0} {
        set expand_mode 1
        set urlvars [list]
        foreach n $expand {
            if {$n == $node_id} {
                set expand_mode 2
                lappend open_nodes "$node_id"
            } else {
                lappend urlvars "expand=$n"
            }
        }

        if { $expand_mode == 1} {
            lappend urlvars "expand=$node_id"
        }

        lappend urlvars "root_id=$root_id"

        set expand_url [join $urlvars "&"]
    } else {
        set expand_url ""
    }

    set name_url [export_vars -base . {expand:multiple {root_id $node_id}}]

    set action_type 0
    set action_form_part ""

    if {$object_id eq ""} {
        if {$new_application == $node_id} {

            set action_type "new_app"
            set action_form_part "[export_vars -form {expand:multiple root_id node_id new_package_id}] [apm_application_new_checkbox]"

            #Generate a package_id for double click protection
            set new_package_id [db_nextval acs_object_id_seq]
        } else {
            set action_form_part "(none)"
        }
    } elseif {$rename_application == $node_id} {
        set action_type "rename_app"
        set action_form_part [export_vars -form {expand:multiple root_id node_id rename_package_id}]

    } else {}

    if {$node_id == $new_parent} {
        set parent_id $new_parent
        set node_type $new_type
        set action_type "new_folder"
        set action_form_part [export_vars -form {expand:multiple parent_id node_type root_id}]
    }
    set delete_id delete-$node_id
    
    multirow append nodes \
        $node_id $expand_mode $expand_url $indent $name $name_url $object_name $url $package_pretty_name \
        $action_type $action_form_part $add_folder_url $new_app_url $unmount_url $mount_url \
        $rename_url $delete_url $parameters_url $permissions_url "" $delete_id

    template::add_confirm_handler \
        -id $delete_id \
        -message "Are you sure you want to delete node $name and any package mounted there?"
}

set new_app_form_part_1 [subst {
    <form name="new_application" action="package-new">
    <div>
    <input type="hidden" name="node_id" value="$node(node_id)">
    <input type="hidden" name="root_id" value="$node(node_id)">
    <input type="hidden" name="new_node_p" value="t">[export_vars -form {expand:multiple}]
    <input name="node_name" type="text" size="8">
    </div>
}]

set new_app_form_part_2 <div>[apm_application_new_checkbox]</div>
set new_app_form_part_3 {
    <div><input type="submit" value="Mount Package"></div>
    </form>
}

append new_app_form  $new_app_form_part_1 $new_app_form_part_2 $new_app_form_part_3

#multirow append nodes -99999 \
    "" "" "" $new_app_form_part_1 \
    "" "" "" $new_app_form_part_2 \
    "" "" "" "" "" "" "" "" "" "" $new_app_form_part_3

multirow append nodes -99999 \
    "" "" "" "Mount an additional package at: $new_app_form"


set services ""

db_foreach services_select {} {
    if {$parameter_count > 0} {
        set href [export_vars -base /shared/parameters { package_id { return_url {[ad_return_url]} } }]
        append services "<li><a href=\"[ns_quotehtml $href]\">[ns_quotehtml $instance_name]</a>"
    }
} if_no_rows {
    append services "  <li>(none)\n"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
