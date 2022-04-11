ad_library {
    Template style handling
    @author Gustaf Neumann
}

ad_proc -private template::toolkit {-subsite_id} {

    return the CSS toolkit empty for the current or given site.
    Potentila result values are "" (undtermined) "bootstrap"
    (for Bootstrap 3) and "bootstrap5" (for Bootstrap 5).

} {
    if { ![info exists subsite_id] } {
        set subsite_id [ad_conn subsite_id]
    }
    set toolkit [parameter::get -parameter CSSToolkit -package_id $subsite_id]
    if {$toolkit eq ""} {
        #
        # Derive the toolkit from the subsite theme
        #
        set theme [subsite::get_theme -subsite_id $subsite_id]
        if {[string match *bootstrap5* $theme]} {
            set toolkit bootstrap5
        } elseif {[string match *bootstrap3* $theme]} {
            set toolkit bootstrap
        }
    }
    return $toolkit
}

ad_proc -private template::iconset {-subsite_id} {

    Return the configured or derived icon set.  Potential results are
    "classic" (old-style gif/png images), "glyphicons" (Part of
    Bootstrap 3), and "bootstrap-icons" (usable for all themes).

} {
    if { ![info exists subsite_id] } {
        set subsite_id [ad_conn subsite_id]
    }
    set iconset [parameter::get -parameter IconSet -package_id $subsite_id]

    if {$iconset eq ""} {
        #
        # Derive the iconset from the template::toolkit.
        #
        if {[template::toolkit -subsite_id $subsite_id] eq "bootstrap"} {
            #
            # Bootstrap 3. Make this for backward compatibility the
            # first choice.
            #
            set iconset "glyphicons"
        } elseif {[apm_package_enabled_p "bootstrap-icons"]} {
            #
            # Bootstrap icons work with all toolkits
            #
            set iconset "bootstrap-icons"
        } else {
            set iconset "classic"
        }
    }
    return $iconset
}


ad_proc -private ::template::icon {
    -name:required
    {-title ""}
    -style
    -class
} {

    Return a dict containing the HTML rendering and a potentially
    needed command for the ADP code. The latter are necessary for
    e.g. style loading.

    The configuration of this method is performed via the Tcl dict
    ::template::icon::map, which is set in tag-init.tcl

} {
    set styleAtt [expr {[info exists style] ? "style='$style'" : ""}]
    set class [expr {[info exists class] ? " $class" : ""}]
    set iconset [::template::iconset]
    if {[dict exists $::template::icon::map $iconset $name]} {
        set name [dict get $::template::icon::map $iconset $name]
    }
    if {[string range $name 0 0] eq "/"} {
        set iconset default
    } elseif {$name eq ""} {
        set iconset text
    }
    set cmd ""
    switch $iconset {
        "glyphicons" {
            set template {<span class='glyphicon glyphicon-$name$class' title='$title' aria-hidden='true' $styleAtt></span>}
        }
        "bootstrap-icons" {
            set cmd {template::head::add_css -href urn:ad:css:bootstrap-icons}
            set template {<i class='bi bi-$name$class' title='$title' aria-hidden='true' $styleAtt></i>}
        }
        "text" {
            set template {<span class='$class' title='$title' $styleAtt>$title</span>}
        }
        default {
            set template {<img class='$class' src='$name' height='16' width='16' title='$title' alt='$title' style='border:0; $styleAtt'>}
        }
    }
    return [list HTML [subst -nocommands $template] cmd $cmd]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
