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
