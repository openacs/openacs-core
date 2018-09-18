ad_library {
    UI widgets for use in forms, etc.

    @cvs-id $Id$
}

ad_proc us_state_widget {
    {default ""}
    {select_name "usps_abbrev"}
} {
    Returns a state selection box.
    This widget depends on the ref-us-states package.
} {
    set widget_value "<select name=\"$select_name\">\n"
    if { $default eq "" } {
        append widget_value "<option value=\"\" selected=\"selected\">Choose a State</option>\n"
    }

    db_foreach all_states {
        select state_name, abbrev from states order by state_name
    } {
        if { $default == $abbrev } {
            append widget_value "<option value=\"$abbrev\" selected=\"selected\">$state_name</option>\n"
        } else {
            append widget_value "<option value=\"$abbrev\">$state_name</option>\n"
        }
    }
    append widget_value "</select>\n"
    return $widget_value
}

ad_proc country_widget {
    {default ""}
    {select_name "country_code"}
    {size_subtag "size='4'"}
} {
    Returns a country selection box.
    This widget depends on the ref-countries package.
} {
    set widget_value "<select name=\"$select_name\" $size_subtag>\n"
    if { $default eq "" } {
        if { [parameter::get -parameter SomeAmericanReadersP -package_id [ad_conn subsite_id] -default 0] } {
            append widget_value "<option value=\"\">Choose a Country</option>
            <option value=\"us\" selected=\"selected\">United States</option>\n"
        } else {
            append widget_value "<option value=\"\" selected=\"selected\">Choose a Country</option>\n"
        }
    }
    db_foreach all_countries {
        select default_name, iso from countries order by default_name
    } {
        if { $default == $iso } {
            append widget_value "<option value=\"$iso\" selected=\"selected\">$default_name</option>\n"
        } else {
            append widget_value "<option value=\"$iso\">$default_name</option>\n"
        }
    }
    append widget_value "</select>\n"
    return $widget_value
}

# teadams - It is usually more appropriate to use html_select_options or
# html_select_value_options.

ad_proc ad_generic_optionlist {
    items
    values
    {default ""}
} {
    Use this to build select form fragments.  Given a list of items and a list of values,
    will return the option tags with default highlighted as appropriate.
} {

    # items is a list of the items you would like the user to select from
    # values is a list of corresponding option values
    # default is the value of the item to be selected
    set count 0
    set return_string ""
    foreach value $values {
        if {  $default eq $value  } {
            append return_string "<option selected=\"selected\" value=\"$value\">[lindex $items $count]</option>\n"
        } else {
            append return_string "<option value=\"$value\">[lindex $items $count]</option>\n"
        }
        incr count
    }
    return $return_string
}

# use ad_integer_optionlist instead of day_list
proc day_list {} {
    return  {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31}
}

ad_proc month_list {} {
    Returns list of month abbreviations
} {
    return  {Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}
}

ad_proc long_month_list {} {
    Returns list of months
} {
    return  {January February March April May June July August September October November December}
}

# use ad_integer_optionlist instead of month_value_list
proc month_value_list {} {
    return {1 2 3 4 5 6 7 8 9 10 11 12}
}

ad_proc future_years_list {
    {num_year 10}
} {
    Returns a list containing the next num_year years in the future.
} {
    set year [ns_fmttime [ns_time] %Y]
    set counter  0
    while {$counter < $num_year } {
        incr counter
        lappend year_list $year
        incr year
    }
    return $year_list
}

# produces the optionlist for a range of integers

# if pad_to_two_p is 1, the option values will be
# padded to 2 digits with a leading 0

ad_proc ad_integer_optionlist {
    start_value
    end_value
    {default ""}
    { pad_to_two_p 0}
} {
    Produces an optionlist for a range of integers from start_value to end_value.
    If default matches one of the options, it is selected. If pad_to_two_p is 1,
    the option values will be padded to 2 digits with a leading 0.
} {
    # items is a list of the items you would like the user to select from
    # values is a list of corresponding option values
    # default is the value of the item to be selected
    set count 0
    set return_string ""


    for { set x $start_value } { $x <= $end_value } { incr x } {

        if { $pad_to_two_p && $x >= 0 && $x < 10 } {
            set value "0$x"
        } else {
            set value $x
        }

        if { $default == $value } {
            append return_string "<option selected=\"selected\" value=\"$value\">$value</option>\n"
        } else {
            append return_string "<option value=\"$value\">$value</option>\n"
        }
    }
    return $return_string
}

