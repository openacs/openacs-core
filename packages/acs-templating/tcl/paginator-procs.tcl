# Query paginator for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)

# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

namespace eval template {}
namespace eval template::paginator {}

ad_proc -public template::paginator { command args } {
    pagination object.  Please see the individual command for
    their arguments.

    @see template::paginator 
    @see template::paginator::create 
    @see template::paginator::get_context 
    @see template::paginator::get_data
    @see template::paginator::get_query 
    @see template::paginator::get_display_info 
    @see template::paginator::get_group 
    @see template::paginator::get_group_count 
    @see template::paginator::get_groups 
    @see template::paginator::get_page 
    @see template::paginator::get_page_count 
    @see template::paginator::get_pages 
    @see template::paginator::get_pages_info
    @see template::paginator::get_row 
    @see template::paginator::get_row_count 
    @see template::paginator::get_row_ids 
    @see template::paginator::get_row_last
    @see template::paginator::reset
} {
  paginator::$command {*}$args
}

ad_proc -public template::paginator::create { statement_name name query args } {
    Creates a paginator object.  Performs an initial query to get the complete
    list of rows in the query result and caches the result for subsequent
    queries.

    @param statement_name A query name.  This is overwritten by the contents of
                        the "query" parameter if it is not the empty string.

    @param name         A unique name corresponding to the query being 
                        paginated, including specific values in the where 
                        clause and sorting specified in the order by clause.

    @param query        The actual query that returns the IDs of all rows in
                        the results.  Bind variables may be used.

    @option timeout     The lifetime of a query result in seconds, after which
                        the query must be refreshed (if not reset).

    @option pagesize    The number of rows to display on a single page.

    @option groupsize   The number of pages in a group, for UI purposes.  This
                        is useful for result sets which span several pages.  For
                        example, if you have 1000 results at 10 results per page,
                        that will leave you with 100 pages and you may not want
                        to display 1-100 in the UI.  In this case, setting a
                        groupsize of 10 will allow you to display pages 1-10, then
                        11-20, and so on.  The default groupsize is 10.

    @option contextual  Boolean indicating whether the pagination interface
                        presented to the user will provide
                        some other contextual clue in addition or instead of
                        page number, such as the first few
                        letters of a title or date.  By default, the second
                        column in the result set returned by query will be used
                        as the context.

    @option page_offset The first page in a set of page groups to be created by
                        this paginator.  This can be used to slice very large sets of
                        page groups into paginators, cached separately (be sure to
                        name each page group's paginator uniquely if you're caching
                        pagination query results).  Very useful since filling the cache
                        for an entire set of page groups can be very costly, and since
                        often only the first few pages of items (for instance, forum threads)
                        are visited through the pagination interface.  The list builder
                        provides an example of how to do this.
} {
  set level [template::adp_level]
  variable parse_level
  set parse_level $level

  # maintain paginator properties in stack frame of current template
  upvar #$level pq:$name:properties opts 

  variable defaults
  array set opts $defaults
  template::util::get_opts $args

  set cache_key	$name:$query
  set row_ids [cache get $cache_key:row_ids]

    #
    # GN: In the following line, we had instead of [::cache exists
    # $cache_key] the commdand [nsv_exists __template_cache_timeout
    # $cache_key] It is not clear, what the intended semantic was, and
    # why not the API working on the nsv was used. See as well
    # below. In general, using a test for a cache entry and a code
    # depening on the cached entry is NOT AN GOOD idea, since the
    # operations are not atomic. Between the check and the later code,
    # the cache entry might be deleted.  refactoring of this code is
    # recommended. Unfortunately, several places in OpenACS have this
    # problem.
    #
    if { ($row_ids eq {} && ![::cache exists $cache_key]) || ([info exists opts(flush_p)] && $opts(flush_p) == "t") } {
      if { [info exists opts(printing_prefs)] && $opts(printing_prefs) ne "" } {
	  set title [lindex $opts(printing_prefs) 0]
	  set stylesheet [lindex $opts(printing_prefs) 1]
	  if { $stylesheet ne "" } {
	      set css_link "<link rel=\"stylesheet\" href=\"$stylesheet\" type=\"text/css\">"
	  } else {
	      set css_link ""
	  }
	  set background [lindex $opts(printing_prefs) 2]
	  if { $background ne "" } {
	      set bg "background=\"$background\""
	  } else {
	      set bg ""
	  }

	  ad_return_top_of_page [subst {
<html>
<head>
<title>$title</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
$css_link
</head>
<body $bg>
	  }]
	  set header_file [lindex $opts(printing_prefs) 3]
	  if { $header_file ne "" } {
	      ns_write [ns_adp_parse -file $header_file]
	  }
	  ns_write [lindex $opts(printing_prefs) 6]
	  init $statement_name $name $query 1
	  ns_write [lindex $opts(printing_prefs) 7]
	  set footer_file [lindex $opts(printing_prefs) 4]
	  if { $footer_file ne "" } {
	      ns_write [ns_adp_parse -file $footer_file]
	  }
	  set return_url [lindex $opts(printing_prefs) 5]
	  if { $return_url ne "" } {
	      # Not sure, what the intented semantics of this command was...
	      #if { [llength $opts(row_ids)]==0 } {
	      #	  nsv_set __template_cache_timeout $cache_key $opts(timeout)
	      #}
	      ns_write "
          <SCRIPT type=\"text/javascript\">
          <!-- Begin
          document.location.href=\"$return_url\";
          // End -->
          </script>
          <noscript>
          <a href=\"$return_url\">Click here to Continue</a>
          </noscript>"
	  }
	  ad_script_abort
      } else {
	  init $statement_name $name $query
      }
  } else {
    set opts(row_ids) $row_ids
    set opts(context_ids) [cache get $cache_key:context_ids]
  }

  set opts(row_count) [llength $opts(row_ids)]
  set opts(page_count) [expr {[get_page $name $opts(row_count)] + $opts(page_offset)}]
  set opts(group_count) [get_group $name $opts(page_count)]
}

