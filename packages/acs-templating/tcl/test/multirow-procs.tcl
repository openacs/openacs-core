ad_library {

    procs for testing the multiple and group tags
    
}


aa_register_case -cats { api } -bugs { 428 } group_tag {
    Testing more than one group tag inside multiple.

    <p>

    This test uses to auxiliary files: multirow-test.tcl and 
    multirow-test.adp - I put them in the same directory 
    acs-templating/tcl/test for now, but it would be cool
    to have a way to test adp output without additional 
    files.

    @see http://openacs.org/bugtracker/openacs/bug?bug_number=428
} {

    set out [ad_parse_template -params [list [list second_level_stays_p 0]] "/packages/acs-templating/tcl/test/multirow-test"]

    aa_true "contains first heading twice when second level changes" [regexp {f1:.*f1:} $out]


    set out [ad_parse_template -params [list [list second_level_stays_p 1]] "/packages/acs-templating/tcl/test/multirow-test"]

    aa_true "contains first heading twice when second level stays the same" [regexp {f1:.*f1:} $out]
}
