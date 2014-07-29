# packages/acs-subsite/www/admin/site-map/rename.tcl

# Copyright (C) 2002 Red Hat

# This file is part of ACS.
#
# ACS is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# ACS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ACS; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

ad_page_contract {
    packages/acs-subsite/www/admin/site-map/rename.tcl

    @author bdolicki@redhat.com
    @creation-date 2000-06-20
    @cvs-id $Id$
} {
  node_id:naturalnum,notnull
  instance_name:notnull
  {expand:integer,multiple {}}
  root_id:naturalnum,optional
}

# (bran 2000-06-20) Here I am assuming that only packages can be hung
# on site_nodes.  Until we have a general framework for mutators
# I can hardly do anything better.

set package_id [site_node::get_object_id -node_id $node_id]

apm_package_rename \
    -package_id $package_id \
    -instance_name $instance_name


ad_returnredirect [export_vars -base "." { expand:multiple root_id }]