ad_proc ad_dateentrywidget {column { value 0 } } {
    Returns form pieces for a date entry widget. A null date may be selected.
} {
    # if you would like the default to be null, call with value= ""

    set NS(months) [list January February March April May June \
        July August September October November December]

    if { $value == 0 } {
        # no default, so use today
        set value  [lindex [split [ns_localsqltimestamp] " "] 0]
    }

    if { $value eq "" } {
        set month ""
        set day ""
        set year ""
    } else {
        lassign [split $value "-"] year month day
        # trim the day, in case we get as well a time stamp
        regexp {^([0-9]+) } $day _ day
    }

    set output "<select name=\"$column.month\">\n"

    # take care of cases like 09 for month
    regsub "^0" $month "" month
    for {set i 0} {$i < 12} {incr i} {
        if { $month ne "" && $i == $month - 1 } {
            append output "<option selected=\"selected\">[lindex $NS(months) $i]</option>\n"
        } else {
            append output "<option>[lindex $NS(months) $i]</option>\n"
        }
    }

    append output [subst {</select><input name="$column.day" type="text" size="2" maxlength="2" value="$day">&nbsp;
                          <input name="$column.year" type="text" size="4" maxlength="4" value="$year">}]

    return $output
}

ad_proc ad_db_select_widget {
    {-size 0}
    {-multiple 0}
    {-default {}}
    {-option_list {}}
    {-blank_if_no_db 0}
    {-hidden_if_one_db 0}
    {-bind {}}
    statement_name
    sql_qry
    name
} {
    given a sql query this generates a select group.  If there is only
    one value it returns the text and a hidden variable setting that value.
    The first selected column should contain the optionlist items. The
    second selected column should contain the optionlist values.
    <p>
    option_list is a list in the same format (i.e. {{str val} {str2 val2}...})
    which is prepended to the list
    <p>
    if sql_qry is null then the list is constructed from option_list only.
    <p>
    if there is only one item the select is not generated and the value
    is passed in hidden form variable.
    <p>
    if -multiple is given then a multi select is returned.
    <p>
    if -blank_if_no_db is true, then do not return a select widget unless
    there are rows from the database
} {
    set retval {}
    set count 0
    set dbcount 0
    if {$option_list ne ""} {
        foreach opt $option_list {
            incr count
            lassign $opt value item
            if { (!$multiple && $value eq $default )
                 || ($multiple && $value in $default)
            } {
                append retval "<option selected value=\"$value\">$item</option>\n"
            } else {
                append retval "<option value=\"$value\">$item</option>\n"
            }
        }
    }

    if { $blank_if_no_db} {
        set count 0
    }

    if {$sql_qry ne ""} {
        set columns [ns_set create]

        db_foreach $statement_name $sql_qry -column_set selection -bind $bind {
            incr count
            incr dbcount
            set item [ns_set value $selection 0]
            set value [ns_set value $selection 1]
            if { (!$multiple && $value eq $default )
                 || ($multiple && $value in $default)
            } {
                append retval "<option selected=\"selected\" value=\"$value\">$item</option>\n"
            } else {
                append retval "<option value=\"$value\">$item</option>\n"
            }
        } if_no_rows {
            if {$default ne ""} {
                return "<input type=\"hidden\" value=\"[ns_quotehtml $default]\" name=\"$name\">\n"
            } else {
                return {}
            }
        }
    }

    if { $count == 1 || ($dbcount == 1 && $hidden_if_one_db) } {
        return "$item<input type=\"hidden\" value=\"[ns_quotehtml $value]\" name=\"$name\">\n"
    } elseif {!$count && !$dbcount && $blank_if_no_db} {
        return {}
    } else {
        set select "<select name=\"$name\""
        if {$size != 0} {
            append select " size=\"$size\""
        }
        if {$multiple} {
            append select " multiple"
        }
        return "$select>\n$retval</select>"
    }
}

ad_proc ad_html_colors {} "Returns an array of HTML colors and names." {
    return {
        { Black 0 0 0 }
        { Silver 192 192 192 }
        { Gray 128 128 128 }
        { White 255 255 255 }
        { Maroon 128 0 0 }
        { Red 255 0 0 }
        { Purple 128 0 128 }
        { Fuchsia 255 0 255 }
        { Green 0 128 0 }
        { Lime 0 255 0 }
        { Olive 128 128 0 }
        { Yellow 255 255 0 }
        { Navy 0 0 128 }
        { Blue 0 0 255 }
        { Teal 0 128 128 }
        { Aqua 0 255 255 }
    }
}

