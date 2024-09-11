ad_include_contract {
    Renders the registered URNs, optionally filtered via match pattern.

    @param match optional match pattern
    @creation-date 2022-10-23
    @author Gustaf Neumann
} {
    {match "*"}
}

template::multirow create urns urn url
foreach pattern [lsort $match] {
    foreach urn [lsort [array names ::template::head::urn $pattern]] {
        template::multirow append urns $urn [template::head::resolve_urn $urn]
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
