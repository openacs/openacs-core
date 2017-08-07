ad_page_contract {
    @cvs-id $Id$
} -properties {
    m:onevalue
} -query {
    m:naturalnum,notnull
} -validate {
    check_size_of_m -requires m {
	if { $m > 15 } {
	    ad_complain "This demo allows only m <= 15"
	}
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
