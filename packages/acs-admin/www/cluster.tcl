ad_page_contract {
    @author Gustaf Neumann

    @creation-date Feb 8, 2023
} {
    {disconnect_node:nohtml,notnull ""}
    {flush_node:nohtml,notnull ""}
}

set page_title "Cluster Management"
set context [list $page_title]

set server_cluster_enabled_p [server_cluster_enabled_p]

if {$server_cluster_enabled_p && [info commands acs::container] eq ""} {
    #
    # Probably, someone has just activated cluster mode without a
    # restart. We can still give a reasonable output by doing an
    # ad-hoch initialization.
    #
    nsv_set cluster cluster_peer_nodes ""
    ::acs::cluster setup
}

set dynamic_cluster_nodes [::acs::cluster dynamic_cluster_nodes]

if {$disconnect_node ne ""} {
    #
    # Disconnect the provided node from DynamicClusterPeers
    #
    acs::cluster dynamic_cluster_reconfigure disconnect $disconnect_node
    set done 1
} elseif {$flush_node ne ""} {
    #
    # The following command might send the request to the current
    # server.
    #
    acs::cluster send $flush_node acs::cache_flush_all
    set done 1
}
if {[info exists done]} {
    ad_returnredirect ./cluster
    ad_script_abort
}


if {$server_cluster_enabled_p} {
    set nsstats_location $::acs::rootdir/packages/acs-subsite/www/admin/nsstats.tcl
    set nsstats_available_p [file readable $nsstats_location]

    set current_node [acs::cluster cget -myLocation]
    set all_cluster_hosts [server_cluster_all_hosts]
    set active_peer_nodes [lsort [nsv_get cluster cluster_peer_nodes]]
    
    append page_title \
        [expr {[acs::cluster is_canonical_server $current_node] ? " (Canonical Server)" : " (Peer Node)"}]
    
    #ns_log notice "all_cluster_hosts <$all_cluster_hosts> active_peer_nodes <$active_peer_nodes>"
    set elements_list {
        state {
            label "State"
            html {align center}
            display_template {
                <if @cluster_nodes.state@ eq "active"><adp:icon class="text-success" name="checkbox-checked" title="Reachable"></a></if>
                <else><if @cluster_nodes.state@ eq "inactive"><adp:icon  class="text-danger" name="warn" title="Not Reachable"></a></if>
                <else>&nbsp;</else>
                </else>
            }
        }

        node_name {
            label "Node"
            orderby node_name
            display_template {
                <if @cluster_nodes.current_p@ true>@cluster_nodes.node_name@ (current)</if>
                <else><a href="@cluster_nodes.node_name@/acs-admin/cluster.tcl"
                       title="Goto Cluster Management of this node">@cluster_nodes.node_name@</a>
                </else>
            }
            html {style {white-space:nowrap;}}
        }
        canonical_p {
            label "Canonical"
            html {align center}
        }
        dynamic_p {
            label "Dynamic"
            html {align center}
        }
        peer_p {
            label "Peer"
            html {align center}
        }
        last_contact {
            label "Last Contact"
            orderby last_contact
            display_template {<if @cluster_nodes.last_contact@ not nil>@cluster_nodes.pretty_last_contact@</if>}
            html {align right style {white-space:nowrap;}}
        }
        last_request {
            label "Last Request"
            orderby last_request
            display_template {<if @cluster_nodes.last_request@ not nil>@cluster_nodes.pretty_last_request@</if>}
            html {align right style {white-space:nowrap;}}
        }
        actions {
            label "Actions"
            html {style {white-space:nowrap;}}
            display_template {
                <a href="@cluster_nodes.node_name@/acs-admin"><adp:icon name="admin" title="Node #acs-admin.Administration#"></a>&nbsp;
                <if @cluster_nodes.nsstats_available_p@ true>
                <a href="@cluster_nodes.node_name@/admin/nsstats.tcl?@page=process"><adp:icon name="graph-up" title="Node Statistics"></a>&nbsp;
                </if>
                <a href="./cluster?flush_node=@cluster_nodes.node_name@"><adp:icon name="bandaid" title="Flush Cache info about Node"></a>&nbsp;
                <if @cluster_nodes.current_p@ true><adp:icon name="trash" invisible="true"></if>
                <else><if @cluster_nodes.canonical_p@ true><adp:icon name="trash" invisible="true"></if>
                <else><a href="./cluster?disconnect_node=@cluster_nodes.node_name@"><adp:icon name="trash"
                      title="Disconnect Peer Node; trigger rejoin and flush in a few seconds when server is alive"></a></else>
                </else>
            }
        }
    }

    multirow create cluster_nodes state node_name current_p \
        canonical_p dynamic_p peer_p \
        last_contact pretty_last_contact \
        last_request  pretty_last_request \
        nsstats_available_p

    template::list::create -name cluster_nodes \
        -multirow cluster_nodes \
        -key node_name \
        -no_data "No Cluster Nodes are known." \
        -elements $elements_list

    foreach node $all_cluster_hosts {
        foreach var {last_contact last_request} {
            set value [set $var [acs::cluster $var $node]]
            set pretty_$var $value
            if {$value ne ""} {
                set seconds [expr {$value/1000}]
                if {[nsf::is object ::xowiki::utility]} {
                    set pretty_$var [::xowiki::utility pretty_age -timestamp $seconds]
                } else {
                    set pretty_$var "[expr {[clock seconds]-$seconds}]s ago"
                }
            }
        }
        if {$last_contact eq ""} {
            set state self
        } else {
            set timeunit [parameter::get \
                              -package_id $::acs::kernel_id \
                              -parameter ClusterHeartbeatInterval \
                              -default 20s ]
            set state [expr {[clock seconds]-($last_contact/1000) > [ns_baseunit -time $timeunit]
                             ? "inactive"
                             : "active"
                         }]
        }

        multirow append cluster_nodes \
            $state $node \
            [expr {$node eq $current_node}] \
            [acs::cluster is_canonical_server $node] \
            [expr {$node in $dynamic_cluster_nodes}] \
            [expr {$node in $active_peer_nodes}] \
            $last_contact $pretty_last_contact \
            $last_request $pretty_last_request \
            $nsstats_available_p
    }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