ad_proc -private template::paginator::init { statement_name name query {print_p 0} } {
    Initialize a paginated query.  Only called by create.
} {
  get_reference

  # query for an ordered list of all row identifiers to cache
  # perform the query in the calling scope so bind variables have effect

  upvar 2 __paginator_ids ids
  set ids [list]

  if { [info exists properties(contextual)] } {

      # query contains two columns, one for ID and one for context cue

      uplevel 2 "
      set full_statement_name \[db_qd_get_fullname $statement_name\]

      # Can't use db_foreach here, since we need to use the ns_set directly.
      db_with_handle db {
	set selection \[db_exec select \$db \$full_statement_name {$query}\]
 
        set __paginator_ids \[list\]
        set total_so_far 1

	while { \[db_getrow \$db \$selection\] } {
	    set this_result \[list\]
	    for { set i 0 } { \$i < \[ns_set size \$selection\] } { incr i } {
                lappend this_result \[ns_set value \$selection \$i\]
	    }
            if { $print_p } {
               if { \$total_so_far % 250 == 0 } {
                   ns_write \"&#133;\$total_so_far \"
               }
               if { \$total_so_far % 3000 == 0 } {
                   ns_write \"<br>\"
               }
            }
            incr total_so_far
	    lappend __paginator_ids \$this_result
	}

        if { $print_p } {
           ns_write \"&#133;\[expr \$total_so_far - 1\]\"
        }

      }
      "

      set i 0
      set page_size $properties(pagesize)
      set context_ids [list]
      set row_ids ""

      foreach row $ids {

          lappend row_ids [lindex $row 0]

          if { $i % $page_size == 0 } {
              lappend context_ids [lindex $row 1]
          }
          incr i
      }

      set properties(context_ids) $context_ids
      cache set $name:$query:context_ids $context_ids $properties(timeout)

      set properties(row_ids) $row_ids

      cache set $name:$query:row_ids $row_ids $properties(timeout)

  } else {

      uplevel 2 "
      # Can't use db_foreach here, since we need to use the ns_set directly.
      db_with_handle db {
	set selection \[db_exec select \$db $statement_name \"$query\"\]

        set __paginator_ids \[list\]
        set total_so_far 1

	while { \[db_getrow \$db \$selection\] } {
	    set this_result \[list\]
	    for { set i 0 } { \$i < \[ns_set size \$selection\] } { incr i } {
                lappend this_result \[ns_set value \$selection \$i\]
	    }
            if { $print_p } {
               if { \$total_so_far % 250 == 0 } {
                   ns_write \"...\$total_so_far \"
               }
               if { \$total_so_far % 3000 == 0 } {
                   ns_write \"<br>\"
               }
            }
            incr total_so_far
	    lappend __paginator_ids \$this_result
	}
        if { $print_p } {
           ns_write \"...\[expr \$total_so_far - 1\]\"
        }
      }
      "

      set properties(row_ids) $ids
      cache set $name:$query:row_ids $ids $properties(timeout)
  }
}

ad_proc -public template::paginator::get_page { name rownum } {
    Calculates the page on which the specified row is located.

    @param name   The reference to the paginator object.
    @param rownum A number ranging from one to the number of rows in the
                  query result, representing the number of a row therein.

    @return A number ranging from one to the number of pages in 
            the query result, representing the number of the page
            the specified row is located in.
} {
  get_reference

  set pagesize $properties(pagesize)

  return [expr ($rownum - 1 - (($rownum - 1) % $pagesize)) / $pagesize + 1]
}

ad_proc -public template::paginator::get_row { name pagenum } {
    Calculates the first row displayed on a page.

    @param name    The reference to the paginator object.
    @param pagenum A number ranging from one to the number of pages in 
                   the query result, representing the number of a page
                   therein.

    @return A number ranging from one to the number of rows in 
            the query result, representing the number of the first
            row on the specified page.
} {
  get_reference

  return [expr ($pagenum - 1) * $properties(pagesize) + 1]
}

ad_proc -public template::paginator::get_row_last { name pagenum } {
    Calculates the last row displayed on a page.

    @param name    The reference to the paginator object.
    @param pagenum A number ranging from one to the number of pages in 
                   the query result, representing the number of a page
                   therein.

    @return A number ranging from one to the number of rows in 
            the query result, representing the number of the last
            row on the specified page.
} {
  get_reference

  set page_count $properties(page_count)

  if {$page_count == $pagenum} {
    return $properties(row_count)
  } else {
    return [expr {$pagenum * $properties(pagesize)}]
  }
}

ad_proc -public template::paginator::get_group { name pagenum } {
    Calculates the page group in which the specified page is located.

    @param name    The reference to the paginator object.
    @param pagenum A number ranging from one to the number of pages in 
                   the query result.

    @return A number ranging from one to the number of groups in the query 
            result, as determined by both the page size and the group size.
            This number represents the page group number that the specified
            page lies in.
} {
  get_reference

  set groupsize $properties(groupsize)

  return [expr ($pagenum - 1 - (($pagenum - 1) % $groupsize)) / $groupsize + 1]
}

ad_proc -public template::paginator::get_row_ids { name pagenum } {
    Gets a list of IDs in a page, selected from the master ID list
    generated by the initial query submitted for pagination.  IDs are
    typically primary key values.

    @param name    The reference to the paginator object.
    @param pagenum A number ranging from one to the number of pages in 
                   the query result.

    @return A Tcl list of row identifiers.
} {
  get_reference

  set pagesize $properties(pagesize)
  set page_offset $properties(page_offset)

  # get the set of ids for the current page
  set start [expr ($pagenum - $page_offset - 1) * $pagesize]
  set end [expr {$start + $pagesize - 1}]
  set ids [lrange $properties(row_ids) $start $end]

  return $ids
}

ad_proc -public template::paginator::get_all_row_ids { name  } {
    Gets a list of IDs in the master ID list
    generated by the initial query submitted for pagination.  IDs are
    typically primary key values.

    @param name    The reference to the paginator object.

    @return A Tcl list of row identifiers.
} {
  get_reference
  return $properties(row_ids)
}

ad_proc -public template::paginator::get_pages { name group } {
    Gets a list of pages in a group, truncating if appropriate at the end.

    @param name    The reference to the paginator object.
    @param group   A number ranging from one to the number of page groups in 
                   the query result.

    @return A Tcl list of page numbers.
} {
  get_reference

  set group_count $properties(group_count)
  set group_size $properties(groupsize)
  set page_count $properties(page_count)

  if { $group > $group_count } {
    if { $group_count == 0 } {
      return ""
    }
    error "Group out of bounds ($group > $group_count)"
  }

  set start [expr ($group - 1) * $group_size + 1]
  set end [expr {$start + $group_size - 1}]

    if { $end > $page_count } { set end $page_count }

  set pages [list]

  for { set i $start } { $i <= $end } { incr i } {
    lappend pages $i
  }

  return $pages
}

ad_proc -public template::paginator::get_groups { name group count } {
    Determines the set of groups to which a group belongs, and calculates the
    starting page of each group in that set.

    @param name    The reference to the paginator object.
    @param group   A number ranging from one to the number of page groups in 
                   the query result.
    @param count   The desired size of the group set.

    @return A Tcl list of page numbers.
} {
  get_reference

  set group_count $properties(group_count)
  set page_count $properties(page_count)
  set group_size $properties(groupsize)
  set page_size $properties(pagesize)

  if { $group > $group_count } {
    if { $group_count == 0 } {
      return ""
    }
    error "Group out of bounds ($group > $group_count)"
  }

  set first [expr ($group - 1 - (($group - 1) % $count)) / $count + 1]

  set start [expr ($first - 1) * $group_size + 1]
  set end [expr {$start + $group_size * $page_size - 1}]

  if { $end > $page_count } { set end $page_count) }

  set pages [list]

  for { set i $start } { $i <= $end } { incr i $group_size } {
    lappend pages $i
  }

  return $pages
}

