ad_page_contract {
    Index page for developer support.

    @author  jsalz@mit.edu
    @creation-date        22 June 2000
    @cvs-id $Id$
} {
    {request_limit:integer 25}
}

ds_require_permission [ad_conn package_id] "admin"

set enabled_p                [ds_enabled_p]
set user_switching_enabled_p [ds_user_switching_enabled_p]
set database_enabled_p       [ds_database_enabled_p]
set profiling_enabled_p      [ds_profiling_enabled_p]
set adp_reveal_enabled_p     [ds_adp_reveal_enabled_p]

set package_id [ad_conn package_id]

set page_title "Developer Support"
set context {}

append body "
<ul>
<li><a href=\"shell.tcl\">OpenACS Shell</a>
<li>Developer support toolbar is currently
[ad_decode $enabled_p 1 \
     "on (<a href=\"set?field=ds&amp;enabled_p=0\">turn it off</a>)" \
     "off (<a href=\"set?field=ds&amp;enabled_p=1\">turn it on</a>)"]

<li>Developer support information is currently
restricted to the following IP addresses:
<ul>
"

set enabled_ips [nsv_get ds_properties enabled_ips]
set includes_this_ip_p 0
if { [llength $enabled_ips] == 0 } {
    append body "<li><i>(none)</i>\n"
} else {
    foreach ip $enabled_ips {
	if { [string match $ip [ad_conn peeraddr]] } {
	    set includes_this_ip_p 1
	}
	if { [regexp {[\*\?\[\]]} $ip] } {
	    append body "<li>IPs matching the pattern \"<code>$ip</code>\"\n"
	} else {
	    append body "<li>$ip\n"
	}
    }
}
if { !$includes_this_ip_p } {
    append body "<li><a href='[ns_quotehtml add-ip?ip=[ad_conn peeraddr]'>add your IP, [ad_conn peeraddr]</a>\n"
}

set requests [nsv_array names ds_request]

set parameterHref [export_vars -base /shared/parameters { package_id { return_url {[ad_return_url]} } }]
append body "
</ul>

<li>Information is being swept every [parameter::get -parameter DataSweepInterval -default 900] sec
and has a lifetime of [parameter::get -parameter DataLifetime -default 900] sec

<li><a href='[ns_quotehtml $parameterHref]'>Set package parameters</a>

<p>

<li>User-switching is currently
[ad_decode $user_switching_enabled_p 1 \
     "on (<a href=\"set?field=user&amp;enabled_p=0\">turn it off</a>)" \
     "off (<a href=\"set?field=user&amp;enabled_p=1\">turn it on</a>)"]

<li>Database statistics is currently
[ad_decode $database_enabled_p 1 \
     "on (<a href=\"set?field=db&amp;enabled_p=0\">turn it off</a>)" \
     "off (<a href=\"set?field=db&amp;enabled_p=1\">turn it on</a>)"]

<li>Template profiling is currently
[ad_decode $profiling_enabled_p 1 \
     "on (<a href=\"set?field=prof&amp;enabled_p=0\">turn it off</a>)" \
     "off (<a href=\"set?field=prof&amp;enabled_p=1\">turn it on</a>)"]

<li>ADP reveal is currently
[ad_decode $adp_reveal_enabled_p 1 \
     "on (<a href=\"set?field=adp&amp;enabled_p=0\">turn it off</a>)" \
     "off (<a href=\"set?field=adp&amp;enabled_p=1\">turn it on</a>)"]

<p>
<li> Help on <a href='doc/editlocal'>edit and code links</a>.
</ul>

<h3>Available Request Information</h3>
<blockquote>
"

if { [llength $requests] == 0 } {
    append body "There is no request information available."
} else {
    append body [subst {
<table cellspacing="0" cellpadding="0">
<tr style="background:#AAAAAA">
<th>Time</th>
<th>Duration</th>
<th>IP</th>
<th>Request</th>
</tr>
    }]

    set colors {white #EEEEEE}
    set counter 0
    set show_more 0
    foreach request [lsort -decreasing -dictionary $requests] {
	if { [regexp {^([0-9]+)\.conn$} $request "" id] } {
	    if { $request_limit > 0 && $counter > $request_limit } {
		incr show_more
		continue
	    }

	    if { [info exists conn] } {
		unset conn
	    }
	    array set conn [nsv_get ds_request $request]
	    if { [catch {
		set start [ns_fmttime [lindex [nsv_get ds_request "$id.start"] 0] "%T"]
	    }] } {
		set start "?"
	    }

	    if { [info exists conn(startclicks)] && [info exists conn(endclicks)] } {
		set duration "[expr { ($conn(endclicks) - $conn(startclicks)) / 1000.0 }] ms"
	    } else {
		set duration ""
	    }

	    if { [info exists conn(peeraddr)] } {
		set peeraddr $conn(peeraddr)
	    } else {
		set peeraddr ""
	    }

	    if { [info exists conn(method)] } {
		set method $conn(method)
	    } else {
		set method "?"
	    }

	    if { [info exists conn(url)] } {
		if { [string length $conn(url)] > 50 } {
		    set url "[string range $conn(url) 0 46]..."
		} else {
		    set url $conn(url)
		}
	    } else {
		set conn(url) ""
                set url {}
	    }

	    if { [info exists conn(query)] && $conn(query) ne "" } {
		if { [string length $conn(query)] > 50 } {
		    set query "?[string range $conn(query) 0 46]..."
		} else {
		    set query "?$conn(query)"
		}
	    } else {
		set query ""
	    }
            if {[ns_cache get ds_page_bits $id:error dummy]} {
                set elink [subst { <a href="send?output=$id:error" style="color: red">Errors</span></a>}]
            } else { 
                set elink {}
            }
	    append body [subst {
<tr style="background:[lindex $colors [expr { $counter % [llength $colors] }]]">
<td align=center>&nbsp;$start&nbsp;</td>
<td align=right>&nbsp;$duration&nbsp;</td>
<td>&nbsp;$peeraddr&nbsp;</td>
		<td><a href="request-info?request=[ns_quotehtml $id]">[ns_quotehtml "$method $url$query"]</a>$elink</td>
</tr>
	    }]
            incr counter
        }
    }
    if { $show_more > 0 } {
	append body [subst {
	    <tr><td colspan="4" align="right"><a href="index?request_limit=0">
	    <i>show $show_more more requests</i></td>
	    </tr>
	}]
    }

    append body "</table>\n"
}

append body "</blockquote>"

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
