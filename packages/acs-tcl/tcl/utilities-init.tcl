ad_library {

    Initializes datastrctures for utility procs.

    @creation-date 02 October 2000
    @author Bryan Quinn
    @cvs-id $Id$
}

# initialize the random number generator
randomInit [ns_time]

# Create mutex for util_background_exec
nsv_set util_background_exec_mutex . [ns_mutex create]