ad_proc -public template::paginator::get_context { name datasource pages } {
    Gets the context cues for a set of pages in the form of a multirow
    data source with 3 columns: rownum (starting with 1); page (number
    of the page); and context (a short string such as the first few
    letters of a name or title).  The context cues may be used in the
    paging interface along with or instead of page numbers.  This
    command is only valid if the contextual option is specified when
    creating the paginator.

    @param name        The reference to the paginator object.
    @param datasource  The name of the multirow datasource to create
    @param pages       A Tcl list of page numbers.
} {
  get_reference

  if { ! [info exists properties(context_ids)] } {
    error "Invalid command (contextual option not specified)"
  }

  set context_ids $properties(context_ids)

  upvar 2 $datasource:rowcount rowcount 
  set rowcount 0

  upvar 2 $datasource:columns columns
  set columns { page context }

  foreach page $pages {

    incr rowcount
    upvar 2 $datasource:$rowcount row

    set row(rownum) $rowcount
    set row(page) $page
    set row(context) [lindex $context_ids $page-1]
  }
}

# DEDS: we can get away without this, but i'm throwing it in anyway
#       as it makes life easier for non-contextual pagination
ad_proc -public template::paginator::get_pages_info { name datasource pages } {
    Gets the page information for a set of pages in the form of a multirow
    data source with 2 columns: rownum (starting with 1); and page (number
    of the page).  This is a counterpart for get_context when using page
    objects that are non-contextual.  Using this makes it easier to switch
    from contextual to non-contextual so that less modification is needed
    on adp template pages.  Think in terms of taking out the display of
    one element in a multirow datasource as compared to converting an adp
    to handle a list datasource instead of a multirow datasource.

    @param name        The reference to the paginator object.
    @param datasource  The name of the multirow datasource to create
    @param pages       A Tcl list of page numbers.
} {
  get_reference

  upvar 2 $datasource:rowcount rowcount 
  set rowcount 0

  upvar 2 $datasource:columns columns
  set columns { page }

  foreach page $pages {

    incr rowcount
    upvar 2 $datasource:$rowcount row

    set row(rownum) $rowcount
    set row(page) $page
  }
}

