ad_library {

    Automated functions for acs-admin

    @cvs-id $Id$

}

# Only run this if this is openacs.org

if {0} {

    ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 0 0] apm_build_repository

    # we register the following filters only during startup, since
    # existing connection threads are not aware of the throttle object.

    if {[ns_server connections] == 0} {
        # 
        # Register the filter progs for url statistics.
        # The methods to be called have the name of the filter type.
        #
        ns_register_filter trace GET /repository/* repository-download
        
        if {[info commands ::xo::db::require] ne ""} {
            ::xo::db::require table apm_package_downloads {
                time     timestamp
                ip       text
                user_id  integer
                channel  text
                package  text
                version  text
                url      text
            }
            
            ad_proc ::repository_log_to_db {} {
                set ip [ns_conn peeraddr]
                set user_id [ad_conn user_id]
                set url [ns_conn url]
                if {[regexp {^/repository/([^/]+)/(.*)-([^-]+).apm$} [ns_conn url] _ channel package version]} {
                    ::xo::dc dml record_package_download \
                        "insert into apm_package_downloads(time, ip, user_id, channel, package, version, url) \
                   values (now(), :ip, :user_id, :channel, :package, :version, :url)"
                }
            }
        }

        ad_proc ::repository-download {args} {
        } {
            ns_log notice "::repository-download called with <$args> [ad_conn user_id] <[ns_conn url]> [ns_conn peeraddr]"
            set f [open $::acs::rootdir/log/apm.log a]
            puts $f "[clock format [clock seconds]]\t[ns_conn peeraddr]\t[ad_conn user_id]\t[ns_conn url]"
            close $f
            if {[catch {::repository_log_to_db} errorMsg]} {
                ns_log error "repository-download: $errorMsg"
            }
            return filter_ok
        }
    }

}





# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
