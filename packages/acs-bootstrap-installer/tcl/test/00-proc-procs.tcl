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
        } errmsg]

        set failure [catch {
            file tail $tilde_filename
        } errmsg]
        aa_true "'file tail' fails with a tilde character, revealing existing users! -> '$errmsg'" \
            $failure

        aa_false "ad_file sanitizes the tilde character from the filename" [catch {
            ad_file tail $tilde_filename
        } errmsg]
    }
