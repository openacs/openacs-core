ad_page_contract {

    @author rhs@mit.edu
    @author bquinn@arsidigta.com
    @creation-date 2000-09-09
    @cvs-id $Id$

} {
    {expand:integer,multiple ""}
    {new_parent:integer ""}
    {new_type ""}
    {root_id:integer ""}
    {new_application:integer ""}
    {rename_application:integer {}}
}

if {[empty_string_p $root_id]} {
    set root_id [ad_conn node_id]
}

# We do a check for the admin privilege because a user could have
# admin privilege on a site_node that has other site_nodes beneath it
# that the user does not have admin privilege on.  If we don't do this
# check, the user could end up making changes on site_nodes that he
# does not have the admin privilege for.

array set node [site_node::get -node_id $root_id]
set parent_id $node(parent_id)
set object_id $node(object_id)

if {![empty_string_p $object_id]} {
    ad_require_permission $object_id admin
}

if {![empty_string_p $new_parent]} {
    set javascript "onLoad=\"javascript:document.new_parent.name.focus();document.new_parent.name.select()\""
} elseif {![empty_string_p $new_application]} {
    set javascript "onLoad=\"javascript:document.new_application.instance_name.focus();document.new_application.instance_name.select()\""
} elseif {![empty_string_p $rename_application]} {
    set javascript "onLoad=\"javascript:document.rename_application.instance_name.focus();document.rename_application.instance_name.select()\""
} else {
    set javascript ""
}

set parent_link ".?[export_url_vars expand:multiple root_id=$parent_id]"

doc_body_append "<html>
<head><title>Site Map</title></head>
<body bgcolor=#ffffff link=#0000ff vlink=#000ff $javascript>

<h2>Site Map</h2>

[ad_context_bar "Site Map"]
<hr>

<p>
<b>&raquo;</b> <a href=\"application-new\">Create new application</a>
</p>


<table cellspacing=0 cellpadding=2 border=0>
<tr>
<td><font face=courier><b>"

set user_id [ad_conn user_id]

db_foreach path_select {} {
    if {$node_id != $root_id && $admin_p == "t"} {
	doc_body_append "<a href=.?[export_url_vars expand:multiple root_id=$node_id]>"
    }
    if {[empty_string_p $name]} {
	doc_body_append "$obj_name:"
    } else {
	doc_body_append $name
    }

    if {$node_id != $root_id && $admin_p == "t"} {
	doc_body_append "</a>"
    }

    if {$directory_p == "t"} {
	doc_body_append "/"
    }
} if_no_rows {
    doc_body_append "&nbsp;"
}

doc_body_append "</b></font>
    </td>
  </tr>
  <tr bgcolor=#aaaaaa>
    <td>
<table align=center width=100% bgcolor=#eeeeee cellspacing=1 border=0>
  <tr bgcolor=#cccccc>
    <th>URL</th>
    <th>Instance Name</th>
    <th>Package Type</th>
    <th>&nbsp;</th>
  </tr>
"

if {[llength $expand] == 0} {
    lappend expand $root_id 
    if { ![empty_string_p $parent_id] } {
        lappend expand $parent_id
    }
}

