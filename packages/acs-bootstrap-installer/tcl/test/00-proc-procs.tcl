ad_library {
    Tests for procs in tcl/00-proc-procs.tcl
}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_file} \
    ad_file {
        Basic test of ad_file, showing why this has been introduced.
    } {
        set non_existing_user "openacstestuser2352rfwef432fg543wf3asdf32rdddsfs65"
        set tilde_filename ~$non_existing_user

        aa_false "'file tail' works as expected without a tilde character" [catch {
            file tail $non_existing_user
        } errorMsg]

        set failure [catch {
            file tail $tilde_filename
        } errorMsg]
        aa_true "'file tail' raises an error with leading tilde character, revealing existing users! -> '$errorMsg'" \
            $failure

        aa_false "ad_file raises no error with leading tilde character" [catch {
            ad_file tail $tilde_filename
        } errorMsg]

        set fresh_fn [ns_sha1 [clock seconds]]
        set i 0

        while {[file exists $fresh_fn-$i]} { incr i }
        # touch the fresh file without tilde
        close [open $fresh_fn-$i w]
        aa_log "filename without tilde: $fresh_fn-$i [pwd]"

        aa_true "file exists $fresh_fn-$i" [file exists $fresh_fn-$i]
        aa_true "ad_file exists $fresh_fn-$i" [ad_file exists $fresh_fn-$i]

        aa_false "file exists $fresh_fn-$i" [file exists ~$fresh_fn-$i]
        aa_false "ad_file exists $fresh_fn-$i" [ad_file exists ~$fresh_fn-$i]

        aa_false "file tail ~$fresh_fn-$i" {[catch {file tail ~$fresh_fn-$i}] == 0}
        aa_true "ad_file tail ~$fresh_fn-$i" {[ad_file tail ~$fresh_fn-$i] eq "./~$fresh_fn-$i"}

        file delete $fresh_fn-$i

        #
        # now the same with an existing file with a leading tilde
        #
        set j $i
        while {[file exists ~$fresh_fn-$j]} { incr j }
        # touch the fresh file with tilde
        close [open ./~$fresh_fn-$j w]
        aa_log "filename with tilde: ~$fresh_fn-$j"

        aa_true "file exists ./~$fresh_fn-$j" [file exists ./~$fresh_fn-$j]
        aa_true "ad_file exists ./~$fresh_fn-$j" [ad_file exists ./~$fresh_fn-$j]
        aa_true "ad_file exists ~$fresh_fn-$j" [ad_file exists ~$fresh_fn-$j]

        aa_false "file tail ~$fresh_fn-$j" {[catch {file tail ~$fresh_fn-$j}] == 0}
        aa_true "ad_file tail ~$fresh_fn-$j" {[ad_file tail ~$fresh_fn-$j] eq "./~$fresh_fn-$j"}

        file delete ./~$fresh_fn-$j
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        db_current_rdbms
        db_available_pools
        db_qd_get_fullname
        db_qd_fetch
        db_fullquery_get_querytext
        db_fullquery_get_name
        db_fullquery_get_query_type
    } \
    db__database_interface {
        Basic test of low-level database interface
    } {
        set dbms [db_current_rdbms]
        aa_equals "dbms looks valid" [dict keys $dbms] "type version"
        aa_true "dbms type nonempty" {[dict get $dbms type] != ""}
        aa_true "dbms version nonempty" {[dict get $dbms version] != ""}

        set pools [db_available_pools ""]
        aa_true "pools '$pools' can be valid (need at least one pool)" {[llength $pools] > 0}

        set qn dbqd.acs-tcl.tcl.site-nodes-procs.site_node::mount.mount_object
        set full_statement_name [db_qd_get_fullname $qn 2]
        aa_true "full_statement_name '$full_statement_name'" {$full_statement_name ne ""}
        set full_query [db_qd_fetch $full_statement_name ""]
        aa_true "full_query '$full_query'" {$full_query ne ""}
        set sql [db_fullquery_get_querytext $full_query]
        aa_true "SQL:<pre>$sql</pre>" {$sql ne ""}

        set name [db_fullquery_get_name $full_query]
        aa_true "name: $name" {$name ne ""}

        # This call is rather useless, just here for completeness
        set type [db_fullquery_get_query_type $full_query]
        aa_true "type: $type" {$type eq ""}
    }
