ad_library {

    Contains procedures specific to AOLserver 3 (mostly recreating
   functionality dropped from AOLserver 2).  

    @creation-date 27 Feb 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id $Id$
}

# -1 = Not there or value was ""
#  0 = NULL, set value to NULL.
#  1 = Got value, set value to it.

proc ns_dbformvalue {formdata column type valuebyref} {

    upvar $valuebyref value

    if {[ns_set get $formdata $column.NULL] == "t"} {
	set value ""
	return 0
    }

    set value [ns_set get $formdata $column]

    if { [string match $value ""] } {
        switch -- $type {
	    
	    date      {
		set value [ns_buildsqldate \
			[ns_set get $formdata $column.month] \
			[ns_set get $formdata $column.day] \
			[ns_set get $formdata $column.year]]
	    }
	    
	    time      {
		set value [ns_buildsqltime \
			[ns_set get $formdata $column.time] \
			[ns_set get $formdata $column.ampm]]
	    }
	    
            datetime  -
	    timestamp {
		set value [ns_buildsqltimestamp \
			[ns_set get $formdata $column.month] \
			[ns_set get $formdata $column.day] \
			[ns_set get $formdata $column.year] \
			[ns_set get $formdata $column.time] \
			[ns_set get $formdata $column.ampm]]
	    }
	    
	    default {
	    }
	}
    }
    if { [string match $value ""] } {
	return -1
    } else {
	return 1
    }
}

proc ns_dbformvalueput {htmlform column type value} {

    switch -- $type {

	date {
	    set retval [ns_formvalueput $htmlform $column.NULL f]
	    set retval [ns_formvalueput $retval $column.month \
		    [ns_parsesqldate month $value]]
	    set retval [ns_formvalueput $retval $column.day \
		    [ns_parsesqldate day $value]]
	    set retval [ns_formvalueput $retval $column.year \
		    [ns_parsesqldate year $value]]
	}

	time {
	    set retval [ns_formvalueput $htmlform $column.NULL f]
	    set retval [ns_formvalueput $retval $column.time \
		    [ns_parsesqltime time $value]]
	    set retval [ns_formvalueput $retval $column.ampm \
		    [ns_parsesqltime ampm $value]]

	}

        datetime  -
	timestamp {
	    set retval [ns_formvalueput $htmlform $column.NULL f]
	    set retval [ns_formvalueput $retval $column.month \
		    [ns_parsesqltimestamp month $value]]
	    set retval [ns_formvalueput $retval $column.day \
		    [ns_parsesqltimestamp day $value]]
	    set retval [ns_formvalueput $retval $column.year \
		    [ns_parsesqltimestamp year $value]]
	    set retval [ns_formvalueput $retval $column.time \
		    [ns_parsesqltimestamp time $value]]
	    set retval [ns_formvalueput $retval $column.ampm \
		    [ns_parsesqltimestamp ampm $value]]
	    
	}

	default {

	    set retval [ns_formvalueput $htmlform $column $value]
	}
    }
    return $retval
}

proc _ns_updatebutton {table var} {
    upvar $var updatebutton

    if { ![info exists updatebutton] } {
	set updatebutton ""
    }
    if { "" eq $updatebutton } {
	db_with_handle db {
	    set updatebutton [ns_table value $db $table update_button_label]
	}
    }
    if { "" eq $updatebutton } {
	set updatebutton "Update Record"
    }
}

proc _http_read {timeout sock length} {

    return [_ns_http_read $timeout $sock $length]

} ;# _http_read

# Tcl page support

proc ns_putscript {conn ignored} {
	ns_returnbadrequest $conn "Cannot PUT a script file"
}

# _ns_dateentrywidget is not very popular and is not
# internationalized. We keep it for backward compatibility. It should
# become deprecated.
proc _ns_dateentrywidget {column} {

    set NS(months) [list January February March April May June \
                        July August September October November December]

    set output "<select name='$column.month'>\n"
    for {set i 0} {$i < 12} {incr i} {
        append output "<option> [lindex $NS(months) $i]\n"
    }

    append output \
        "</select>&nbsp;<INPUT name='$column.day'\
type='text' size='3' maxlength='2'>&nbsp;<input name='$column.year'\
type='text' size='5' maxlength='4'>"

    return [ns_dbformvalueput $output $column date [lindex [split [ns_localsqltimestamp] " "] 0]]
}

proc _ns_timeentrywidget {column} {
    
    set output "<INPUT NAME='$column.time' type='text' size='9'>&nbsp;<select name='$column.ampm'>\
<option> AM\
<option> PM\
</select>"

    return [ns_dbformvalueput $output $column time [lindex [split [ns_localsqltimestamp] " "] 1]]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
