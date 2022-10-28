ad_page_contract {
    @author Gustaf Neumann

    @creation-date Aug 6, 2018
} {
}

set title "ACS Templating Package - Sitewide Admin"
set context [list $title]

#
# Collect generic names
#
set generic {}
foreach iconset [dict keys $::template::icon::map] {
    lappend generic {*}[dict keys [dict get $::template::icon::map $iconset]]
}

#
# Default iconset
#
set default_iconset [::template::iconset]

set iconsets {}
foreach iconset {bootstrap-icons fa-icons} {
    if {[::template::head::can_resolve_urn urn:ad:css:$iconset]} {
        template::head::add_css -href urn:ad:css:$iconset
        lappend iconsets $iconset
    }
}
#
# When running under bootstrap3, add the glyph iconds
#
if {[template::toolkit] eq "bootstrap"} {
    lappend iconsets glyphicons
}
lappend iconsets classic

set th "<th scope='col'>Name</th>"
foreach iconset $iconsets {
    append th "<th scope='col'>$iconset</th>"
    append td "<td><adp:icon name='\$name' alt='\$name' iconset='$iconset'></td>"
}

append genericHTML \
    {<table class="table">} \n \
    "<tr>$th</tr>\n" \
    [join [lmap name [lsort -unique [set generic]] {
        set _ "<tr><td>$name</td> [subst $td] </tr>"
    }] \n] \
    </table>\n

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
