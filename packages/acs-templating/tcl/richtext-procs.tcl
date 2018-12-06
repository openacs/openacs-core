ad_library {
    Rich text input widget and datatype for OpenACS templating system.

    @author Lars Pind (lars@pinds.com)
    @creation-date 2003-01-27
}

namespace eval template {}
namespace eval template::data {}
namespace eval template::data::transform {}
namespace eval template::data::validate {}
namespace eval template::util {}
namespace eval template::util::richtext {}
namespace eval template::widget {}
namespace eval template::data::to_sql {}
namespace eval template::data::from_sql {}

ad_proc -public template::util::richtext { command args } {
    Dispatch procedure for the richtext object
} {
  template::util::richtext::$command {*}$args
}

ad_proc -public template::util::richtext::create {
    {contents {}}
    {format {}}
} {
    Create a richtext widget

    @param contents The text content of the widget
    @param format How that text is formatted (text, html, etc)

    @return Two-element list of the joined parameters
} {
    return [list $contents $format]
}

ad_proc -public template::util::richtext::acquire { type { value "" } } {
    Create a new richtext value with some predefined value
    Basically, create and set the richtext value
} {
  set richtext_list [template::util::richtext::create]
  return [template::util::richtext::set_property $type $richtext_list $value]
}

ad_proc -public template::util::richtext::formats {} {
    Returns a list of valid richtext formats
} {
    return { text/enhanced text/markdown text/plain text/html text/fixed-width }
}

ad_proc -public template::util::richtext::format_options {} {
    Returns a formatting option list
} {
    return [list \
                [list [_ acs-templating.Enhanced_Text] text/enhanced] \
                [list [_ acs-templating.Markdown_Text] text/markdown] \
                [list [_ acs-templating.Plain_Text] text/plain] \
                [list [_ acs-templating.Fixed_width_Text] text/fixed-width] \
                [list [_ acs-templating.HTML] text/html]]
}

ad_proc -public template::data::validate::richtext {
    value_ref
    message_ref
} {
    Validate richtext after form submission.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if the submitted data is valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref richtext_list
    lassign $richtext_list contents format

    if { $contents ne "" && [lsearch -exact [template::util::richtext::formats] $format] == -1 } {
        set message "Invalid format, '$format'."
        return 0
    }

    # enhanced text and HTML needs to be security checked
    if { $format in { text/enhanced text/html } } {

        set check_result [ad_html_security_check $contents]
        if { $check_result ne "" } {
            set message $check_result
            return 0
        }
    }

    return 1
}

ad_proc -public template::data::transform::richtext {
    element_ref
} {
    Transform the previously-validated submitted data into a two-element list
    as defined by the richtext datatype.

    @param element_ref Reference variable to the form element

    @return Two-element list defined by the richtext datatype
} {

    upvar $element_ref element
    set element_id $element(id)

    set contents [ns_queryget $element_id]
    set format [ns_queryget $element_id.format]

    if { $contents eq "" } {
        # We need to return the empty list in order for form builder to think of it
        # as a non-value in case of a required element.
        return [list]
    } else {
        return [list [list $contents $format]]
    }
}

ad_proc -public template::util::richtext::set_property { what richtext_list value } {
    Set a property of the richtext datatype.

    @param what One of
      <ul>
        <li>contents (synonyms content, text)</li>
        <li>format (synonym mime_type)</li>
      </ul>

    @param richtext_list the richtext list to modify
    @param value the new value

    @return the modified list
} {
    lassign $richtext_list contents format

    switch -- $what {
        contents - content - text {
            # Replace contents with value
            return [list $value $format]
        }
        format - mime_type {
            # Replace format with value
            return [list $contents $value]
        }
        default {
            error "Invalid property $what, valid properties are text (synonyms content, contents), mime_type (synonym format)."
        }
    }
}

ad_proc -public template::util::richtext::get_property { what richtext_list } {

    Get a property of the richtext datatype. Valid properties are:

    @param what the name of the property. Must be one of:
    <ul>
    <li>contents (synonyms content, text) - returns the actual contents of the textarea field</li>
    <li>format (synonym mime_type) - returns the mimetype, e.g. 'text/plain'</li>
    <li>html_value - returns the content converted to html format, regardless of the format the content is actually in. In case it is already text/html no conversion will be applied.</li></ul>

    @param richtext_list a richtext datatype value, usually created with ad_form.
} {
    lassign $richtext_list contents format

    switch -- $what {
        content - contents - text {
            return $contents
        }
        format - mime_type {
            return $format
        }
        html_value {
            if { $contents ne "" } {
                return [ad_html_text_convert -from $format -to "text/html" -- $contents]
            } else {
                return {}
            }
        }

        default {
            error "Parameter supplied to util::richtext::get_property 'what' must be one of: 'contents', 'format', 'html_value'. You specified: '$what'."
        }
    }
}



