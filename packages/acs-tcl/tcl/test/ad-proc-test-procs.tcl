ad_library {

    Tests for ad_proc.

    @author Lee Denison lee@xarg.co.uk
    @creation-date 2005-03-11
}

aa_register_case -cats {api smoke} ad_proc_create_callback {

    Tests the creation of a callback and an implementation with 
    some forced error cases.

} {
    aa_true "throw error for ad_proc -callback with extraneous proc body" \
        [catch {
            ad_proc -callback a_callback { arg1 arg2 } { docs } { body }
        } error]

    aa_true "throw error for callback called contract" \
        [catch {
            ad_proc -callback contract { arg1 arg2 } { docs } -
        } error]

    ad_proc -callback a_callback { -arg1 arg2 } { this is a test callback } -
    set callback_procs [info commands ::callback::a_callback::*]
    aa_true "creation of a valid callback contract with '-' body" \
        [expr {"::callback::a_callback::contract" in $callback_procs}]

    ad_proc -callback a_callback_2 { arg1 arg2 } { this is a test callback } {}
    set callback_procs [info commands ::callback::a_callback_2::*]
    aa_true "creation of a valid callback contract with no body" \
        [expr {"::callback::a_callback_2::contract" in $callback_procs}]

    aa_true "throw error for missing -callback on implementation definition" \
        [catch {
            ad_proc -impl an_impl {} { docs } { body }
        } error]

    aa_true "throw error for implementation named impl" \
        [catch {
            ad_proc -callback a_callback -impl impl {} { docs } { body }
        } error]

    ad_proc -callback a_callback -impl an_impl {} { 
        this is a test callback implementation 
    } {
    }
    set impl_procs [info commands ::callback::a_callback::impl::*]
    aa_true "creation of a valid callback implementation" \
        [expr {"::callback::a_callback::impl::an_impl" in $impl_procs}]
}

ad_proc -callback a_callback {
        -arg1:required arg2
} {
        this is a test callback
} -

ad_proc -callback b_callback {
        -arg1:required arg2
} {
        this is a test callback
} -
ad_proc -callback c_callback {
        -arg1:required arg2
} {
        this is a test callback
} -

ad_proc -callback a_callback -impl an_impl1 {} {
        this is a test callback implementation
} {
        return 1
}

ad_proc -callback a_callback -impl an_impl2 {} {
        this is a test callback implementation which does
        an upvar of an array.
} {
        upvar $arg1 arr
    if {[info exists arr(test)]} {
            return $arr(test)
    }
    return {}
}

ad_proc -callback a_callback -impl fail_impl {} {
        this is a test callback implementation
} {
        error "should fail"
}

ad_proc EvilCallback {} {
    This is a test callback implementation that should not be invoked.
} {
        error "Should not be invoked"
}

aa_register_case -cats {api smoke} ad_proc_fire_callback {

    Tests a callback with two implementations .

} {
    aa_true "throws error for invalid arguments even if no implementations" \
        [catch {callback c_callback bar} error]

    aa_true "callback returns empty list with no implementations" \
        [expr {[llength [callback b_callback -arg1 foo bar]] == 0}]

    set foo(test) 2

    aa_true "callback returns value for each defined callback and catches the error callback" \
        [expr {[llength [callback -catch a_callback -arg1 foo bar]] == 2}]

    aa_true "callback returns correct value for specified implementation" \
        [expr {[callback -impl an_impl1 a_callback -arg1 foo bar] == 1}]

    aa_true "callback returns correct value for an array ref" \
        [expr {[callback -impl an_impl2 a_callback -arg1 foo bar] == 2}]

    aa_true "callback works with {} args" \
        [expr {[callback -impl an_impl2 a_callback -arg1 {} {}] == {}}]

    aa_true "callback errors with missing arg" \
        [expr {[catch {callback -impl an_impl2 a_callback -arg1 foo} err] == 1}]

    aa_true "throws error for invalid arguments with implementations" \
        [catch {callback a_callback bar} error]

    aa_true "throws error when a non-existent implementation is specified" \
        [catch {callback -impl non_existent a_callback -arg1 foo bar} error]

    aa_true "throws error without -catch when an error occurs in a callback" \
        [catch {callback a_callback -arg1 foo bar} error]

    set x [catch {callback -impl an_impl2 a_callback -arg1 foo {[EvilCallback]}} error]
    aa_false "EvilCallback not invoked returned $error" $x

    set x [catch {callback -impl an_impl2 a_callback -arg1 {[EvilCallback]} bar} error]
    aa_false "EvilCallback not invoked returned $error" $x


}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
