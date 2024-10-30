ad_library {
    Template style handling

    @author Gustaf Neumann
}

ad_proc -private template::toolkit {-subsite_id} {

    Return the CSS toolkit or empty the current or given subsite.
    Potential result values are "" (undetermined) "bootstrap" (for
    Bootstrap 3), "bootstrap5" (for Bootstrap 5), or "w3css".

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
        } elseif {[string match *w3css* $theme]} {
            set toolkit w3css
        }
    }
    return $toolkit
}

namespace eval ::template {
    nx::Object create ::template::CSS {
        #
        # CSS property manager. This class is used for agnostic handling
        # of icons, CSS class names, or styling preferences of a
        # subsite/instance.
        #

        dict set :cssClasses w3css {
            btn-default ""
            btn-outline-secondary "w3-btn w3-white w3-border w3-border-grey w3-round"
            margin-form margin-form
        }
        dict set :cssClasses bootstrap5 {
            action "btn btn-outline-secondary btn-sm m-1"
            btn-default btn-outline-secondary
            bulk-action "btn btn-outline-secondary btn-sm"
            checkbox-inline form-check-inline
            close btn-close
            cog gear
            form-action "btn btn-outline-secondary btn-sm m-1"
            margin-form ""
            navbar-default navbar-light
            navbar-right ms-auto
            print printer
            radio-inline form-check-inline
        }
        dict set :cssClasses bootstrap {
            action "btn btn-default"
            btn-default btn-default
            bulk-action "btn btn-default"
            card "panel panel-default"
            card-body panel-body
            card-header panel-heading
            d-none hidden
            form-action "btn btn-default"
            margin-form ""
            text-warning text-warn
        }
        dict set :cssClasses yui {
            card portlet-wrapper
            card-body portlet
            card-header portlet-header
        }
        dict set :cssClasses default {
            btn-default ""
            margin-form margin-form
        }

        :public object method clear {} {
            #
            # Clear the cached toolkit name, such that it is reloads the
            # settings on the next initialize call.
            #
            unset -nocomplain :preferredCSSToolkit
        }

        :public object method toolkit {} {
            #
            # Return the preferred CSS toolkit
            #
            return ${:preferredCSSToolkit}
        }

        :public object method icon_name {filename} {
            #
            # Return an icon name for the proved filename
            #
            # Default icon name
            set iconName file
            if {${:iconset} eq "bootstrap-icons"} {
                switch [ad_file extension $filename] {
                    .doc  -
                    .docx -
                    .odt  -
                    .txt  {set iconName "file-earmark-text"}

                    .csv  -
                    .ods  -
                    .xls  -
                    .xlsx {set iconName "file-earmark-spreadsheet"}

                    .odp  -
                    .ppt  -
                    .pptx {set iconName "file-earmark-spreadsheet"}

                    .pdf  {set iconName "file-earmark-pdf"}

                    .c    -
                    .h    -
                    .tcl {set iconName "file-earmark-code"}

                    .css  -
                    .html -
                    .java -
                    .js   -
                    .json -
                    .py   -
                    .sql {set iconName "filetype-[string range [ad_file extension $filename] 1 end]"}

                    default {
                        switch -glob [ns_guesstype $filename] {
                            image/* {set iconName "file-earmark-image"}
                            video/* {set iconName "file-earmark-play"}
                            audio/* {set iconName "file-earmark-slides"}
                            default {
                                ns_log notice "not handled '[ad_file extension $filename] / [ns_guesstype $filename] of <$filename>"
                            }
                        }
                    }
                }
            }
            return $iconName
        }

        :public object method require_toolkit {{-css:switch} {-js:switch}} {
            #
            # Make sure that the preferred toolkit is loaded. Note that some
            # combination won't match nicely, since e.g. the toolbar of a
            # theme based on bootstrap5 is messed up, when the preferred
            # toolkit is bootstrap3. .... so, we should have some default
            # setting or fallbacks to handle such situations.
            #
            if {${:preferredCSSToolkit} eq "bootstrap5"} {
                if {$css} {::template::head::add_css -href urn:ad:css:bootstrap5}
                if {$js}  {::template::head::add_javascript -src urn:ad:js:bootstrap5}
            } elseif {${:preferredCSSToolkit} eq "bootstrap"} {
                if {$css} {::template::head::add_css -href urn:ad:css:bootstrap3}
                if {$js}  {::template::head::add_javascript -src urn:ad:js:bootstrap3}
            } else {
                # YUI has many simple files, let the application decide what
                # to be loaded.
            }
        }

        :public object method initialize {} {
            #
            # Initialize tailorization for CSS toolkits. The function reads
            # the global apm package parameter and sets/resets accordingly
            # (a) the default values (actually parameters) for the form
            # field and (b) defines the toolkit specific CSS class name
            # mapping.
            #
            #
            # Loading optional, but universally present header files has do
            # be performed per request... not sure this is the best place,
            # since packages are as well initialized in the background.
            #
            if {[ns_conn isconnected] && [apm_package_enabled_p "bootstrap-icons"]} {
                template::head::add_css -href urn:ad:css:bootstrap-icons
            }
            set paramValue [parameter::get_global_value -package_key acs-templating \
                                -parameter PreferredCSSToolkit \
                                -default [parameter::get_global_value -package_key xowiki \
                                              -parameter PreferredCSSToolkit \
                                              -default default]]
            #
            # Check, if parameter value is compatible with the theme. In
            # particular, a preferred toolkit of "bootstrap3" does not work
            # when the theme is based on Bootstrap 5 and vice versa. When necessary,
            # align the value.
            #
            if {$paramValue in {default bootstrap bootstrap5} && [ns_conn isconnected]} {
                set theme [subsite::get_theme]
                if {$paramValue in {bootstrap default} && [string match *bootstrap5* $theme]} {
                    set paramValue bootstrap5
                } elseif {$paramValue in {bootstrap5 default} && [string match *bootstrap3* $theme]} {
                    set paramValue bootstrap
                }
                if {$paramValue eq "default"} {
                    # For the time being, YUI is the default (deriving default
                    # toolkit from theme did not work, we have to assume that
                    # the fonts for Bootstrap 3 or 5 are not loaded for edit
                    # buttons, etc.
                    set paramValue yui
                }
            }

            #
            # Just do initialization once
            #
            if {[info exists :preferredCSSToolkit]
                && ${:preferredCSSToolkit} eq $paramValue
            } {
                return
            }
            #ns_log notice "template::CSS: initialize to <$paramValue>"
            #
            # The code below is executed only on first initialization of the
            # object or on changes of the preferredCSSToolkit.
            #
            set :preferredCSSToolkit $paramValue
            set :iconset [template::iconset]

            if {${:preferredCSSToolkit} eq "bootstrap"} {
                if {[info commands ::xowiki::formfield::FormField] ne ""} {
                    ::xowiki::formfield::FormField parameter [subst {
                        {CSSclass form-control}
                        {form_item_wrapper_CSSclass form-group}
                        {form_label_CSSclass ""}
                        {form_widget_CSSclass ""}
                        {form_button_CSSclass "[template::CSS class form-action]"}
                        {form_button_wrapper_CSSclass ""}
                        {form_help_text_CSSclass help-block}
                    }]
                }
            } elseif {${:preferredCSSToolkit} eq "bootstrap5"} {
                if {[info commands ::xowiki::formfield::FormField] ne ""} {
                    ::xowiki::formfield::FormField parameter [subst {
                        {CSSclass form-control}
                        {form_item_wrapper_CSSclass mb-3}
                        {form_label_CSSclass "form-label me-1"}
                        {form_widget_CSSclass ""}
                        {form_button_CSSclass "[template::CSS class form-action]"}
                        {form_button_wrapper_CSSclass ""}
                        {form_help_text_CSSclass form-text}
                    }]
                    ::xowiki::formfield::select parameter {
                        {CSSclass form-select}
                    }
                    ::xowiki::formfield::checkbox parameter {
                        {CSSclass form-check}
                    }
                    ::xowiki::formfield::radio parameter {
                        {CSSclass form-check}
                    }
                    ::xowiki::formfield::range parameter {
                        {CSSclass form-range}
                    }
                }
            } else {
                if {[info commands ::xowiki::formfield::FormField] ne ""} {

                    ::xowiki::formfield::FormField parameter {
                        {CSSclass}
                        {form_label_CSSclass ""}
                        {form_widget_CSSclass form-widget}
                        {form_item_wrapper_CSSclass form-item-wrapper}
                        {form_button_CSSclass ""}
                        {form_button_wrapper_CSSclass form-button}
                        {form_help_text_CSSclass form-help-text}
                    }
                    ::xowiki::Form requireFormCSS
                }
            }
        }

        :public object method registerCSSclasses {toolkit dict} {
            #
            # Register CSS class mapping for the provided framework
            #
            nsv_set acs_templating_cssClasses $toolkit $dict
        }

        #
        # Initialize acs_templating_cssClasses in case, nothing is
        # registered.
        #
        nsv_set acs_templating_cssClasses . .

        :public object method class {-toolkit name} {
            #
            # In case, a mapping for CSS classes is defined, return the
            # mapping for the provided class name. Otherwise return the
            # input class name unmodified.
            #
            if {![info exists toolkit]} {
                set toolkit ${:preferredCSSToolkit}
                if {$toolkit eq "default"} {
                    set toolkit [template::toolkit]
                    set :preferredCSSToolkit $toolkit
                    ns_log notice "derived CSS toolkit '$toolkit'"
                }
            }

            if {[nsv_get acs_templating_cssClasses $toolkit dict]} {
                if {[dict exists $dict $name]} {
                    return [dict get $dict $name]
                }
            } else {
                ns_log warning "template::CSS: no class mapping for" \
                    "toolkit $toolkit provided (should be in theme definition)"
            }

            if {[dict exists ${:cssClasses} $toolkit $name]} {
                return [dict get ${:cssClasses} $toolkit $name]
            } else {
                return $name
            }
        }

        :public object method classes {classNames} {
            #
            # Map a list of CSS class names
            #
            return [join [lmap class $classNames {:class $class}] " "]
        }
    }
}

ad_proc ::template::icon::name {-iconset name} {

    Return for the provided generic name the name in the specified or
    current iconset the name mapping. This function is necessary in
    boundary cases, where e.g. a display_template passes the generic
    name of the icon via template variables which have to be
    @-substituted before adp-tag resolution, which performs the
    regular icon name mapping. Otherwise, the tag resolver receives,
    e.g., ...name=@icon@...

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
    "classic" (old-style gif/png images), "glyphicons"
    (Part of Bootstrap 3), "fa-icons" (usable for all themes), and
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
    {-invisible:boolean f}
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

    @param alt used in classic images. When not specified, use 'title' attribute
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
    set firstchar [string range $name 0 0]
    if {$firstchar eq "/"} {
        set iconset default
    } elseif {$name eq ""} {
        set iconset text
    } elseif {![string match {[a-z@]} $firstchar]} {
        set iconset text
        set alt $name
    }
    set _class [expr {$class ne "" ? " $class" : ""} ]
    set title [ns_quotehtml $title]
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
            #
            # When "title" is a message key, and it is used e.g. in
            # the "title" and "alt" fields, then the edit icon is
            # displayed twice in TRN mode, which look like a bug. So,
            # don't set alt per default to the message key, when it
            # looks like a message key... Or maybe better, force the
            # user to set the "alt" attribute.
            #
            #if {$alt eq "" && [string first "#" $title] == -1} {set alt $title}
            set template {<img class='$class' src='$name' height='16' width='16' title='$title' alt='$alt' style='border:0; $styleAtt'>}
        }
    }
    if {$invisible_p} {
        set template "<span style='visibility:hidden;'>$template</span>"
    }
    #ns_log notice "RETURN  HTML [subst -nocommands $template] cmd $cmd]"
    return [list HTML [subst -nocommands $template] cmd $cmd]
}

namespace eval ::template::icon {

    set ::template::icon::map {
        bootstrap-icons {
            add-new-item         plus-circle
            admin                wrench-adjustable
            checkbox-checked     check2-square
            checkbox-unchecked   square
            check                check-lg
            cog                  gear
            edit                 pencil-square
            eye-closed           eye-slash
            eye-open             eye
            file                 file-earmark
            filetype-csv         filetype-csv
            folder-add           folder-plus
            form-info-sign       info-square
            list-alt             card-heading
            mount                arrow-up-circle
            next                 chevron-right
            permissions          lock
            previous             chevron-left
            radio-checked        check2-circle
            radio-unchecked      circle
            reload               arrow-clockwise
            search               search
            sitemap              diagram-3
            text                 file-earmark-text
            unmount              eject
            user                 person
            warn                 exclamation-triangle-fill
            watch                eye
        }
        fa-icons {
            add-new-item         "fa-solid fa-plus"
            admin                "fa-solid fa-wrench"
            arrow-down           "fa-solid fa-arrow-down"
            arrow-left           "fa-solid fa-arrow-left"
            arrow-right          "fa-solid fa-arrow-right"
            arrow-up             "fa-solid fa-arrow-up"
            check                "fa-solid fa-check"
            checkbox-checked     "fa-regular fa-square-check"
            checkbox-unchecked   "fa-regular fa-square"
            cog                  "fa-solid fa-gear"
            download             "fa-solid fa-download"
            edit                 "fa-regular fa-pen-to-square"
            eye-closed           "fa-regular fa-eye-slash"
            eye-open             "fa-regular fa-eye"
            file                 "fa-regular fa-file"
            filetype-csv         "fa-solid fa-file-csv"
            folder               "fa-regular fa-folder"
            folder-add           "fa-solid fa-plus"
            form-info-sign       "fa-solid fa-circle-info"
            link                 "fa-solid fa-link"
            list                 "fa-solid fa-list"
            list-alt             "fa-regular fa-rectangle-list"
            mount                "fa-regular fa-circle-up"
            next                 "fa-solid fa-chevron-right"
            paperclip            "fa-light fa-paperclip"
            permissions          "fa-solid fa-lock"
            previous             "fa-solid fa-chevron-left"
            user                 "fa-solid fa-user"
            radio-checked        "fa-regular fa-circle-check"
            radio-unchecked      "fa-regular fa-circle"
            reload               "fa-solid fa-arrows-rotate"
            search               "fa-solid fa-magnifying-glass"
            sitemap              "fa-solid fa-sitemap"
            text                 "fa-regular fa-file-lines"
            unmount              "fa-solid fa-eject"
            trash                "fa-regular fa-trash-can"
            warn                 "fa-solid fa-triangle-exclamation"
            watch                "fa-regular fa-eye"
        }
        glyphicons {
            admin                wrench
            add-new-item         plus-sign
            checkbox-checked     check
            checkbox-unchecked   unchecked
            cog                  cog
            download             download-alt
            edit                 pencil
            eye-closed           eye-close
            eye-open             eye-open
            file                 file
            filetype-csv         ""
            folder               folder-open
            folder-add           plus-sign
            form-info-sign       info-sign
            link                 link
            list-alt             list-alt
            mount                collapse-up
            next                 menu-right
            paperclip            paperclip
            permissions          lock
            previous             menu-left
            radio-checked        record
            radio-unchecked      /shared/images/radio.gif
            reload               refresh
            search               search
            sitemap              /resources/acs-subsite/sitemap.svg
            text                 file
            unmount              eject
            user                 user
            warn                 alert
            watch                eye-open
        }
        classic {
            add-new-item         "+"
            admin                ""
            arrow-down           /resources/acs-subsite/arrow-down.gif
            arrow-left           /resources/acs-subsite/arrow-left.png
            arrow-right          /resources/acs-subsite/arrow-right.png
            arrow-up             /resources/acs-subsite/arrow-up.gif
            checkbox-checked     /shared/images/checkboxchecked.gif
            checkbox-unchecked   /shared/images/checkbox.gif
            check                /shared/images/checkboxchecked.gif
            cog                  " parameters"
            download             /shared/images/download16.png
            edit                 /shared/images/Edit16.gif
            eye-closed           /shared/images/eye-slash16.png
            eye-open             /shared/images/eye16.png
            filetype-csv         /shared/images/csv16.png
            file                 /shared/images/file.gif
            folder               /resources/acs-subsite/Open16.gif
            folder-add           "+"
            form-info-sign       /shared/images/info.gif
            link                 /resources/acs-subsite/url-button.gif
            mount                /resources/acs-subsite/up.gif
            list                 /shared/images/list16.png
            list-alt             /resources/acs-subsite/Preferences16.gif
            next                 "&raquo;"
            paperclip            /resources/acs-subsite/attach.png
            permissions          ""
            previous             "&laquo;"
            radio-checked        /shared/images/radiochecked.gif
            radio-unchecked      /shared/images/radio.gif
            text                 /shared/images/text16.png
            reload               /shared/images/recylce16.png
            search               /resources/acs-subsite/Zoom16.gif
            sitemap              /resources/acs-subsite/sitemap.svg
            trash                /shared/images/Delete16.gif
            unmount              /resources/acs-subsite/down.gif
            user                 /resources/acs-subsite/profile-16.png
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
