#      Initializes datastrctures for the installer.

#      @creation-date 02 October 2000
#      @author Bryan Quinn
#      @cvs-id installer-init.tcl,v 1.2 2000/10/23 23:25:31 bquinn Exp


# Create a mutex for the installer
nsv_set acs_installer mutex [ns_mutex create]