# ----------------------------------------------------------------------
#
# Richtext plugin interface
#
# ----------------------------------------------------------------------

ad_proc -public template::util::richtext::initialize_widget {
    -form_id
    -text_id
    -editor
    {-options {}}
} {

    Initialize a single text input (textarea with the id "text_id"
    part of a form with "form_id") for the specified richtext editor
    via a richtext-editor plugin (e.g. ckeditor4, tinymce, or xinha)

    @param form_id   ID of the form containing the textarea
    @param text_id   ID of the textarea
    @param editor    Editor, which should be used
    @param options   Options passed in from the widget spec

    @return          On success, this function returns a dict with success 1

} {
    if {![require_editor -editor $editor]} {
        return {success 0}
    }

    set result {success 1}
    lappend result {*}[::richtext::${editor}::initialize_widget \
                           -form_id $form_id \
                           -text_id $text_id \
                           -options $options]
    return $result
}

set ::template::util::richtext::editors {}

#
# Check if an editor package of this kind is installed
#
ad_proc -private template::util::richtext::require_editor {
    -editor
} {
    Check, whether this editor package is installed.
} {
    if {$editor ni $::template::util::richtext::editors} {
        ns_log warning "richtext: no editor with name $editor is registered"
        return 0
    }
    return 1
}


ad_proc -public template::util::richtext::get_tag {
    {-options {}}
} {

    Return tag name for the markup; normally a "textarea", but some
    editors might use e.g. a "div". If the function is defined for the
    editor, call it.

} {
    set tag textarea
    if {[dict exists $options editor]
        && [info commands ::richtext::[dict get $options editor]::get_tag] ne ""
    } {
        set tag [::richtext::[dict get $options editor]::get_tag -options $options]
    }
    return $tag
}


ad_proc -public template::util::richtext::register_editor { editor } {

    Make an rich-text editor known to the templating system.

    @param editor  Editor to be registered
    @return        List of editors registered so far

} {
    lappend ::template::util::richtext::editors $editor
}

ad_proc -public template::util::richtext::render_widgets { } {

    Render all rich-text editors with their widget specific
    code. Every editor might have multiple instances on the page,
    which are accessible to "render_widgets" via the global variable
    acs_blank_master__htmlareas. This function can be used to perform
    a single (customization) operation relevant for multiple widgets.

} {

    ns_log debug "we have the following editors registered: $::template::util::richtext::editors"

    foreach editor $::template::util::richtext::editors {
        ::richtext::${editor}::render_widgets
    }
}


