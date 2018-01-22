ad_library {

    Provides a collection of deprecated procs to provide backward
    compatibility for sites who have not yet removed calls to the
    dprecated functions.

    In order to skip loading of deprecated code, use the following
    snippet in your config file

        ns_section ns/server/${server}/acs
            ns_param WithDeprecatedCode 0
    
    @cvs-id $Id$
}

if {![ad_with_deprecated_code_p]} {
    ns_log notice "deprecated-procs: skip deprecated code"
    return
}
ns_log notice "deprecated-procs include depreacted code"

namespace eval template {}
namespace eval template::util {}

ad_proc -public -deprecated template::util::get_cookie { name {default_value ""} } {
    Retrieve the value of a cookie and return it
    Return the default if no such cookie exists

    @see ad_get_cookie
} {
    set headers [ns_conn headers]
    set cookie [ns_set iget $headers Cookie]

    if { [regexp "$name=(\[^;\]+)" $cookie match value] } {
	return [ns_urldecode $value]
    }

    return $default_value
}

ad_proc -public -deprecated template::util::set_cookie { expire_state name value { domain "" } } {
    Create a cookie with specified parameters.  The expiration state
    may be persistent, session, or a number of minutes from the current
    time.

    @see ad_set_cookie
} {

    if { [string match $domain {}] } {
	set path "ns/server/[ns_info server]/module/nssock"
	set domain [ns_config $path Hostname]
    }

    set cookie "$name=[ns_urlencode $value]; path=/; domain=$domain"

    switch -- $expire_state {

	persistent {
	    append cookie ";expires=Wed, 01-Jan-2020 01:00:00 GMT"
	}

	"" -
	session {
	}

	default {

	    set time [expr {[ns_time] + ($expire_state * 60)}]
	    append cookie ";expires=[ns_httptime $time]"
	}
    }

    ns_set put [ns_conn outputheaders] "Set-Cookie" $cookie
}

ad_proc -public -deprecated template::util::clear_cookie { name { domain "" } } {
    Expires an existing cookie.

    @see ad_get_cookie

} {
    if { [string match $domain {}] } {
	set path "ns/server/[ns_info server]/module/nssock"
	set domain [ns_config $path Hostname]
    }

    set cookie "$name=expired; path=/; domain=$domain;"
    append cookie "expires=Tue, 01-Jan-1980 01:00:00 GMT"

    ns_set put [ns_conn outputheaders] "Set-Cookie" $cookie
}

ad_proc -deprecated -public template::util::quote_html {
    html
} {
    Quote possible HTML tags in the contents of the html parameter.
} {

    return [ns_quotehtml $html]
}


ad_proc -deprecated -public template::util::multirow_foreach { name code_text } {
    runs a block of code foreach row in a multirow.

    Using "template::multirow foreach" is recommended over this routine.

    @param name the name of the multirow over which the block of
    code is iterated

    @param code_text the block of code in the for loop; this block can
    reference any of the columns belonging to the
    multirow specified; with the multirow named
    "fake_multirow" containing columns named "spanky"
    and "foobar",to set the column spanky to the value
    of column foobar use:<br>
    <code>set fake_multirow.spanky @fake_multirow.foobar@</code>
    <p>
    note: this block of code is evaluated in the same
    scope as the .tcl page that uses this procedure

    @author simon

    @see template::multirow
} {

    upvar $name:rowcount rowcount $name:columns columns i i
    upvar running_code running_code

    for { set i 1} {$i <= $rowcount} {incr i} {

	set running_code $code_text
	foreach column_name $columns {

	    # first change all references to a column to the proper
	    # rownum-dependent identifier, ie the array value identified
	    # by $<multirow_name>:<rownum>(<column_name>)
	    regsub -all "($name).($column_name)" $running_code "$name:${i}($column_name)" running_code
	}

	regsub -all {@([a-zA-Z0-9_:\(\)]+)@} $running_code {${\1}} running_code

	uplevel {
	    eval $running_code
	}

    }

}

ad_proc -deprecated -public template::util::get_param {
    name
    {section ""}
    {key ""}
} {
    Retrieve a stored parameter, or "" if no such parameter
    If section/key are present, read the parameter from the specified
    section.key in the INI file, and cache them under the given name
} {

    if { ![nsv_exists __template_config $name] } {

	# Extract the parameter from the ini file if possible
	if { $section ne "" } {

	    # Use the name if no key is specified
	    if { $key ne "" } {
		set key $name
	    }

	    set value [ns_config $section $key ""]
	    if {$value eq ""} {
		return ""
	    } else {
		# Cache the value and return it
		template::util::set_param $name $value
		return $value
	    }

	} else {
	    # No such parameter found and no key/section specified
	    return ""
	}
    } else {
	return [nsv_get __template_config $name]
    }
}

ad_proc -public -deprecated  template::util::set_param { name value } {
    Set a stored parameter
} {
    nsv_set __template_config $name $value
}

ad_proc -deprecated template::get_resource_path {} {
    Get the template directory
    The body is doublequoted, so it is interpreted when this file is read
    @see template::resource_path
} "
  return \"[file dirname [file dirname [info script]]]/resources\"
"
