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

    ad_proc assert_browser_locale {accept_language expect_locale} {
        Assert that with given accept language header lang::conn::browser_locale returns
        the expected locale.

        @author Peter Marklund
    } {
        ns_set update [ns_conn headers] "Accept-Language" $accept_language
        set browser_locale [lang::conn::browser_locale]
        aa_equals "Checking return value of lang::conn::browser_locale " $browser_locale $expect_locale
    }
}
