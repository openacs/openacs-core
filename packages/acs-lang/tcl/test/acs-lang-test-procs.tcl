ad_library {
    Helper test Tcl procedures.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 18 October 2002
}

namespace eval lang::test {

    ad_proc get_dir {} {
        The test directory of the acs-lang package (where this file resides).

        @author Peter Marklund (peter@collaboraid.biz)
        @creation-date 28 October 2002
    } {
        return "[acs_package_root_dir acs-lang]/tcl/test"
    }
}