# You might wonder why level is aliased as mylevel here.  Well, for some
# reason, Oracle does not allow level to be selected from an on-the-fly view
# containing connect by.  However, if you rename the column, Oracle is happy to give
# it to you.  We could tell you how we figured this out, but then we would have to kill you.
set open_nodes [list]
db_foreach nodes_select {} {
    if { [lsearch -exact $open_nodes $parent_id] == -1 && $parent_id != "" && $mylevel > 2 } { continue } 

    # set up commands to put in the various columns
    set controls [list]
    set dir_controls [list]  
    set name_controls [list]  

    if {$directory_p == "t"} {
	lappend controls "<a href=.?[export_url_vars expand:multiple root_id node_id new_parent=$node_id new_type=folder]>add folder</a>"
	if {[empty_string_p $object_id]} {
	    lappend controls "<a href=mount?[export_url_vars expand:multiple root_id node_id]>mount</a>"
	    lappend controls "<a href=.?[export_url_vars expand:multiple root_id new_application=$node_id]>new application</a>"
	} else {
	    # This makes sure you can't unmount the thing that is serving
	    # the page you're looking at.
	    if {[ad_conn node_id] != $node_id} {
		lappend controls "<a href=unmount?[export_url_vars expand:multiple root_id node_id]>unmount</a>"
	    }
	    
	    # Is the object a package?
	    if {![empty_string_p $package_id]} {
		if {$object_admin_p && ($parameter_count > 0)} {
		    lappend controls "<a href=\"[export_vars -base "/shared/parameters" { package_id {return_url {[ad_return_url]} } }]\">parameters</a>"
		}
	    }
	    
	    # Add a link to control permissioning
	    if {$object_admin_p} {
		lappend controls "<a href=\"../../permissions/one?[export_url_vars object_id]\">permissions</a>"
		lappend controls "<a href=\"?[export_url_vars expand:multiple root_id rename_application=$node_id]\">rename</a>"
		lappend controls "<a href=\"instance-delete?package_id=$object_id&root_id=$root_id\" onclick=\"return confirm('Are you sure you want to delete node $name and any package mounted there?');\">delete</a>"
	    }
	}
    }
    
  if {[ad_conn node_id] != $node_id && $n_children == 0 && [empty_string_p $object_id]} {
    lappend controls "<a href=delete?[export_url_vars expand:multiple root_id node_id]>delete</a>"
  }

    doc_body_append "<tr><td><nobr><font face=courier size=-1>"

    # use the indent variable to hold current indent level
    # we'll use it later to indent stuff at the end by the amount
    # of the last node
    set indent ""
    for {set i 0} {$i < 3*$mylevel} {incr i} {
	append indent "&nbsp;"
    }
        doc_body_append $indent

    if {!$root_p && $n_children > 0} {
	set link "+"
	set urlvars [list]
	foreach n $expand {
	    if {$n == $node_id} {
		set link "-"
		lappend open_nodes "$node_id"
	    } else {
		lappend urlvars "expand=$n"
	    }
	}

	if {[string equal $link "+"]} {
	    lappend urlvars "expand=$node_id"
	}

	lappend urlvars "root_id=$root_id"

	doc_body_append "(<a href=.?[join $urlvars "&"]>$link</a>)</font> "
    } else {
	doc_body_append "&nbsp;&nbsp;&nbsp;</font> "
    }

    doc_body_append "<font face=courier><b>"
    if {!$root_p && $root_id != $node_id} {
	doc_body_append "<a href=.?[export_url_vars expand:multiple root_id=$node_id]>"
    }
    doc_body_append "$name"
    if {!$root_p && $root_id != $node_id} {
	doc_body_append "</a>"
    }

    doc_body_append [ad_decode $directory_p t / f ""]

    doc_body_append "</b></font></nobr><font size=-1> [join $dir_controls " | "] </font></td>"



  doc_body_append "<td>"

  if {[empty_string_p $object_id]} {
    if {$new_application == $node_id} {
	#Generate a package_id for double click protection
	set new_package_id [db_nextval acs_object_id_seq]
      doc_body_append "<form name=new_application action=package-new>
        [export_form_vars expand:multiple root_id node_id new_package_id]
        <font size=-1>
        <input name=instance_name type=text size=8 value=\"\">
        </td><td>
        [apm_application_new_checkbox]
        </td>
        <td>
        <input type=submit value=New>
        </font>
      </form>
      "
    } else {
      doc_body_append "(none)"
    }
  } elseif {$rename_application == $node_id} {
      doc_body_append "<form name=rename_application action=rename>
        [export_form_vars expand:multiple root_id node_id rename_package_id]
        <font size=-1>
        <input name=instance_name type=text size=\"[string length $object_name]\" value=\"$object_name\">
        <input type=submit value=Rename>
        </font>
        </form>
      "
  } else {
      doc_body_append "<a href=\"$url\">[lang::util::localize $object_name]</a>"
  }

  if {![empty_string_p $object_id] || $new_application != $node_id } {
      doc_body_append "</td><td>$package_pretty_name</td><td><font size=-1>\[ [join $controls " | "] \]</font></td>"
  } 
  doc_body_append "</tr>\n"

  if {$node_id == $new_parent} {
    set parent_id $new_parent
    set node_type $new_type
    doc_body_append "<tr><td><form name=new_parent action=new><nobr><font face=courier size=-1>"
    for {set i 0} {$i < (3*($mylevel + 1) + 3)} {incr i} {
      doc_body_append "&nbsp;"
    }
    # Generate a node_id for doubleclick protection.
    doc_body_append "
        [export_form_vars expand:multiple parent_id node_type root_id]
        <b><input name=name type=text size=8 value=Untitled>
        <input type=submit value=New></b>
      </font></nobr>
      </form>
    </td>
    <td>&nbsp;</td>
    <td>&nbsp;</td>\n</tr>"
  }
}

doc_body_append "
  </tr>
  <tr>
<form name=new_application action=package-new>
  <input type=hidden name=node_id value=$node(node_id) />
  <input type=hidden name=root_id value=$node(node_id) />
  <input type=hidden name=new_node_p value=t />
  [export_form_vars expand:multiple]
  <td>$indent<input name=node_name type=text size=8>
  </td>
  <td colspan=\"2\">
    [apm_application_new_checkbox]
  </td>
  <td>
    <input type=submit value=\"Mount Package\">
  </td>
</form>

    </tr>
</table>
</table>

          </ul>
    </tr>
    <tr>
"

doc_body_append "
<p>
<a href=\"unmounted\">Manage unmounted applications</a>
</p>

<h2>Set Parameters</h2>
       <ul>
"


db_foreach services_select {} {
    if {$parameter_count > 0} {
        if {[ad_permission_p $package_id admin]} {		
	    doc_body_append "  <li><a href=\"[export_vars -base "/shared/parameters" { package_id { return_url {[ad_return_url]} } }]\">$instance_name</a>"
	}
    }
    doc_body_append "\n"
} if_no_rows {
  doc_body_append "  <li>(none)\n"
}


doc_body_append "
</ul>
"

doc_body_append "<p />
<center><strong>Site Map Instructions</strong></center><p /> 

To <strong>add an application</strong> to this site, use <em>new sub
folder</em> to create a new site node beneath under the selected
folder.  Then choose <em>new application</em> to select an installed
application package for instantiation.  The application will then be
available at the displayed URL.<p />

To <strong>configure</strong> an application select <em>set
parameters</em> to view and edit application specific options.
<em>set permissions</em> allows one to grant privileges to users and
groups to specific application instances or other application data.
For more info on parameters and permissions, see the package specific
documentation.  <p />

To <strong>copy</strong> an application instance to another URL,
create a new folder as above, then select <em>mount</em>.  Select
the application to be copied from the list of available packages.<p />

To <strong>move</strong> an application,
copy it as above to the new location, then select
<em>unmount</em> at the old location.  Selecting <em>delete</em> on
the empty folder will remove it from the site node.<p />

To <strong>remove</strong> an application and all of its data, select
<em>unmount</em> from all the site nodes it is mounted from, then
<em>delete</em> it from the <em>Unmounted Applications</em> link below
the site map.

</font>


[ad_footer]
"
