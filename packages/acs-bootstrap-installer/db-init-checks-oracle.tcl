#####
#
# Perform database specific checks for the bootstrap and installer scripts.
#
#####

proc db_bootstrap_checks { errors error_p } {

    upvar $errors my_errors
    upvar $error_p my_error_p

    foreach pool [db_available_pools {}] {
        if { [catch { set db [ns_db gethandle -timeout 15 $pool]}] || $db eq "" } {
            # This should never happened - we were able to grab a handle previously, why not now?
            append my_errors "(db_bootstrap_checks) Internal error accessing pool \"$pool\".<br>"
            set my_error_p 1
        } else { # DRB: The aD code didn't deallocate the database handle if either of the following
            # errors occurred.  Boo hiss...
            if { [catch { ns_ora 1row $db "select sysdate from dual" }] ||
                 [catch { ns_ora exec_plsql_bind $db { begin :1 := 37*73; end; } 1 "" }] } {
                append my_errors "Database pool \"$pool\" has been configured with an old version of the Oracle driver.  You'll need version 2.3 or later.<br>"
                set my_error_p 1
            }
            ns_db releasehandle $db
        }
    }

    if { ![info exists my_error_p] } {
        # Get the version from Oracle, using the db tools equivalent of
        # sticks and fire...
        set db [ns_db gethandle [lindex [db_available_pools {}] 0]]
        set selection [ns_db 1row $db "select version from product_component_version where product like 'Oracle%'"]
        regexp {^[0-9]+\.[0-9]+\.[0-9]+} [ns_set value $selection 0] match
        ns_db releasehandle $db
        nsv_set ad_database_version . $match
    }
}

