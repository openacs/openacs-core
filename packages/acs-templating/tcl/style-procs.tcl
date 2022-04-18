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
    Bootstrap 3), "fa-icons" (usable for all themes), and
    "bootstrap-icons" (usable for all themes).

} {
    if { ![info exists subsite_id] } {
        set subsite_id [ad_conn subsite_id]
    }
    set default ""
    # set default "fa-icons"  ;# just for testing
    set iconset [parameter::get -parameter IconSet -package_id $subsite_id -default $default]

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
        } elseif {[apm_package_enabled_p "fa-icons"]} {
            #
            # Awesome icons work with all toolkits
            #
            set iconset "fa-icons"
        } else {
            set iconset "classic"
        }
    }
    return $iconset
}


ad_proc -private ::template::icon {
    -name:required
    {-alt ""}
    {-class ""}
    {-iconset ""}
    {-style ""}
    {-title ""}
} {

    Return a dict containing the HTML rendering and a potentially
    needed command for the ADP code. The latter are necessary for
    e.g. style loading.

    The target icon can be (1) a font glyph, (2) an image or (3) just
    a text. Method (1) is used for glyphicons and boostrap icons,
    which is signaled by a value in the icon::map starting with a
    plain character. When the value starts with a slash "/", then an
    image will be used. When the name has no graphical counterpart
    (variant 3), this is signaled via an empty string. In this case,
    the resulting replacement will be the value of "alt" in text form.

    The configuration of this method is performed via the Tcl dict
    ::template::icon::map, which is set in tag-init.tcl

    @param alt used im classic images. When not specified, use 'title' attribute
    @param iconset force isage of this icon set
    @return dict containing 'HTML' and 'cmd'
} {
    set styleAtt [expr {$style ne "" ? "style='$style'" : ""}]
    if {$iconset eq ""} {
        set iconset [::template::iconset]
    }

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
        "fa-icons" {
            set cmd {template::head::add_css -href urn:ad:css:fa-icons}
            set template {<i class='$name$class' title='$title' aria-hidden='true' $styleAtt></i>}
        }
        "text" {
            set alt [expr {[info exists alt] ? $alt : $title}]
            set template {<span class='$class' title='$title' $styleAtt>$alt</span>}
        }
        default {
            set alt [expr {[info exists alt] ? $alt : $title}]
            set template {<img class='$class' src='$name' height='16' width='16' title='$title' alt='$alt' style='border:0; $styleAtt'>}
        }
    }
    return [list HTML [subst -nocommands $template] cmd $cmd]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
