ad_library {
    Rich text input widget and datatype for OpenACS templating system.

    @author Lars Pind (lars@pinds.com)
    @creation-date 2003-01-27
    @cvs-id $Id$
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
  eval template::util::richtext::$command $args
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
    return { text/enhanced text/plain text/html text/fixed-width }
}

ad_proc -public template::util::richtext::format_options {} {
    Returns a formatting option list
} {
    return [list \
                [list [_ acs-templating.Enhanced_Text] text/enhanced] \
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

    set contents    [lindex $richtext_list 0]
    set format      [lindex $richtext_list 1]

    if { $contents ne "" && [lsearch -exact [template::util::richtext::formats] $format] == -1 } {
	set message "Invalid format, '$format'."
	return 0
    }

    # enhanced text and HTML needs to be security checked
    if { [lsearch { text/enhanced text/html } $format] != -1 } {

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
    set contents [lindex $richtext_list 0]
    set format   [lindex $richtext_list 1]

    switch $what {
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
    
    Get a property of the richtext datatype. Valid proerties are: 
    
    @param what the name of the property. Must be one of:
    <ul>
    <li>contents (synonyms content, text) - returns the actual contents of the textarea field</li>
    <li>format (synonym mime_type) - returns the mimetype, e.g. 'text/plain'</li>
    <li>html_value - returns the content converted to html format, regardless of the format the content is actually in. In case it is already text/html no conversion will be applied.</li></ul>

    @param richtext_list a richtext datatype value, usually created with ad_form.
} {
    set contents  [lindex $richtext_list 0]
    set format    [lindex $richtext_list 1]

    switch $what {
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

ad_proc -public -deprecated template::widget::richtext_htmlarea { element_reference tag_attributes } {
    Implements the richtext widget, which offers rich text editing options.

    If the acs-templating.UseHtmlAreaForRichtextP parameter is set to true (1), this will use the htmlArea WYSIWYG editor widget.
    Otherwise, it will use a normal textarea, with a drop-down to select a format. The available formats are:
    <ul>
    <li>Enhanced text = Allows HTML, but automatically inserts line and paragraph breaks.
    <li>Plain text = Automatically inserts line and paragraph breaks, and quotes all HTML-specific characters, such as less-than, greater-than, etc.
    <li>Fixed-width text = Same as plain text, but conserves spacing; useful for tabular data.
    <li>HTML = normal HTML.
    </ul>
    You can also parameterize the richtext widget with a 'htmlarea_p' attribute, which can be true or false, and which will override the parameter setting.

    @see template::widget::richtext
} {

  upvar $element_reference element

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
  
  set output {}

  if {$element(mode) eq "edit"} {
      append output {<script type="text/javascript"><!--} \n {acs_RichText_WriteButtons();  //--></script>}
      
      set attributes(id) "richtext__$element(form_id)__$element(id)"
      
      if { [exists_and_not_null element(htmlarea_p)] } {
          set htmlarea_p [template::util::is_true $element(htmlarea_p)]
      } else {
          set htmlarea_p [parameter::get \
                              -package_id [apm_package_id_from_key "acs-templating"] \
                              -parameter "UseHtmlAreaForRichtextP" \
                              -default 0]
      }

      # Check browser's User-Agent header for compatibility with htmlArea
      ad_return_complaint 1 "use htmlareap = $htmlarea_p"
      if { $htmlarea_p } {
          set user_agent [string tolower [ns_set get [ns_conn headers] User-Agent]]
          if { [string first "opera" $user_agent] != -1 } { 
              # Opera - doesn't work, even though Opera claims to be IE
              set htmlarea_p 0
          } elseif { [regexp {msie ([0-9]*)\.([0-9]+)} $user_agent matches major minor] } {
              # IE, works for browsers > 5.5
              if { $major < 5 || ($major == 5  && $minor < 5) } {
                  set htmlarea_p 0
              }
          } elseif { [regexp {gecko/0*([1-9][0-9]*)} $user_agent match build] } {
              if { $build < 20030210 } {
                  set htmlarea_p 0
              }
          } else {
              set htmlarea_p 0
          }
      }

      if { $htmlarea_p } {
          # Tell the blank-master to include the special stuff for htmlArea in the page header
          global acs_blank_master__htmlareas
          lappend acs_blank_master__htmlareas $attributes(id)
      }

      append output [textarea_internal "$element(id)" attributes $contents]
      if { $htmlarea_p } {
          append output "<input name=\"$element(id).format\" value=\"text/html\" type=\"hidden\">"
      } else {
          append output "<br>[_ acs-templating.Format]: [menu $element(id).format [template::util::richtext::format_options] $format attributes]"
      }
          
      # Spell-checker
      array set spellcheck [template::util::spellcheck::spellcheck_properties -element_ref element]
      if { $spellcheck(render_p) } {
          append output " [_ acs-templating.Spellcheck]: [menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] $spellcheck(selected_option) attributes]"
      }
  } else {
      # Display mode
      if { [info exists element(value)] } {
          append output [template::util::richtext::get_property html_value $element(value)]
          append output "<input type=\"hidden\" name=\"$element(id)\" value=\"[ad_quotehtml $contents]\">"
          append output "<input type=\"hidden\" name=\"$element(id).format\" value=\"[ad_quotehtml $format]\">"
      }
  }
      
  return $output
}



ad_proc -public template::widget::richtext { element_reference tag_attributes } {

    <p>
    Implements the richtext widget, which offers rich text editing options.

    This version supports the <strong>xinha</strong> and <strong>tinymce</strong>
    editors.

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
    The available editors in wysigwig mode are xinha and tinymce. In order to 
    use xinha, one has to use 'editor xinha' in the options of the form field. 
    The following options for xinha may be specified:
    <ul>
    <li> <em>editor</em>: xinha
    <li> <em>height</em>: height of the xinha widget (e.g. 350px)
    <li> <em>width</em>: width of the xinha widget (e.g. 500px)
    <li> <em>plugins</em>: tcl list of plugins to be used in xinha. There
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
    for the file selector. Can be used alterantive with fs_package_id, whatever
    more handy in the application.
    <li> <em>fs_package_id</em>: the package id of the file_storage package 
    from which files should be taken
    for the file selector. Can be used alterantive with folder_id, whatever
    more handy in the application. If nothing is specified, the
    globally mounted file-store is used.
    <li> <em>file_types</em>: SQL match pattern for selecting certain types
    of files (e.g. pdf files). The match pattern is applied on the MIME
    type of the field. E.g. a value of %text/% allows any kind of text
    files to be selected, while %pdf% could be used for pdf-files. If
    nothing is specified, all file-types are presented.
    <li> <em>javascript</em>: provide javascript code to configure 
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
    Note that the richtext editors interact with <code>blank-master.tcl</code> and 
    <code>blank-master.adp</code>.
    <p>
    Derived from the htmlarea richtext widget for htmlarea by lars@pinds.com<br>
    modified for RTE http://www.kevinroth.com/ by davis@xarg.net<br>
    xinha support by gustaf.neumann@wu-wien.ac.at<br>
    tinymce support by oct@openacs.org
} {

    upvar $element_reference element
    set output ""
    
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

        if {[string first "chrome" $user_agent] != -1} {
            # vguerra: google chrome browser
            # needs more testing in order to check if chrome fully
            # supports xinha
            # roc: this check has to go first since safari use applewebkit, 
            # so the agent always contain safari word
            # once xinha officially support chrome (already supports safari), we 
            # can remove this if and add the check at the next if.
        } elseif {[string first "safari" $user_agent] != -1} {
            regexp {version/([0-9]+)[.]} $user_agent _ user_agent_version
            if {$user_agent_version < 3} {
                set element(htmlarea_p) false
            }
        } elseif {[string first "opera" $user_agent] != -1} {
            regexp {^[^/]+/([0-9]+)[.]} $user_agent _ user_agent_version
            if {$user_agent_version < 9} {
                set element(htmlarea_p) false
            }
        }

        if { [exists_and_not_null element(htmlarea_p)] } {
            set htmlarea_p [template::util::is_true $element(htmlarea_p)]
        } else {
            set htmlarea_p [parameter::get \
                                -package_id $package_id_templating \
                                -parameter "UseHtmlAreaForRichtextP" \
                                -default 0]
        }

        set format_menu [menu $element(id).format [template::util::richtext::format_options] $format {}]
        set output [textarea_internal $element(id) attributes $contents]

        # Spell-checker
        array set spellcheck [template::util::spellcheck::spellcheck_properties \
                                  -element_ref element]

        if { $htmlarea_p } {
            # figure out, which rich text editor to use
            set richtextEditor [expr {[info exists options(editor)] ?
                                      $options(editor) : [parameter::get \
                                                              -package_id $package_id_templating \
                                                              -parameter "RichTextEditor" \
                                                              -default "xinha"]}]
            # Tell the blank-master to include the special stuff 
            # for the richtext widget in the page header
            set ::acs_blank_master($richtextEditor) 1

            if {$richtextEditor eq "xinha"} {
                
                # we have a xinha richtext widget, specified by "options {editor xinha}"
                # The following options are supported: 
                #      editor plugins width height folder_id fs_package_id
                #
                if {[info exists options(plugins)]} {
                    set plugins $options(plugins)
                } else {
                    set plugins [parameter::get \
                                     -package_id $package_id_templating \
                                     -parameter "XinhaDefaultPlugins" \
                                     -default ""]

                    # GetHtml CharacterMap ContextMenu FullScreen 
                    # ListType TableOperations EditTag LangMarks Abbreviation
                }
                set quoted [list]
                foreach e $plugins {lappend quoted '$e'}
                set ::acs_blank_master(xinha.plugins) [join $quoted ", "]

                set xinha_options ""
                foreach e {width height folder_id fs_package_id script_dir file_types attach_parent_id wiki_p} {
                    if {[info exists options($e)]} {
                        append xinha_options "xinha_config.$e = '$options($e)';\n"
                    }
                }
                # DAVEB add package_id
                append xinha_options "xinha_config.package_id = '[ad_conn package_id]';\n"
                # DAVEB find out if there is a key datatype in the form

                global af_key_name
                if {[info exists af_key_name(${element(form_id)})]} {
                    append xinha_options "xinha_config.key = '[template::element get_value $element(form_id) $af_key_name(${element(form_id)})]';\n"
                }
                if {[info exists options(javascript)]} {
                    append xinha_options $options(javascript) \n
                }
                set ::acs_blank_master(xinha.options) $xinha_options
                lappend ::acs_blank_master__htmlareas $attributes(id)

            } elseif {$richtextEditor eq "tinymce"} {

                lappend ::acs_blank_master__htmlareas $attributes(id)

                # get default configs
                set tinymce_default_config {
                    {mode "exact" } 
                    {relative_urls "false"}
                    {height "450px" }
                    {width "100%"}
                    {plugins "style,layer,table,save,iespell,preview,media,searchreplace,print,contextmenu,paste,fullscreen,noneditable,visualchars,xhtmlxtras" }        
                    {browsers "msie,gecko,safari,opera" }
                    {apply_source_formatting "true" }
                    {paste_auto_cleanup_on_paste true}
                    {paste_convert_headers_to_strong true}
                    {fix_list_elements true}
                    {fix_table_elements true}
                    {theme "openacs"}
                    {theme_openacs_toolbar_location "top" }
                    {theme_openacs_toolbar_align "left" }
                    {theme_openacs_statusbar_location "bottom" }
                    {theme_openacs_resizing true}
                    {theme_openacs_disable "styleselect"}
                    {theme_openacs_buttons1_add_before "save,separator"} 
                    {theme_openacs_buttons2_add "separator,preview,separator,forecolor,backcolor"} 
                    {theme_openacs_buttons2_add_before "cut,copy,paste,pastetext,pasteword,separator,search,replace,separator"} 
                    {theme_openacs_buttons3_add_before "tablecontrols,separator"} 
                    {theme_openacs_buttons3_add "iespell,media,separator,print,separator,fullscreen"}
                    {extended_valid_elements "img[id|class|style|title|lang|onmouseover|onmouseout|src|alt|name|width|height],hr[id|class|style|title],span[id|class|style|title|lang]"}
                    {element_format "html"}}
                set tinymce_configs_list [parameter::get \
                                              -package_id [apm_package_id_from_key "acs-templating"] \
                                              -parameter "TinyMCEDefaultConfig" \
                                              -default $tinymce_default_config]
                set pairslist [list]
                ns_log debug "tinymce: options [array get options]"

                foreach config_pair $tinymce_configs_list {
                    set config_key [lindex $config_pair 0]
                    if {[info exists options($config_key)]} {
                        # override default values with individual
                        # widget specification
                        set config_value $options($config_key)
                        unset options($config_key)
                    } else {
                        set config_value [lindex $config_pair 1]
                    }
                    ns_log debug "tinymce: key $config_key value $config_value"
                    if  {$config_value eq "true" || $config_value eq "false"} {
                        lappend pairslist "${config_key}:${config_value}"
                    } else {
                        lappend pairslist "${config_key}:\"${config_value}\""
                    }
                }

                foreach name [array names options] {
                    ns_log debug "tinymce: NAME $name"
                    # add any additional options not specified in the
                    # default config
                    lappend pairslist "${name}:\"$options($name)\""
                }

                lappend pairslist "elements : \"[join $::acs_blank_master__htmlareas ","]\""
                set tinymce_configs_js [join $pairslist ","]
                set ::acs_blank_master(tinymce.config) $tinymce_configs_js
            }

            append output "</span></label>\n<script type='text/javascript'>document.write(\"<input name='$element(id).format' value='text/html' type='hidden'>\");</script>\n"
            append output "<noscript><div><label for=\"$element(id).format\"><span class=\"form-widget\">[_ acs-templating.Format]: $format_menu</span></label></div></noscript>"

            if { $spellcheck(render_p) } {
                append output "<label for=\"$element(id).spellcheck\"><span class=\"form-widget\">[_  acs-templating.Spellcheck]: " \
                    [menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] \
                         $spellcheck(selected_option) {}]
            }

        } else {
            # htmlarea_p is false

            append output "</span></label>\n<label for=\"$element(id).format\"><span class=\"form-widget\">[_ acs-templating.Format]: $format_menu"

            if { $spellcheck(render_p) } {
                append output "</span></label>\n<label for=\"$element(id).spellcheck\"><span class=\"form-widget\">[_  acs-templating.Spellcheck]: " \
                    [menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] \
                         $spellcheck(selected_option) {}]
            }

        }

    } else {
        # Display mode
        if { $element(mode) eq "display" && [info exists element(value)] } {
            append output [template::util::richtext::get_property html_value $element(value)]
            append output "<input type=\"hidden\" name=\"$element(id)\" value=\"[ad_quotehtml $contents]\">"
            append output "<input type=\"hidden\" name=\"$element(id).format\" value=\"[ad_quotehtml $format]\">"
        }
    }
    
    return $output
}

ad_proc template::data::to_sql::richtext { value } {

    Handle richtext transformations using a standardized naming convention.

} {
    return "'[DoubleApos [list [template::util::richtext::get_property content $value] \
                               [template::util::richtext::get_property format $value]]]'"
}

