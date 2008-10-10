#      Initializes datastrctures for the installer.

#      @creation-date 02 October 2000
#      @author Bryan Quinn
#      @cvs-id $Id$


# Create a mutex for the installer
nsv_set acs_installer mutex [ns_mutex create oacs:installer]
