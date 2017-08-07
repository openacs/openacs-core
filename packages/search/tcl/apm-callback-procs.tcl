namespace eval search {}
namespace eval search::install {}

ad_proc search::install::after_instantiate {
    -package_id:required
} {
    Package after instantiation callback proc.

    Schedule the indexer so the admin doesn't have to restart their server to get search
    up and running after mounting it.
} {

    # DRB: Unless it is being instantiated from initial install as specified by an install.xml
    # file, in which case the init file hasn't been sourced, and the user has to restart their
    # server anyway ...

    if { [info procs search::init::schedule_indexer] ne "" } {
        search::init::schedule_indexer
    }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
