#/packages/acs-lang/tcl/lang-catalog-init.tcl
ad_library {
    Loads files that contain messages.
    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    @creation-date 10 September 2000
    @author Jeff Davis (davis@arsdigita.com)
    @author Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
    @author Peter Marklund (peter@collaboraid.biz)
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

#####
#
# Load catalog files from all packages into the database
#
#####

# This is done in a scheduled proc so that it won't take up time at server startup.
# Instead, it can be done by a thread after the server has started multithreading.
#
# Peter Marklund, 7 October 2002: Commenting out since we don't want to source the catalog
# files on every startup (we want to source them just once). If the acs_messages table 
# had a package_key column we could easily
# check if a certain package has already had its catalog files sourced or not.

#ad_schedule_proc -once t 5 lang::catalog::load_all