ad_proc -public template::paginator::get_row_count { name } {
    Gets the total number of records in the paginated query

    @param name    The reference to the paginator object.

    @return A number representing the row count.
} {
  get_reference

  return $properties(row_count)
}

ad_proc -public template::paginator::get_page_count { name } {
    Gets the total number of pages in the paginated query

    @param name    The reference to the paginator object.

    @return A number representing the page count.
} {
  get_reference

  return $properties(page_count)
}

ad_proc -public template::paginator::get_group_count { name } {
    Gets the total number of groups in the paginated query

    @param name    The reference to the paginator object.

    @return A number represeting the group count.
} {
  get_reference

  return $properties(group_count)
}

ad_proc -public template::paginator::get_display_info { name datasource page } {
    Make paginator display properties available as a onerow data source:

    <table>
    <tr>
      <td>next_page:</td>
                 <td>following page or empty string if at end</td>
    </tr>
    <tr>
      <td>previous_page:</td>
                 <td>preceeding page or empty string if at beginning</td>
    </tr>
    <tr>
      <td>next_group:</td>
                 <td>page that begins the next page group or empty string if 
                     at end</td>
    </tr>
    <tr>
      <td>previous_group:</td>
                 <td>page that begins the last page group or 
               	     empty string if at endl.</td>
    </tr>
    <tr>
      <td>page_count:</td>
                 <td>the number of pages</td>
    </tr>
    </table>
   
    @param name        The reference to the paginator object.
    @param datasource  The name of the onerow datasource to create
    @param page        A page number representing the reference point from
                       which the display properties are calculated.
} {
  get_reference
  upvar 2 $datasource info

  if { $page > $properties(page_count) } {
    set page $properties(page_count)
  }

  set group [get_group $name $page]
  set groupsize $properties(groupsize)

  set info(page_count) $properties(page_count)
  set info(group_count) $properties(group_count)
  set info(current_page) $page
  set info(current_group) $group
  set info(groupsize) $groupsize

  array set info {
    next_page {} 
    previous_page {}
    next_group {} 
    previous_group {}
    next_page_context {} 
    previous_page_context {}
    next_group_context {} 
    previous_group_context {}
  }

  if { $page > 1 } { 
    set info(previous_page) [expr {$page - 1}] 
  }

  if { $page < $properties(page_count) } { 
    set info(next_page) [expr {$page + 1}] 
  }


  if { $group > 1 && $groupsize > 1 } {
    set info(previous_group) [expr ($group - 2) * $groupsize + 1]
  }

  if { $group < $properties(group_count) && $groupsize > 1 } {
    set info(next_group) [expr {$group * $groupsize + 1}]
  }

  # If the paginator is contextual, set the context
  if { [info exists properties(context_ids)] } {
    foreach elm { next_page previous_page next_group previous_group } {
      if { ([info exists info($elm)] && $info($elm) ne "") } {
        set info(${elm}_context) [lindex $properties(context_ids) $info($elm)-1]
      }
    }
  }
}

