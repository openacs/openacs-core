# File:        set-enabled.tcl
# Package:     developer-support
# Author:      jsalz@mit.edu
# Date:        22 June 2000
# Description: Enables or disables developer support data collection.
#
# $Id$

ad_page_variables {
    enabled_p
}

ds_require_permission [ad_conn package_id] "admin"

nsv_set ds_properties enabled_p $enabled_p
ad_returnredirect "index"
