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

ad_proc ::template::icon::name {-iconset name} {

    Return for the provided generic name the name in the specified or
    current iconset the name mapping. This function is necessary in
    boundary cases, where e.g. a display_template passes the generic
    name of the icon via template variables which have to be
    @-substituted before adp-tag resolution, which performs the
    regular icon name mapping (otherwise, the tag resolver receives
    e.g. ...name=@icon@...)

    @param iconset
    @param name
    @return mapped icon name or the passed in generic name
} {
    if {![info exists iconset]} {
        set iconset [template::iconset]
    }
    if {[dict exists $::template::icon::map $iconset $name]} {
        set name [dict get $::template::icon::map $iconset $name]
    }
    return $name
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
    a text. Method (1) is used for glyphicons and bootstrap icons,
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
    set _class [expr {$class ne "" ? " $class" : ""} ]
    set cmd ""
    switch $iconset {
        "glyphicons" {
            set template {<span class='glyphicon glyphicon-$name$_class' title='$title' aria-hidden='true' $styleAtt></span>}
        }
        "bootstrap-icons" {
            set cmd {template::head::add_css -href urn:ad:css:bootstrap-icons}
            set template {<i class='bi bi-$name$_class' title='$title' aria-hidden='true' $styleAtt></i>}
        }
        "fa-icons" {
            set cmd {template::head::add_css -href urn:ad:css:fa-icons}
            set template {<i class='$name$_class' title='$title' aria-hidden='true' $styleAtt></i>}
        }
        "text" {
            if {$alt eq ""} {set alt $title}
            set template {<span class='$class' title='$title' $styleAtt>$alt</span>}
        }
        default {
            if {$alt eq ""} {set alt $title}
            set template {<img class='$class' src='$name' height='16' width='16' title='$title' alt='$alt' style='border:0; $styleAtt'>}
        }
    }
    #ns_log notice "RETURN  HTML [subst -nocommands $template] cmd $cmd]"
    return [list HTML [subst -nocommands $template] cmd $cmd]
}

namespace eval ::template::icon {
    set ::template::icon::map {
        bootstrap-icons {
            add-new-item         plus-circle
            checkbox-checked     check2-square
            checkbox-unchecked   square
            edit                 pencil-square
            eye-closed           eye-slash
            eye-open             eye
            file                 file-earmark
            filetype-csv         filetype-csv
            form-info-sign       info-square
            list-alt             card-heading
            next                 chevron-right
            previous             chevron-left
            radio-checked        check2-circle
            radio-unchecked      circle
            reload               arrow-clockwise
            text                 file-earmark-text
            user                 person
            warn                 exclamation-triangle-fill
            watch                eye
        }
        fa-icons {
            add-new-item         "fa-solid fa-plus"
            arrow-down           "fa-solid fa-arrow-down"
            arrow-left           "fa-solid fa-arrow-left"
            arrow-right          "fa-solid fa-arrow-right"
            arrow-up             "fa-solid fa-arrow-up"
            checkbox-checked     "fa-regular fa-square-check"
            checkbox-unchecked   "fa-regular fa-square"
            download             "fa-solid fa-download"
            edit                 "fa-regular fa-pen-to-square"
            eye-closed           "fa-regular fa-eye-slash"
            eye-open             "fa-regular fa-eye"
            file                 "fa-regular fa-file"
            filetype-csv         "fa-solid fa-file-csv"
            folder               "fa-regular fa-folder"
            form-info-sign       "fa-solid fa-circle-info"
            link                 "fa-solid fa-link"
            list                 "fa-solid fa-list"
            list-alt             "fa-regular fa-rectangle-list"
            next                 "fa-solid fa-chevron-right"
            paperclip            "fa-light fa-paperclip"
            previous             "fa-solid fa-chevron-left"
            user                 "fa-solid fa-user"
            radio-checked        "fa-regular fa-circle-check"
            radio-unchecked      "fa-regular fa-circle"
            reload               "fa-solid fa-arrows-rotate"
            text                 "fa-regular fa-file-lines"
            trash                "fa-regular fa-trash-can"
            warn                 "fa-solid fa-triangle-exclamation"
            watch                "fa-regular fa-eye"
        }
        glyphicons {
            add-new-item         plus-sign
            checkbox-checked     check
            checkbox-unchecked   unchecked
            download             download-alt
            edit                 pencil
            eye-closed           eye-close
            eye-open             eye-open
            file                 file
            filetype-csv         ""
            folder               folder-open
            form-info-sign       info-sign
            link                 link
            list-alt             list-alt
            next                 menu-right
            paperclip            paperclip
            previous             menu-left
            radio-checked        record
            radio-unchecked      /shared/images/radio.gif
            reload               refresh
            text                 file
            user                 user
            warn                 alert
            watch                eye-open
        }
        classic {
            add-new-item         "+"
            arrow-down           /resources/acs-subsite/arrow-down.gif
            arrow-left           /resources/acs-subsite/arrow-left.png
            arrow-right          /resources/acs-subsite/arrow-right.png
            arrow-up             /resources/acs-subsite/arrow-up.gif
            checkbox-checked     /shared/images/checkboxchecked.gif
            checkbox-unchecked   /shared/images/checkbox.gif
            download             /shared/images/download16.png
            edit                 /shared/images/Edit16.gif
            eye-closed           /shared/images/eye-slash16.png
            eye-open             /shared/images/eye16.png
            filetype-csv         /shared/images/csv16.png
            file                 /shared/images/file.gif
            folder               /shared/images/Delete16.gif
            form-info-sign       /shared/images/info.gif
            link                 /resources/acs-subsite/url-button.gif
            list                 /shared/images/list16.png
            list-alt             /shared/images/Preferences16.gif
            next                 "rlaquo;"
            paperclip            /resources/acs-subsite/attach.png
            previous             "&laquo;"
            radio-checked        /shared/images/radiochecked.gif
            radio-unchecked      /shared/images/radio.gif
            text                 /shared/images/text16.png
            reload               /shared/images/recylce16.png
            trash                /shared/images/Delete16.gif
            user                 /shared/images/profile-16.png
            warn                 /shared/images/diamond.gif
            watch                /shared/images/eye16.png
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
