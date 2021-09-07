# /tcl/0-acs-init.tcl
#
# The very first file invoked when OpenACS is started up. Sources
# /packages/acs-tcl/bootstrap/bootstrap.tcl.
#
# jsalz@mit.edu, 12 May 2000
#
# $Id$

namespace eval acs {
    #
    # Determine, under which server we are running
    #
    set ::acs::useNaviServer [expr {[ns_info name] eq "NaviServer"}]

    #
    # Initialize the list of known database types .  User code should use the database
    # API routine db_known_database_types rather than reference the nsv list directly.
    # We might change the way this is implemented later.  Each database type is
    # represented by a list consisting of the internal name, driver name, and
    # "pretty name" (used by the APM to list the available database engines that 
    # one's package can choose to support).  The driver name and "pretty name" happen
    # to be the same for PostgreSQL and Oracle but let's not depend on that being true
    # in all cases...
    #

    set ::acs::known_database_types {
        {oracle Oracle Oracle}
        {postgresql PostgreSQL PostgreSQL}
    }

    #
    # Enable / disable features depending on availability
    #
    set ::acs::pageroot [expr {$::acs::useNaviServer ? [ns_server pagedir] : [ns_info pageroot]}]
    set ::acs::tcllib   [expr {$::acs::useNaviServer ? [ns_server tcllib] : [ns_info tcllib]}]
    set ::acs::rootdir  [file dirname [string trimright $::acs::tcllib "/"]]
    set ::acs::useNsfProc [expr {[info commands ::nsf::proc] ne ""}]
}

# Determine the OpenACS root directory, which is the directory right above the
# Tcl library directory ::acs::tcllib.

nsv_set acs_properties root_directory $::acs::rootdir

ns_log "Notice" "Loading OpenACS, rooted at $::acs::rootdir"
set bootstrap_file "$::acs::rootdir/packages/acs-bootstrap-installer/bootstrap.tcl"

if { [file isfile $bootstrap_file] } {

    ns_log "Notice" "Sourcing $bootstrap_file"
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
		    ns_log Error "0-acs-init.tcl: please use tDOM version 0.7.8 or greater (you have version $version)"
		}
	    }
	}
    }
        
    source $bootstrap_file
} else {
    ns_log "Error" "$bootstrap_file does not exist. Aborting the OpenACS load process."
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
