ad_library {

    Tcl trace procs, accompanied by tcltrace-init.tcl

    Add Tcl execution traces to asserted Tcl commands

    @author Gustaf Neumann (neumann@wu-wien.ac.at)
    @creation-date 2015-06-11
    @cvs-id $Id$
}


namespace eval ::tcltrace {

    ad_proc -private before-ns_return { cmd op } {

        Execute this proc before ns_return is called.
        This proc saves the request in a file, which can be later
        used for validating the returned HTML. This works as well
        for admin pages, which can not be validated via web based
        HTML validators without giving away admin privileges.

        @param cmd the full command as executed by Tcl
        @param op the trace operation
    } {
        lassign $cmd cmdname statuscode mimetype content

        if {[::parameter::get_from_package_key \
                 -package_key acs-tcl \
                 -parameter TclTraceSaveNsReturn \
                 -default 0]} {
            if {$statuscode == 200
                && $mimetype eq "text/html"} {
                set name [ns_conn url]
                regsub {/$} $name /index name
                set fullname [ad_tmpdir]/ns_saved$name.html
                ns_log notice "before-ns_return: save content of ns_return to file:$fullname"
                set dirname [ad_file dirname $fullname]
                if {![ad_file isdirectory $dirname]} {
                    file mkdir $dirname
                }
                set f [open $fullname w]
                puts $f $content
                close $f
            } else {
                ns_log notice "before-ns_return: ignore statuscode $statuscode mime-type $mimetype"
            }
        }
    }


    ad_proc -private before-ns_log { cmd op } {
        Execute this proc before ns_log is called

        @param cmd the full command as executed by Tcl
        @param op the trace operation
    } {
        set msg [join [lassign $cmd cmdname severity]]
        set severity [string totitle $severity]
        if {![info exists ::__log_severities]} {
            set ::__log_severities [::parameter::get_from_package_key \
                                        -package_key acs-tcl \
                                        -parameter TclTraceLogSeverities \
                                        -default ""]
        }
        if {$severity in $::__log_severities} {
            # we do not want i18n raw strings substituted via ds_comment.
            # Maybe we should add this substitution there....
            regsub -all -- {\#([a-zA-Z0-9._-]+)\#} $msg {\&#35;\1\&#35;} msg
            catch {ds_comment "$cmdname $severity $msg"}
        } else {
            #catch {ds_comment "ignore $severity $msg"}
        }
    }

    ad_proc -private before {
        {-details:boolean false}
        cmd
        op
    } {

        Generic trace proc for arbitrary commands. Simply reports
        calls to function (optionally with full context) to the error.log.

        @param details when set, use ad_log for reporting with full context
        @param cmd the full command as executed by Tcl
        @param op the trace operation

    } {
        set log_cmd [expr {$details_p ? "ad_log" : "ns_log"}]
        set abbrev_cmd [lmap w $cmd {
            regsub -all \n $w {\n} w
            regsub -all \r $w {\r} w
            if {[string length $w] > 100} {
                set w [string range $w 0 100]...
            }
            set w
        }]
        $log_cmd notice "trace: [join $abbrev_cmd { }]"
    }

}






# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
