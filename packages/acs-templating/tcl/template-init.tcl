# Initialization of ArsDigita Templating System as a Tcl-only module

# Copyright (C) 1999-2000 ArsDigita Corporation
# Author: Karl Goldstein (karlg@arsdigita.com)
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# XXX (bquinn): This file should not be here.

# Register filters if ATS is installed as a Tcl "module".
# Actually, acs-templating is a package.

# ns_register_filter postauth GET *.acs acs_page_filter
# ns_register_filter postauth POST *.acs acs_page_filter
# ns_register_filter postauth GET */ acs_page_filter
# ns_register_filter postauth POST */ acs_page_filter

set pkg_id [apm_package_id_from_key acs-templating]

if { [ad_parameter -package_id $pkg_id ShowCompiledTemplatesP dummy 0] } {
  ns_register_filter postauth GET *.cmp cmp_page_filter
}

if { [ad_parameter -package_id $pkg_id ShowDataDictionariesP  dummy 1] } {
  ns_register_filter postauth GET *.dat dat_page_filter
  ns_register_filter postauth GET *.frm frm_page_filter
}