ad_proc -public template::widget::richtext { element_reference tag_attributes } {

    <p>
    Implements the richtext widget, which offers rich text editing options.

    This version integrates support for the <strong>xinha</strong> and
    <strong>tinymce</strong> editors out of the box, but other richtext editors
    can be used including and configuring them in your custom template.

    If the acs-templating.UseHtmlAreaForRichtextP parameter is set to true (1),
    this will use the WYSIWYG editor widget set in the acs-templating.RichTextEditor
    parameter.
    Otherwise, it will use a normal textarea, with a drop-down to select a format.
    The available formats are:
    </p>

    <ul>
    <li>Enhanced text = Allows HTML, but automatically inserts line and paragraph breaks.
    <li>Plain text = Automatically inserts line and paragraph breaks, and quotes
    all HTML-specific characters, such as less-than, greater-than, etc.
    <li>Fixed-width text = Same as plain text, but conserves spacing; useful
    for tabular data.
    <li>HTML = normal HTML.
    </ul>

    <p>
    You can also parameterize the richtext widget with a 'htmlarea_p' attribute,
    which can be true or false, and which will override the parameter setting.
    <p>
    The richtext widget can be extended with several plugins, which are OpenACS
    packages named richtex-EDITOR. Plugins are available e.g. for xinha, tinymce
    and ckeditor4. When the plugins are installed, one can use e.g. xinha
    by specifying 'editor xinha' in the options of the widget spec.
    The following options for xinha may be specified:
    <ul>
    <li> <em>editor</em>: xinha
    <li> <em>height</em>: height of the xinha widget (e.g. 350px)
    <li> <em>width</em>: width of the xinha widget (e.g. 500px)
    <li> <em>plugins</em>: Tcl list of plugins to be used in xinha. There
    is an a special plugin for the oacs file selector available, called OacsFs.
    If no options are specified, the following plugins will be loaded:
    <code>
    GetHtml CharacterMap ContextMenu FullScreen
    ListType TableOperations EditTag LangMarks Abbreviation
    </code>
    </ul>
    <p>
    These options are used by the OacsFs plugin
    <ul>
    <li> <em>folder_id</em>: the folder from which files should be taken
    for the file selector. Can be used alternative with fs_package_id, whatever
    more handy in the application.
    <li> <em>fs_package_id</em>: the package id of the file_storage package
    from which files should be taken
    for the file selector. Can be used alternative with folder_id, whatever
    more handy in the application. If nothing is specified, the
    globally mounted file-store is used.
    <li> <em>file_types</em>: SQL match pattern for selecting certain types
    of files (e.g. pdf files). The match pattern is applied on the MIME
    type of the field. E.g. a value of %text/% allows any kind of text
    files to be selected, while %pdf% could be used for pdf-files. If
    nothing is specified, all file-types are presented.
    <li> <em>javascript</em>: provide JavaScript code to configure
    the xinha widget and its plugins. The configure object is called <code>xinha_config</code>.
    </ul>

    <p>
    Example to use xinha with only a few controls:

    <pre>
    {options {editor xinha plugins {OacsFs} height 350px javascript {
        xinha_config.toolbar = [
                                ['popupeditor', 'bold','italic','createlink','insertimage','separator'],
                                ['killword','removeformat'] ];
    }}}
    </pre>

    <p>
    Example for the use of the <strong>xinha</strong> widget with options:
    <pre>
    text:richtext(richtext),nospell,optional
    {label #xowiki.content#}
    {options {editor xinha plugins OacsFs height 350px file_types %pdf%}}
    {html {rows 15 cols 50 style {width: 100%}}}
    </pre>

    <p>
    Caveat: the three adp-files needed for the OpenACS file selector
    (insert-image, insert-ilink and file-selector)
    are currently part of the xowiki package, since acs-templating
    is per default not mounted. This is hopefully only a temporal situation
    and we find a better place.

    <p>
    Example for the use of the <strong>tinymce</strong> widget with options:
    <pre>
    text:richtext(richtext),nospell,optional
    {label #acs-subsite.Biography#}
    {options {theme simple plugins "oacsimage,oacslink,style"}}
    {html {rows 15 cols 50 style {width: 100%}}}
    </pre>
    <p>
    See <a href="http://wiki.moxiecode.com/index.php/TinyMCE:Configuration">TinyMCE
    documentation</a> for a full list of available options
    <p>
    Caveat: the scripts needed for the oacsimage and oacslink plugins require
    acs-templating to be mounted. This is a temporary situation until we find
    a better way to handle plugins.

    <p>
    Example for the use of a custom editor widget:
    <pre>
    text:richtext(richtext),nospell,optional
    {label #acs-subsite.Biography#}
    {options {editor custom ...custom configuration...}}
    {html {rows 15 cols 50 style {width: 100%}}}
    </pre>
    <p>
    If provided with a WYSIWYG editor different than 'xinha' or 'tinymce',
    system will just collect formfield ids and supplied options for the
    richtext field and will provide them as-is to the blank-master environment.
    When using a custom editor, funcional meaning of the options is totally up
    to the user.

    <p>
    Note that the richtext editors interact with <code>blank-master.tcl</code> and
    <code>blank-master.adp</code>.
    <p>
    Derived from the htmlarea richtext widget for htmlarea by lars@pinds.com<br>
    modified for RTE http://www.kevinroth.com/ by davis@xarg.net<br>
    xinha and ckeditor4 support by gustaf.neumann@wu-wien.ac.at<br>
    tinymce support by oct@openacs.org
} {

    upvar $element_reference element
    set output ""

    #ns_log notice "widget::richtext: richtext-options? [info exists element(options)] HTML? [info exists element(html)]"

    if { [info exists element(html)] } {
        array set attributes $element(html)
    }

    array set attributes $tag_attributes

    if { [info exists element(value)] } {
        set contents [template::util::richtext::get_property contents $element(value)]
        set format   [template::util::richtext::get_property format $element(value)]
    } else {
        set contents {}
        set format {}
    }

    array set options [expr {[info exists element(options)] ? $element(options) : ""}]

    if { $element(mode) eq "edit" } {
        set attributes(id) $element(id)
        set package_id_templating [apm_package_id_from_key "acs-templating"]

        set user_agent [string tolower [ns_set get [ns_conn headers] User-Agent]]

        if {[string first "safari" $user_agent] != -1} {
            if {[regexp {version/([0-9]+)[.]} $user_agent _ user_agent_version]
                && $user_agent_version < 3} {
                set element(htmlarea_p) false
            }
        } elseif {[string first "opera" $user_agent] != -1} {
            if {[regexp {^[^/]+/([0-9]+)[.]} $user_agent _ user_agent_version]
                && $user_agent_version < 9} {
                set element(htmlarea_p) false
            }
        }

        if { [info exists element(htmlarea_p)] && $element(htmlarea_p) ne "" } {
            set htmlarea_p [template::util::is_true $element(htmlarea_p)]
        } else {
            set htmlarea_p [parameter::get \
                                -package_id $package_id_templating \
                                -parameter "UseHtmlAreaForRichtextP" \
                                -default 0]
        }
        set edit_item_tag [::template::util::richtext::get_tag -options [array get options]]
        set format_menu [menu $element(id).format [template::util::richtext::format_options] $format {}]
        set output [textarea_internal $element(id) attributes $contents "edit" $edit_item_tag]

        # Spell-checker
        array set spellcheck [template::util::spellcheck::spellcheck_properties \
                                  -element_ref element]
        #ns_log notice "widget::richtext: $htmlarea_p, spellcheck [array get spellcheck] OPTIONS [array get options]"

        if { $htmlarea_p } {
            # figure out, which rich text editor to use
            set richtextEditor [expr {[info exists options(editor)] ?
                                      $options(editor) : [parameter::get \
                                                              -package_id $package_id_templating \
                                                              -parameter "RichTextEditor" \
                                                              -default "xinha"]}]
            #
            # Tell the blank-master to include the special stuff
            # for the richtext widget in the page header
            #
            set ::acs_blank_master($richtextEditor) 1

            #
            # Collect ids of richtext form fields
            #
            lappend ::acs_blank_master__htmlareas $attributes(id)

            #
            # Try to initialize the widget via richtext plugins
            #
            set result [::template::util::richtext::initialize_widget \
                            -form_id $element(form_id) \
                            -text_id $attributes(id) \
                            -editor $richtextEditor \
                            -options [array get options]]
            ns_log debug "widget::richtext: ::template::util::richtext::initialize_widget -> $result"

            if {[dict get $result success] == 1} {
                #
                # Everything is set-up via the editor plugin. In
                # general, we can pass back more information back from
                # the plugins via the dict "result" without extending
                # the interface, but that feature is not used yet.
                #
            } else {
                # Editor is custom. All options are passed as-is to
                # the blank master and their meaning will be defined
                # in a custom template.

                set ::acs_blank_master(${richtextEditor}.options) [array get options]
            }

            #
            # The following trick with document.write is for providing
            # reasonable behavior when JavaScript is turned completely
            # off.
            #
            append output \
                "</span>\n<script type='text/javascript' nonce='$::__csp_nonce'>\n" \
                [subst {document.write("<input name='$element(id).format' value='text/html' type='hidden'>");}] \
                "</script>\n<noscript><div>" \
                [subst {<span class="form-widget"><label for="$element(id).format">[_ acs-templating.Format]: </label>}] \
                $format_menu "</span></div></noscript>\n" \
                "<span>"

            if { $spellcheck(render_p) } {
                append output [subst {</span>
                    <span class="form-widget"><label for="$element(id).spellcheck">[_  acs-templating.Spellcheck]: </label>
                    [menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] \
                    $spellcheck(selected_option) {}]
                }]
            }

        } else {
            # htmlarea_p is false

            append output [subst {</span>
                <span class="form-widget"><label for="$element(id).format">[_ acs-templating.Format]: </label>$format_menu
            }]

            if { $spellcheck(render_p) } {
                append output [subst {</span>
                    <span class="form-widget"><label for="$element(id).spellcheck">[_  acs-templating.Spellcheck]: </label>
                    [menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] \
                         $spellcheck(selected_option) {}]
                }]
            }

        }

    } else {
        # Display mode
        if { $element(mode) eq "display" && [info exists element(value)] } {
            append output [template::util::richtext::get_property html_value $element(value)]
            append output "<input type=\"hidden\" name=\"$element(id)\" value=\"[ns_quotehtml $contents]\">"
            append output "<input type=\"hidden\" name=\"$element(id).format\" value=\"[ns_quotehtml $format]\">"
        }
    }

    return $output
}

ad_proc template::data::to_sql::richtext { value } {

    Handle richtext transformations using a standardized naming convention.

} {
    return [::ns_dbquotevalue [list [template::util::richtext::get_property content $value] \
                                   [template::util::richtext::get_property format $value]]]
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
