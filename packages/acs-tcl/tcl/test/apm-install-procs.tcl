ad_library {

    Tests for api in /tcl/apm-install-procs.tcl

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        apm_get_repository_channels
    } \
    apm_respositories_api {
        Check the API to retrieve upstream repositories
    } {
        set repos failed

        aa_false "Fetching the repos succeeds" \
            [catch {set repos [apm_get_repository_channels]} errmsg]

        foreach repo $repos {
            aa_equals "Repo entry '$repo' is made by 2 elements" \
                [llength $repo] 2
        }
    }