ad_proc -public template::paginator::get_data { statement_name name datasource query id_column page } {
    Sets a multirow data source with data for the rows on the current page.
    The pseudocolumn "all_rownum" is added to each row, indicating the
    index of the row relative to all rows across all pages.

    @param name       The reference to the paginator object.
    @param datasource The name of the datasource to create.
    @param query      The query to execute, containing IN (CURRENT_PAGE_SET).
    @param id_column  The name of the ID column in the display query (required
                      to order rows properly).
} {
  set ids [get_row_ids $name $page]

  # calculate the base row number for the page
  upvar 2 __page_firstrow firstrow
  set firstrow [get_row $name $page]

  # build a hash of row order to order the rows on the page 
  upvar 2 __page_order row_order
  template::util::list_to_lookup $ids row_order

  # substitute the current page set
  if { $query eq "" } {
    set query [uplevel 2 "db_map ${statement_name}_partial"]
  }

  # DEDS: quote the ids so that we are not
  #       necessarily limited to integer keys
  set quoted_ids [list]
  foreach one_id $ids {
      lappend quoted_ids "'[DoubleApos $one_id]'"
  }
  set in_list [join $quoted_ids ","]
  if { ! [regsub CURRENT_PAGE_SET $query $in_list query] } {
    error "Token CURRENT_PAGE_SET not found in page data query  ${statement_name}_partial: $query"
  }

  if { [llength $in_list] == 0 } {
    uplevel 2 "set $datasource:rowcount 0"
    return
  }



  # execute the query such that the unsorted data source is created in the
  # current stack frame.  Generate a multirow data source in the calling
  # stack frame as we go, using the order lookup created above to ensure
  # that the rows are properly sorted.  Do it in the calling stack frame
  # so that bind variables may be used.
  uplevel 2 "
    
    set __page_cnt 0
    db_foreach $statement_name \"$query\" -column_array row {
      incr __page_cnt
      set i \$__page_order(\$row($id_column))
      upvar 0 $datasource:\$i __page_sorted_row
      array set __page_sorted_row \[array get row\]
      set __page_sorted_row(rownum) \[expr \$i + \$__page_firstrow - 1\]
    }

    set $datasource:rowcount \${__page_cnt}
  "