ad_proc ad_color_widget_js {} "Returns JavaScript code necessary to use color widgets." {
    return {

        var adHexTupletValues = '0123456789ABCDEF';

        function adHexTuplet(val) {
            return adHexTupletValues.charAt(Math.floor(val / 16)) + adHexTupletValues.charAt(Math.floor(val % 16));
        }

        function adUpdateColorText(field) {
            var form = document.forms[0];
            var element = form[field + ".list"];
            var rgb = element.options[element.selectedIndex].value;
            var r,g,b;
            if (rgb == "" || rgb == "none" || rgb == "custom") {
                r = g = b = "";
            } else {
                var components = rgb.split(",");
                r = components[0];
                g = components[1];
                b = components[2];
            }
            form[field + ".c1"].value = r;
            form[field + ".c2"].value = g;
            form[field + ".c3"].value = b;

            document['color_' + field].src = '/shared/1pixel.tcl?r=' + r + '&g=' + g + '&b=' + b;
        }

        function adUpdateColorList(field) {
            var form = document.forms[0];
            var element = form[field + ".list"];

            var c1 = form[field + ".c1"].value;
            var c2 = form[field + ".c2"].value;
            var c3 = form[field + ".c3"].value;
            if (c1 != parseInt(c1) || c2 != parseInt(c2) || c3 != parseInt(c3) ||
            c1 < 0 || c2 < 0 || c3 < 0 || c1 > 255 || c2 > 255 || c3 > 255) {
                element.selectedIndex = 1;
                document['color_' + field].src = '/shared/1pixel.tcl?r=255&g=255&b=255';
                return;
            }

            document['color_' + field].src = '/shared/1pixel.tcl?r=' + c1 + '&g=' + c2 + '&b=' + c3;

            var rgb = parseInt(form[field + ".c1"].value) + "," + parseInt(form[field + ".c2"].value) + "," + parseInt(form[field + ".c3"].value);
            var found = 0;
            for (var i = 0; i < element.length; ++i)
            if (element.options[i].value == rgb) {
                element.selectedIndex = i;
                found = 1;
                break;
            }
            if (!found)
            element.selectedIndex = 0;
        }

    }
}

ad_proc ad_color_widget {
    name
    default
    { use_js 0 }
} {
    Returns a color selection widget, optionally using JavaScript. Default is a string of the form '0,192,255'.
} {
    set out {<table cellspacing="0" cellpadding="0"><tr><td>}
    append out [subst {<select name="$name.list"}]
    if { $use_js != 0 } {
        set id [clock clicks -microseconds]
        append out [subst { id="select-$id"}]
        template::add_event_listener \
            -id select-$id -event change \
            -script [subst {adUpdateColorText('$name');}]
    }
    append out ">\n"

    set items [list "custom:" "none"]
    set values [list "custom" ""]

    foreach color [ad_html_colors] {
        lappend items [lindex $color 0]
        lappend values "[lindex $color 1],[lindex $color 2],[lindex $color 3]"
    }

    append out "[ad_generic_optionlist $items $values $default]</select>\n"

    if { ![regexp {^([0-9]+),([0-9]+),([0-9]+)$} $default all c1 c2 c3] } {
        set c1 ""
        set c2 ""
        set c3 ""
    }

    foreach component { c1 c2 c3 } {
        append out [subst { <input name="$name.$component" size="3" value="[set $component]"}]
        if { $use_js } {
            append out [subst { id="input-$component-$id"}]
            template::add_event_listener \
                -id input-$component-$id -event change \
                -script [subst {adUpdateColorList('$name');}]
        }
        append out ">"
    }

    if { $use_js == 1 } {
        if { $c1 eq "" } {
            set c1 255
            set c2 255
            set c3 255
        }
        append out [subst {</td><td>&nbsp;
                           <img name="color_$name" src="/shared/1pixel.tcl?r=$c1&g=$c2&b=$c3" width="26" height="26" style="border:1">
        }]
    }
    append out "</td></tr></table>\n"
    return $out
}

ad_proc ad_process_color_widgets args {
    Sets variables corresponding to the color widgets named in $args.
} {
    foreach field $args {
        upvar $field var
        set var [ns_queryget "$field.list"]
        if { $var eq "custom" } {
            set var "[ns_queryget "$field.c1"],[ns_queryget "$field.c2"],[ns_queryget "$field.c3"]"
        }
        if { ![regexp {^([0-9]+),([0-9]+),([0-9]+)$} $var "" r g b] || $r > 255 || $g > 255 || $b > 255 } {
            set var ""
        }
    }
}

ad_proc ad_color_to_hex { triplet } {
    Converts a string of the form 0,192,255 to a string of the form #00C0FF.
} {
    if { [regexp {^([0-9]+),([0-9]+),([0-9]+)$} $triplet all r g b] } {
        return "#[format "%02x%02x%02x" $r $g $b]"
    } else {
        return ""
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
