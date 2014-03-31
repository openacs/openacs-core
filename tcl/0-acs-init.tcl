# /tcl/0-acs-init.tcl
#
# The very first file invoked when OpenACS is started up. Sources
# /packages/acs-tcl/bootstrap/bootstrap.tcl.
#
# jsalz@mit.edu, 12 May 2000
#
# $Id$

# handling NaviServer deprecated ns_info subcommands. 
namespace eval acs {
    set ::acs::pageroot [expr {[catch {ns_server pagedir}] ? [ns_info pageroot] : [ns_server pagedir]}]
    set ::acs::tcllib [expr {[catch {ns_server tcllib}] ? [ns_info tcllib] : [ns_server tcllib]}]
    set ::acs::rootdir [file dirname [string trimright $::acs::tcllib "/"]]
    #if {[info commands ::dbi_rows] ne ""} { set ::acs::preferdbi 1 }
}

# Determine the OpenACS root directory, which is the directory right above the
# Tcl library directory ::acs::tcllib.

nsv_set acs_properties root_directory $::acs::rootdir

ns_log "Notice" "Loading OpenACS, rooted at $::acs::rootdir"
set bootstrap_file "$::acs::rootdir/packages/acs-bootstrap-installer/bootstrap.tcl"

if { [file isfile $bootstrap_file] } {

    #
    # Check that the appropriate version of tDom (http://www.tdom.org)
    # is installed and spit out a comment or try to install it if not.
    #
    if {[info commands domNode] eq ""} { 
	if {[ns_info version] < 4} {
	    ns_log Error "0-acs-init.tcl: domNode command not found -- libtdom.so not loaded?"
	} elseif {[ns_info version] >= 4} {
	    if {[catch {set version [package require tdom]} errmsg]} { 
		ns_log Error "0-acs-init.tcl: error loading tdom: $errmsg" 
	    } else {
		lassign [split $version .] major minor point
		if {$major == 0 
		    && ( $minor < 7 || ($minor == 7 && $point < 8))} { 
		    ns_log Error "0-acs-init.tcl: please use tdom version 0.7.8 or greater (you have version $version)"
		}
	    }
	}
    }

    ns_log "Notice" "Sourcing $bootstrap_file"        
    source $bootstrap_file
} else {
    ns_log "Error" "$bootstrap_file does not exist. Aborting the OpenACS load process."
}