#   uplevel 2 "

#     db_multirow __page_data $statement_name \"$query\" {
#       set i \$__page_order(\$row($id_column))
#       upvar 0 $datasource:\$i __page_sorted_row
#       array set __page_sorted_row \[array get row\]
#       set __page_sorted_row(rownum) \[expr \$i + \$__page_firstrow - 1\]
#     }

#     set $datasource:rowcount \${__page_data:rowcount}
#   "

}

ad_proc -public template::paginator::get_query { name id_column page } {
    Returns a query with the data for the rows on the current page.

    @param name       The reference to the paginator object.
    @param query      The query to execute, containing IN (CURRENT_PAGE_SET).
    @param id_column  The name of the ID column in the display query (required
                      to order rows properly).
} {
    set ids [get_row_ids $name $page]

    if { $ids ne "" } {
	# calculate the base row number for the page
	upvar 2 __page_firstrow firstrow
	set firstrow [get_row $name $page]
	
	# build a hash of row order to order the rows on the page 
	upvar 2 __page_order row_order
	template::util::list_to_lookup $ids row_order
	
	set query "CURRENT_PAGE_SET"
	
	# DEDS: quote the ids so that we are not
	#       necessarily limited to integer keys
	set quoted_ids [list]
	foreach one_id $ids {
	    lappend quoted_ids "'[DoubleApos $one_id]'"
	}
	set in_list [join $quoted_ids ","]
	if { ! [regsub CURRENT_PAGE_SET $query $in_list query] } {
	    error "Token CURRENT_PAGE_SET not found."
	}
	
	if { [llength $in_list] == 0 } {
	    uplevel 2 "set $datasource:rowcount 0"
	    return
	}

	# Return the query with CURRENT_PAGE_SET slugged
	return $query
    } else {
	return "null"
    }
}

ad_proc -public template::paginator::reset { name query } {
    Resets the cache for a query.
} {
    cache flush $name:$query:context_ids
    cache flush $name:$query:row_ids
}

ad_proc -private template::paginator::get_reference {} {
    Get a reference to the paginator properties (internal helper)
} {
  uplevel {

    variable parse_level
    set level $parse_level

    upvar #$level pq:$name:properties properties
    if { ! [array exists properties] } {
      error "Paginator does not exist"
    }
  }
}

