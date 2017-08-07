ad_library {
    Supports the use of callbacks.

    @author Lee Denison (lee@xarg.co.uk)
}

namespace eval callback {}

ad_proc -public callback::impl_exists {
    {-callback:required}
    {-impl:required}
} {
    Returns whether the specified implementation exists.
} {
    return [expr {[info commands ::callback::${callback}::impl::${impl}] ne ""}]
}

ad_proc -public callback::get_object_type_impl {
    {-object_type:required}
    {-callback:required}
} {
    Finds the most type specific implementation of <code>callback</code>.
} {
    if {[callback::impl_exists -callback $callback -impl $object_type]} {
        return $object_type
    } else {
        set supertypes [acs_object_type::supertypes \
            -subtype $object_type]

        foreach type $supertypes {
            if {[callback::impl_exists -callback $callback -impl $type]} {
                return $type
            }
        }
    }

    return ""
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
