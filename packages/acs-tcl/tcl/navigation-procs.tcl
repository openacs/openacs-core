ad_library {

    Provides procedures to spit out the navigational parts of the site.

    @cvs-id $Id$
    @author philg@mit.edu
    @creation-date 11/5/98 (adapted originally from the Cognet server)     
    edited February 28, 1999 by philg to include support for a 
    Yahoo-style navigation system (showing users where they are in a
    hierarchy)

}


ad_proc ad_context_bar { args } {

    Returns a Yahoo-style hierarchical navbar. Includes "Your Workspace" or "Administration"
    if applicable, and the subsite if not global.

} {

  set context [list]

  if {[ad_conn user_id] != 0 && ![string match /pvt/home* [ad_conn url]]} {
      lappend context [list "[ad_pvt_home]" "[ad_pvt_home_name]"]
  }

  set node_id [ad_conn node_id]
  db_foreach context {
    select site_node.url(node_id) as url, object_id,
           acs_object.name(object_id) as object_name,
           level
    from site_nodes
    start with node_id = :node_id
    connect by prior parent_id = node_id
    order by level asc
  } {
      lappend context [list $url $object_name]
  }

  if { [string match admin/* [ad_conn extra_url]] } {
    lappend context [list "[ad_conn package_url]admin/" \
	"Administration"]
  }

  set context [concat $context $args]

  set out [list]

  for { set i 0 } { $i < [llength $context] } { incr i } {
    set element [lindex $context $i]
    if { $i == [llength $context] - 1 } {
      if {[llength $args] == 0} {
	lappend out [lindex $element 1]
      } else {
	lappend out $element
      }
    } else {
      lappend out "<a href=\"[lindex $element 0]\">[lindex $element 1]</a>"
    }
  }

  return [join $out " : "]
}

# a context bar, rooted at the workspace

proc_doc ad_context_bar_ws args {
    Returns a Yahoo-style hierarchical navbar, starting with a link to workspace.
} {
    set choices [list "[ad_pvt_home_link]"]


    set index 0
    foreach arg $args {
	incr index
	if { $index == [llength $args] } {
	    lappend choices $arg
	} else {
	    lappend choices "<a href=\"[lindex $arg 0]\">[lindex $arg 1]</a>"
	}
    }
    return [join $choices " : "]
}

# a context bar, rooted at the workspace or index, depending on whether
# user is logged in

proc_doc ad_context_bar_ws_or_index args {
    Returns a Yahoo-style hierarchical navbar, starting with a link to
    either the workspace or /, depending on whether or not the user is
    logged in.  
} {
    if { [ad_get_user_id] == 0 } {
	set choices [list "<a href=\"/\">[ad_system_name]</a>"] 
    } else {
	set choices [list "[ad_pvt_home_link]"]
    }

# lars, Apr25-00: Took out this old scoping thing
#
#    if { [ad_conn scope on_which_table] != "." } {
#	if { [llength $args] == 0 } {
#	    lappend choices [ad_conn scope name]
#	} else {
#	    lappend choices "<a href=\"[ad_conn scope url]/\">[ad_conn scope name]</a>"
#	}
#    }

    set index 0
    foreach arg $args {
	incr index
	if { $index == [llength $args] } {
	    lappend choices $arg
	} else {
	    lappend choices "<a href=\"[lindex $arg 0]\">[lindex $arg 1]</a>"
	}
    }
    return [join $choices " : "]
}

proc_doc ad_admin_context_bar args { 
    Returns a Yahoo-style hierarchical navbar, starting with links
    workspace and admin home.
    Suitable for use in pages underneath /admin.
} {
    set choices [list "[ad_pvt_home_link]" "<a href=\"/acs-admin/\">ACS System Wide Administration</a>"]
    set index 0
    foreach arg $args {
	incr index
	if { $index == [llength $args] } {
	    lappend choices $arg
	} else {
	    lappend choices "<a href=\"[lindex $arg 0]\">[lindex $arg 1]</a>"
	}
    }
    return [join $choices " : "]
}

proc_doc ad_navbar args {
    produces navigation bar. notice that navigation bar is different
    than context bar, which exploits a tree structure. navbar will just
    display a list of nicely formatted links.
} {
    set counter 0
    foreach arg $args {
	lappend link_list "<a href=\"[lindex $arg 0]\">[lindex $arg 1]</a>"
	incr counter
    }
    if { $counter > 0 } {
	return "\[[join $link_list " | "]\]"
    } else {
	return ""
    }
}

proc_doc ad_choice_bar { items links values {default ""} } {
    Displays a list of choices (Yahoo style), with the currently selected one highlighted.
} {

    set count 0
    set return_list [list]

    foreach value $values {
	if { [string compare $default $value] == 0 } {
	        lappend return_list "<strong>[lindex $items $count]</strong>"
	} else {
	        lappend return_list "<a href=\"[lindex $links $count]\">[lindex $items $count]</a>"
	}

	incr count
    }

    if { [llength $return_list] > 0 } {
        return "\[[join $return_list " | "]\]"
    } else {
	return ""
    }
    
}


# directories that should not receive links to move up one level

proc ad_no_uplevel_patterns {} {
    set regexp_patterns [list]
    lappend regexp_patterns "/pvt/home.tcl"
    # tcl files in the root directory
    lappend regexp_patterns "^/\[^/\]*\.tcl\$"
    lappend regexp_patterns "/admin*"
}


# determines if java_script should be enabled
    
proc java_script_capabilities {} {
    set user_agent ""
    set version 0
    set internet_explorer_p 0
    set netscape_p 0
	
    # get the version
    set user_agent [ns_set get [ad_conn headers] User-Agent]
    regexp -nocase "mozilla/(\[^\.\ \]*)" $user_agent match version

    # IE browsers have MSIE and Mozilla in their user-agent header
    set internet_explorer_p [regexp -nocase "msie" $user_agent match]

    # Netscape browser just have Mozilla in their user-agent header
    if {$internet_explorer_p == 0} {
	set netscape_p [regexp -nocase "mozilla" $user_agent match]
    }
   
    set java_script_p 0
 
    if { ($netscape_p && ($version >= 3)) || ($internet_explorer_p && ($version >= 4)) } {
	set java_script_p 1
    }

    return $java_script_p
}

# netscape3 browser has a different output

proc netscape3_browser {} {
    set user_agent ""
    set version 0
    set internet_explorer_p 0
    set netscape_p 0
    
    # get the version
    set user_agent [ns_set get [ad_conn headers] User-Agent]
    regexp -nocase "mozilla/(\[^\.\ \]*)" $user_agent match version
    
    # IE browsers have MSIE and Mozilla in their user-agent header
    set internet_explorer_p [regexp -nocase "msie" $user_agent match]
    
    # Netscape browser just have Mozilla in their user-agent header
    if {$internet_explorer_p == 0} {
	set netscape_p [regexp -nocase "mozilla" $user_agent match]
    }
 
    set netscape3_p 0
 
    if { ($netscape_p && ($version == 3))} {
	set netscape3_p 1
    }

    return $netscape3_p
}



# creates the generic javascript/nonjavascript
# select box for the submenu

proc menu_submenu_select_list {items urls {highlight_url "" }} {
    set return_string ""
    set counter 0

    append return_string "<form name=submenu ACTION=/redir>
<select name=\"url\" onchange=\"go_to_url(this.options\[this.selectedIndex\].value)\">"

    foreach item $items {
	set url_stub [ad_conn url]

	# if the url matches the url you would redirect to, as determined
	# either by highlight_url, or if highlight_url is not set,
	# the current url then select it
	if {$highlight_url != "" && $highlight_url == [lindex $urls $counter]} {
 	    append return_string "<OPTION VALUE=\"[lindex $urls $counter]\" selected>$item"
	} elseif {$highlight_url == "" && [string match *$url_stub* [lindex $urls $counter]]} {
	    append return_string "<OPTION VALUE=\"[lindex $urls $counter]\" selected>$item"
	} else {
	    append return_string "<OPTION VALUE=\"[lindex $urls $counter]\">$item"
	}
	incr counter
    }
    
    append return_string "</select><br>
    <noscript><input type=\"Submit\" value=\"GO\">
    </noscript>
    </form>\n"
}


# this incorporates HTML designed by Ben (not adida, some other guy)

proc ad_menu_header {{section ""} {uplink ""}} {
    
    set section [string tolower $section]

    # if it is an excluded directory, just return
    set url_stub [ad_conn url]
    set full_filename "[ns_info pageroot]$url_stub"
   

    foreach naked_pattern [ad_naked_html_patterns] {
	if [string match $naked_pattern $url_stub] {
	    # want the global admins with no menu, but not the domain admin
	    return ""
        }
    }

    # title is the title for the title bar
    # section is the highlight for the menu

   
    set menu_items [menu_items] 
    set java_script_p [java_script_capabilities]
    
    # Ben has a different table structure for netscape 3
    set netscape3_p [netscape3_browser]
    set return_string ""

    if { $java_script_p } {
    	append return_string " 
	<script language=\"JavaScript\">
	//<!--
	
	go = new Image();
	go.src = \"/graphics/go.gif\";
	go_h = new Image();
	go_h.src = \"/graphics/go_h.gif\";
	
	up_one_level = new Image();
	up_one_level.src = \"/graphics/36_up_one_level.gif\";
	up_one_level_h = new Image();
	up_one_level_h.src = \"/graphics/36_up_one_level_h.gif\";
	
	back_to_top = new Image();
	back_to_top.src = \"/graphics/24_back_to_top.gif\";
	back_to_top_h = new Image();
	back_to_top_h.src = \"/graphics/24_back_to_top_h.gif\";

	help = new Image();
	help.src = \"/graphics/help.gif\";
	help_h = new Image();
	help_h.src = \"/graphics/help_h.gif\";

	rules = new Image();
	rules.src = \"/graphics/rules.gif\";
	rules_h = new Image();
	rules_h.src = \"/graphics/rules_h.gif\";"
	
	foreach item $menu_items {
	    if {  $item == [menu_highlight $section] } { 
		#this means the item was selected, so there are different gifs
		append return_string "
		  $item = new Image();
		  $item.src =  \"/graphics/[set item]_a.gif\";
		  [set item]_h = new Image();
		  [set item]_h.src =  \"/graphics/[set item]_ah.gif\";"
	    } else {
		append return_string "
		$item = new Image();
		$item.src =  \"/graphics/[set item].gif\";
		[set item]_h = new Image();
		[set item]_h.src =  \"/graphics/[set item]_h.gif\";"
	    }
	    
	}
 
	# javascipt enabled
	append return_string "
	
	function hiLite(imgObjName) \{
	    document \[imgObjName\].src = eval(imgObjName + \"_h\" + \".src\")
	\}

	function unhiLite(imgObjName) \{
	    document \[imgObjName\].src = eval(imgObjName + \".src\")
	\}

	function go_to_url(url) \{
		if (url \!= \"\") \{
			self.location=url;
		\}
		return;
	\}
	// -->
	</SCRIPT>"  
    } else {
	
	append return_string "

	<script language=\"JavaScript\">
	//<!--
	
	function hiLite(imgObjName) \{
	\}
		
	function unhiLite(imgObjName) \{
	\}

	function go_to_url(url) \{
	\}
	// -->
	</SCRIPT>"
    }		

    # We divide up the screen into 4 areas top to bottom:
    #  + The top table which is the cognet logo and search stuff.
    #  + The next table down is the CogNet name and area name.
    #  + The next area is either 1 large table with 2 sub-tables, or two tables (NS 3.0).
    #      The left table is the navigation table and the right one is the content.
    #  + Finally, the bottom table holds the bottom navigation bar.
    

    append return_string "[ad_body_tag]"
   
    
    if {$netscape3_p} {
	append return_string "<IMG src=\"/graphics/top_left_brand.gif\" width=124 height=87 border=0 align=left alt=\"Cognet\"> 
<TABLE border=0 cellpadding=3 cellspacing=0>"
    }  else {
	append return_string "
<TABLE border=0 cellpadding=0 cellspacing=0 height=87 width=\"100%\" cols=100>
    <TR><TD width=124 align=center><IMG src=\"/graphics/top_left_brand.gif\" width=124 height=87 border=0 alt=\"Cognet\"></TD>
        <TD colspan=99><TABLE border=0 cellpadding=3 cellspacing=0 width=\"100%\">"
    }

    append return_string "
        <TR><TD height=16></TD></TR>
        <TR valign=bottom><TD bgcolor=\"[table_background_1]\" align=left><FONT FACE=\"Arial, Helvetica, sans-serif\" size=5>Search</FONT></TD></TR>
        <TR bgcolor=\"[table_background_1]\"><TD align=left valign=center><FORM  action=\"/search-direct\" method=GET name=SearchDirect>
                <SELECT name=section>
                     [ad_generic_optionlist [pretty_search_sections] [search_sections] [menu_search_highlight $section]]     
                </SELECT>&nbsp;&nbsp;
                <INPUT type=text value=\"\" name=query_string>&nbsp;&nbsp;"

    if {$netscape3_p} {
	append return_string "<INPUT TYPE=submit VALUE=go>&nbsp;&nbsp;
             </FORM></TD></TR>
         </TABLE>"
    } else {
	append return_string "<A href=\"JavaScript: document.SearchDirect.submit();\" onMouseOver=\"hiLite('go')\" onMouseOut=\"unhiLite('go')\" alt=\"search\"><img name=\"go\" src=\"/graphics/go.gif\" border=0 width=32 height=24 align=top alt=\"go\"></A>
	</FORM></TD></TR>
         </TABLE></TD>
   </TR>
</TABLE>"
    }

    append return_string "
<TABLE bgcolor=\"#000066\" border=0 cellpadding=0 cellspacing=0 height=36 width=\"100%\">
    <TR><TD align=left><A HREF=\"/\"><IMG src=\"/graphics/cognet.gif\" width=200 height=36 align=left border=0></A><IMG SRC=\"[menu_title_gif $section]\" ALIGN=TOP WIDTH=\"222\" HEIGHT=\"36\" BORDER=\"0\" HSPACE=\"6\" alt=\"$section\"></TD>"

    set uplevel_string  "<TD align=right><A href=\"[menu_uplevel $section $uplink]\" onMouseOver=\"hiLite(\'up_one_level\')\" onMouseOut=\"unhiLite(\'up_one_level\')\"><img name=\"up_one_level\" src=\"/graphics/36_up_one_level.gif\" border=0 width=120 height=36 \" alt=\"Up\"></A></TD></TR>"

    foreach url_pattern [ad_no_uplevel_patterns] {
	if [regexp $url_pattern $url_stub match] {
	    set uplevel_string ""
	}
    }
    
    append return_string $uplevel_string 
    append return_string "</TABLE>"

    if  {$netscape3_p} {
	append return_string "<TABLE border=0 cellpadding=0 cellspacing=0 width=200 align=left>"
    } else {
	append return_string "<TABLE border=0 cellpadding=0 cellspacing=0 width=\"100%\" cols=100>
   <TR valign=top><TD width=200 bgcolor=\"[table_background_1]\">
       <TABLE border=0 cellpadding=0 cellspacing=0 width=200>"
    }

#  Navigation Table

    foreach item $menu_items {
	if {  $item == [menu_highlight $section] } { 
	    append return_string "<TR><TD valign=bottom height=25 width=200 bgcolor=\"#FFFFFF\"><A href=\"[menu_url $item]\" onMouseOver=\"hiLite('[set item]')\" onMouseOut=\"unhiLite('[set item]')\"><img name=\"[set item]\" src=\"/graphics/[set item]_a.gif\" border=0 width=200 height=25 alt=\"$item\"></A></TD></TR>"
	} else {
	    append return_string "<TR><TD valign=bottom height=25 width=200 bgcolor=\"#FFFFFF\"><A href=\"[menu_url $item]\" onMouseOver=\"hiLite('[set item]')\" onMouseOut=\"unhiLite('[set item]')\"><img name=\"[set item]\" src=\"/graphics/[set item].gif\" border=0 width=200 height=25 alt=\"$item\"></A></TD></TR>"
	}
    }

    append return_string "
       <TR bgcolor=\"[table_background_1]\" valign=top align=left><TD width=200>
           <TABLE border=0 cellpadding=4 cellspacing=0 width=200>
    <!-- NAVIGATION BAR CONTENT GOES AFTER THIS START COMMENT USING TABLE Row and Data open and close tags -->
	        [menu_subsection $section]
                <!-- NAVIGATION BAR CONTENT GOES BEFORE THIS END COMMENT -->
           </TABLE></TD></TR>
   </TABLE>"
    
   if {$netscape3_p} {
       append return_string "<TABLE border=0 cellpadding=4 cellspacing=12>"
   } else {
       append return_string "
       </TD><TD valign=top align=left colspan=99><TABLE border=0 cellpadding=4 cellspacing=12 width=\"100%\">"
   }
   append return_string "<TR><TD>"
}

proc ad_menu_footer {{section ""}} {
   
    # if it is an excluded directory, just return
    set url_stub [ad_conn url]
    set full_filename "[ns_info pageroot]$url_stub"
   
    foreach naked_pattern [ad_naked_html_patterns] {
	if [string match $naked_pattern $url_stub] {
	    return ""
	}
    }

    set netscape3_p 0
	
    if {[netscape3_browser]} {
	set netscape3_p 1
    }

    append return_string "</TD></TR></TABLE>"
    
    # close up the table
    if {$netscape3_p != 1} {
	append return_string "</TD></TR>
       </TABLE>"
    }

    # bottom bar

    append return_string "
    <TABLE border=0 cellpadding=0 cellspacing=0 height=24 width=\"100%\">
       <TR bgcolor=\"#000066\"><TD align=left valign=bottom><A href=#top onMouseOver=\"hiLite('back_to_top')\" onMouseOut=\"unhiLite('back_to_top')\"><img name=\"back_to_top\" src=\"/graphics/24_back_to_top.gif\" border=0 width=200 height=24 alt=\"top\"></A></TD>
         <TD align=right valign=bottom><A href=\"[ad_parameter GlobalURLStub "" "/global"]/rules.tcl\" onMouseOver=\"hiLite('rules')\" onMouseOut=\"unhiLite('rules')\"><img name=\"rules\" src=\"/graphics/rules.gif\" border=0 width=96 height=24 valign=bottom alt=\"rules\"></A><A href=\"[ad_help_link $section]\" onMouseOver=\"hiLite('help')\" onMouseOut=\"unhiLite('help')\"><img name=\"help\" src=\"/graphics/help.gif\" border=0 width=30 height=24 align=bottom alt=\"help\"></A></TD></TR>
    </TABLE>"
    return $return_string
}

