#####
#
# Perform database specific checks for the bootstrap and installer scripts.
#
#####

proc db_bootstrap_checks { errors error_p } {

    upvar $errors my_errors
    upvar $error_p my_error_p

    foreach pool [nsv_get db_available_pools .] {
        if { [catch { set db [ns_db gethandle -timeout 15 $pool]}] || ![string compare $db ""] } {
            # This should never happened - we were able to grab a handle previously, why not now?
            append my_errors "(db_bootstrap_checks) Internal error accessing pool \"$pool\".<br>"
            set my_error_p 1
        } else {
            # DRB: The aD code didn't deallocate the database handle if either of the following
            # errors occured.  Boo hiss...
            if { [catch { ns_ora 1row $db "select sysdate from dual" }] ||
                 [catch { ns_ora exec_plsql_bind $db { begin :1 := 37*73; end; } 1 "" }] } {
                append my_errors "Database pool \"$pool\" has been configured with an old version of the Oracle driver.  You'll need version 2.3 or later.<br>"
                set my_error_p 1
            }
            ns_db releasehandle $db
        }
    }

    if { ![info exists my_error_p] } {
        # DRB: I've got the SQL to pick the version to drop in later...what we really want,
        # though, is Oracle's "compat version" number and I'm not sure how to get it (it is
        # reported as 8.1.0 during the Oracle installation process)
        nsv_set ad_database_version . "8.1.6"
    }
}

proc db_installer_checks { errors error_p } {

    upvar $errors my_errors
    upvar $error_p my_error_p

    # Date format is a globally defined value for Oracle, so we only need to check it once
    # for correctness.

    if { [db_string sysdate "select sysdate from dual"] != [ns_fmttime [ns_time] "%Y-%m-%d"] } {
        # See if NLS_DATE_FORMAT is set correctly
        append my_errors "<li><p><b>Your Oracle driver is correctly installed, however
            Oracle's date format should be set to <i>YYYY-MM-DD</i>.</b></p>\n"
        set my_error_p 1
    }
} 

# If we're using Oracle we have to check that the korn shell's available and a couple of
# other similar things.

proc db_helper_checks { errors error_p } {

     upvar $errors my_errors
     upvar $error_p my_error_p

    # Oracle should provide ctxhx
    global env
    # How the hell we'd get this far without ORACLE_HOME is beyond me, but they wanna
    # check, so let them check!
    if {![info exists env(ORACLE_HOME)]} {
        append my_errors "<li><p>
        <strong>There is no <code>ORACLE_HOME</code> variable in your environment.  This variable must be set in order for the installer to locate your Oracle instance.</strong><p>
        "
        set my_error_p 1
    } elseif { ![file exists "$env(ORACLE_HOME)/ctx/bin/ctxhx"] && ![ad_windows_p]} {
        append my_errors "<li><p><strong> The file <code>$env(ORACLE_HOME)/ctx/bin/ctxhx</code> which is needed 
by the OpenACS Content Repository is not present in your filesystem.  You must be running Oracle 8.1.6 
with Intermedia installed to use OpenACS.  If you are using Linux, this file is missing because Oracle 
does not distribute it with the Linux version of Oracle.  However, you can replace this file with a 
shell script that acts as a workaround.<p>
The program <code>ctxhx</code> is primarily used to convert files to HTML or TEXT and can
support translating between different character sets.  The content repository does not need
this extensive functionality, so you can replace the program with
<blockquote><pre>
#!/bin/sh
cat \$1 > \$2
</pre></blockquote>

Save the above text in <code>$env(ORACLE_HOME)/ctx/bin/ctxhx</code>, and give
it the proper ownership and permissions.
<blockquote><pre>
chown oracle:oinstall $env(ORACLE_HOME)/ctx/bin/ctxhx
chmod 755 $env(ORACLE_HOME)/ctx/bin/ctxhx
</pre></blockquote>
</strong><p>"

        set my_error_p 1
    }
 
    # ksh must be installed for Oracle's loadjava to work.

    if { ![ad_windows_p] && ![file exists "/bin/ksh"] } {
        if {[file exists "/usr/bin/ksh"]} {
	    set usr_bin_p 1
        } else {
	    set usr_bin_p 0
        }
        if {!($usr_bin_p)} {
	    append my_errors "<li><p><strong>The file <code>/bin/ksh</code> is not present.  This file is the Korn shell and
	    is required by Oracle's <code>loadjava</code> utility for adding Java class files to the database.
	    It must be installed in order for OpenACS to install properly.  Please obtain it from 
	    <a href=\"http://www.kornshell.com/\">David Korn's Kornshell page</a>.  Install it and provide
	    a symbolic link from <code>/bin/ksh</code> to the executable.  Alternatively, <code>loadjava</code>
	    is known to work if <code>/bin/sh</code> is linked to <code>/bin/ksh</code>.  You can do this by typing
	    as root:
	    <blockquote><pre>
ln -s /bin/sh /bin/ksh
	    </blockquote></pre>
	    </strong></p>"
        } else {
	    append my_errors "<li><p>You have the Korn shell installed in <code>/usr/bin/ksh</code>, but Oracle's
	    <code>loadjava</code> program expects in in <code>/bin/ksh</code>.  As root, please create 
	    a symbolic link.
	    <blockquote><pre>
ln -s /usr/bin/ksh /bin/ksh
	    </pre></blockquote></strong></p>"
        }
        set my_error_p 1
    }
}