proc db_installer_checks { errors error_p } {

    upvar $errors my_errors
    upvar $error_p my_error_p

    # Date format is a globally defined value for Oracle, so we only need to check it once
    # for correctness.

    if { [db_string sysdate "select sysdate from dual"] != 
         [db_string sysdate2 "select to_char(sysdate,'YYYY-MM-DD') from dual"] } {
				  
        # See if NLS_DATE_FORMAT is set correctly
    	append my_errors "<hr><P><B>"
	append my_errors [db_string sysdate "select sysdate from dual"] 
    	append my_errors "<P>"
	append my_errors [ns_fmttime [ns_time] "%Y-%m-%d"] 
	append my_errors "</B><P><hr>"
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
    # How the hell we'd get this far without ORACLE_HOME is beyond me, but they want to
    # check, so let them check!
    if {![info exists env(ORACLE_HOME)]} {
        append my_errors "<li><p>
        <strong>There is no <code>ORACLE_HOME</code> variable in your environment. 
This variable must be set in order for the Oracle software to work properly (even on an Oracle client).</strong><p>
        "
        set my_error_p 1
    } 

    # First we look for the overall presence of interMedia
    db_1row check_role "SELECT (SELECT COUNT(*) FROM USER_ROLE_PRIVS WHERE GRANTED_ROLE = 'CTXAPP') ctxrole,
       (SELECT COUNT(*) FROM ALL_USERS WHERE USERNAME = 'CTXSYS') ctxuser,
       USER thisuser FROM DUAL"
    if {$ctxuser < 1} {
        append my_errors "<li><p><strong>The CTXSYS user does not exist in your database. This means 
that interMedia is probably not installed. interMedia is needed for full-text searching. 
To install it, you may either use the Oracle Database Assistant (<code>dbassist</code> under UNIX) to re-create 
your database or add the missing capabilities (JServer and interMedia), or, if you're feeling adventurous, look at running 
the SQL*Plus script <code>\$ORACLE_HOME/ctx/admin/dr0inst.sql</code> <em>on the Oracle server</em>.</strong></p>"
        set my_error_p 1
    }

    if {$ctxrole < 1} {
      append my_errors "<li><p><strong>The <code>CTXAPP</code> role has not been granted to this database 
user (<code>$thisuser</code>). Without the role, it will be impossible to synchronize interMedia indexes 
and several other tasks. As a dba user (e.g., <code>SYSTEM</code>), grant the role:
<blockquote><pre>
GRANT CTXAPP TO $thisuser;
</pre></blockquote>
If you still receive this error after restarting AOLserver, you may need to include the role 
as a \"default\" role for the user. To do so, run the following as a dba user such as <code>SYSTEM</code>:
<blockquote><pre>
ALTER USER $thisuser DEFAULT ROLE ALL;
</pre></blockquote>
</strong></p>"

      set my_error_p 1
    }


    # drop in a function to convert an Oracle supplied procedure into
    # function output
    set sql "CREATE OR REPLACE FUNCTION oacs_get_oracle_version(p_which IN VARCHAR2 DEFAULT 'version') 
      RETURN VARCHAR2 AS
      v_version VARCHAR2(50);
      v_compat VARCHAR2(50);
      BEGIN
        DBMS_UTILITY.DB_VERSION( v_version, v_compat );
        IF LOWER(p_which) = 'version' THEN
	   RETURN v_version;
        ELSIF LOWER(p_which) = 'compatibility' THEN
           RETURN v_compat;
        ELSE
   	   RETURN '';
   	END IF;
      END oacs_get_oracle_version;"
    db_dml create_oacs_get_oracle_version $sql

    db_1row get_platform_dbversion  "SELECT DBMS_UTILITY.PORT_STRING platform, oacs_get_oracle_version('version') dbversion FROM DUAL"
    # the following isn't used currently, but maybe someday we'll give the user
    # a snapshot of what we think their environment is
    switch -regexp -- $platform {
       {^IBMPC/WIN_NT.*} {set platformname "Windows"}
       {^SVR4-be-.*}      {set platformname "Solaris"}
       {^IBM AIX/RS.*}    {set platformname "RS/6000 AIX"}
       {^HP9000.*}        {set platformname "HP-UX on HP 9000"}
       {^Linuxi386.*}     {set platformname "Linux on Intel" }
       {^DEC Alpha OSF/1} {set platformname "Tru64 UNIX on Alpha" }
    }

    set dbversion_list [split $dbversion .]
    lassign $dbversion_list dbversion_major dbversion_minor dbversion_patch
    set dbversion_total [expr {($dbversion_major * 1000000) + ($dbversion_minor * 1000) + ($dbversion_patch)}]

    # Check for Oracle 8.1.6 and before running on Linux. If so, we've got to tell the user
    # what to do about lack of INSO filter support in interMedia there.
    if {($dbversion_total <= 8001006) && [string match $platform "Linuxi386*"]} {
        append my_errors "<li><p><strong>You are running Oracle $dbversion under Linux (Intel). Versions of
Oracle prior to 8.1.7 lack the INSO filters used by interMedia. (These filters convert content
stored in a variety of proprietary formats (e.g., Microsoft Word) into plain text or HTML for indexing
and searching.) The best solution is to upgrade the server to Oracle 8.1.7. A workaround is to create the 
file <code>\$ORACLE_HOME/ctx/bin/ctxhx</code> 
<em>on the Oracle server</em> containing the following lines:
<blockquote><pre>
#!/bin/sh
cat \$1 > \$2
</pre></blockquote>
This is a simple shell script that just copies the input onto the output. This will work fine
for the HTML and text documents generally stored in this toolset. After saving this file,
be sure to give it the proper ownership and permissions:
<blockquote><pre>
chown oracle:oinstall \$ORACLE_HOME/ctx/bin/ctxhx
chmod 755 \$ORACLE_HOME/ctx/bin/ctxhx
</pre></blockquote>
</strong><p>"
        set my_error_p 1
    }

    # do some cleanup
    db_dml drop "DROP FUNCTION oacs_get_oracle_version"
 
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
	    <a href=\"http://www.kornshell.com/\">David Korn's Kornshell page</a>.  (Alternatively, <code>pdksh</code> 
            (a ksh clone) has been reported to work.) Install it and provide
	    a symbolic link from <code>/bin/ksh</code> to the executable.  Alternatively, <code>loadjava</code>
	    is known to work if <code>/bin/sh</code> is linked to <code>/bin/ksh</code>.  You can do this by typing
	    as root:
	    <blockquote><pre>
ln -s /bin/sh /bin/ksh
	    </blockquote></pre>
	    </strong></p>"
        } else {
	    append my_errors "<li><p>You have the Korn shell installed in <code>/usr/bin/ksh</code>, but Oracle's
	    <code>loadjava</code> program expects it in <code>/bin/ksh</code>.  As root, please create 
	    a symbolic link.
	    <blockquote><pre>
ln -s /usr/bin/ksh /bin/ksh
	    </pre></blockquote></strong></p>"
        }
        set my_error_p 1
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
