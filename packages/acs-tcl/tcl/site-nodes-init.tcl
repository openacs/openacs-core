ad_library {

  @author rhs@mit.edu
  @creation-date 2000-09-07
  @cvs-id $Id$

}

nsv_set site_nodes_mutex mutex [ns_mutex create oacs:site_nodes]

site_node::init_cache

#
# In case, we have a recent version of NaviServer, we can use
# ns_urlspace for mapping tree data.
#
if {[info commands ns_urlspace] ne "" && [info commands ::xo::db::sql::site_node] ne ""} {
    #
    # Prefetch paths, which should not be mapped to the base node "/",
    # since these have to go through the classical mapping, where we
    # need for every possible path a single cache entry. By mapping eg
    # "/resources/*" to the sitenode of "/", we can remove this redundancy.
    #
    # The list of prefetched command can be extended via the config file
    #
    # ns_section ns/server/${server}/acs/acs-tcl
    #         ns_param SiteNodesPrefetch  {/file /changelogs /munin}
    #
    set extraPaths [parameter::get \
                        -package_id [apm_package_id_from_key acs-tcl] \
                        -parameter SiteNodesPrefetch \
                        -default {}]
    foreach path [list /repository /resources {*}$extraPaths] {
        set node_id [site_node::get_node_id -url $path]
        set cmd [list ns_urlspace set -key sitenode $path/* $node_id]
        ns_log notice "--- precache <$cmd> -> <$node_id>"
        {*}$cmd
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
