# Query paginator for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)

# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ad_proc -public template::paginator { command args } {
    pagination object.  Please see the individual command for
    their arguments.

    @see template::paginator 
    @see template::paginator::create 
    @see template::paginator::get_context 
    @see template::paginator::get_data 
    @see template::paginator::get_display_info 
    @see template::paginator::get_group 
    @see template::paginator::get_group_count 
    @see template::paginator::get_groups 
    @see template::paginator::get_page 
    @see template::paginator::get_page_count 
    @see template::paginator::get_pages 
    @see template::paginator::get_row 
    @see template::paginator::get_row_count 
    @see template::paginator::get_row_ids 
} {
  eval paginator::$command $args
}

ad_proc -public template::paginator::create { statement_name name query args } {
    Creates a paginator object.  Performs an initial query to get the complete
    list of rows in the query result and caches the result for subsequent
    queries.

    @param name         A unique name corresponding to the query being 
                        paginated, including specific values in the where 
                        clause and sorting specified in the order by clause.

    @param query        The actual query that returns the IDs of all rows in
                        the results.  Bind variables may be used.

    @option timeout     The lifetime of a query result in seconds, after which
                        the query must be refreshed.

    @option pagesize    The number of rows to display on a single page.

    @option groupsize   The number of pages in a group, for UI purposes.

    @option contextual  Boolean indicating whether the pagination interface
                        presented to the user will provide
                        some other contextual clue in addition or instead of
                        page number,, such as the first few
                        letters of a title or date.
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

  if { [string equal $row_ids {}] } {
    init $statement_name $name $query
  } else {
    set opts(row_ids) $row_ids
    set opts(context_ids) [cache get $cache_key:context_ids]
  }

  set opts(row_count) [llength $opts(row_ids)]
  set opts(page_count) [get_page $name $opts(row_count)]
  set opts(group_count) [get_group $name $opts(page_count)]
}

ad_proc -private template::paginator::init { statement_name name query } {
    Initialize a paginated query.  Only called by create.
} {
  get_reference

  # query for an ordered list of all row identifiers to cache
  # perform the query in the calling scope so bind variables have effect

  upvar 3 __paginator_ids ids

  if { [info exists properties(contextual)] } {

      # query contains two columns, one for ID and one for context cue
      uplevel 3 "set __paginator_ids \[db_list_of_lists $statement_name \"$query\"\]"

      set i 0
      set page_size $properties(pagesize)
      set context_ids [list]
      
      foreach row $ids {

          lappend row_ids [lindex $row 0]

          if { [expr $i % $page_size] == 0 } {
              lappend context_ids [lindex $row 1]
          }
          incr i
      }
      
      set properties(context_ids) $context_ids
      cache set $name:$query:context_ids $context_ids $properties(timeout)


      if { [template::util::is_nil row_ids] } {
          set row_ids ""
      }

      set properties(row_ids) $row_ids
      cache set $name:$query:row_ids $row_ids $properties(timeout)


  } else {

      # no extra column specified for paging by contextual cues
      uplevel 3 "set __paginator_ids [db_list $statement_name  \"$query\"]"

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

  # get the set of ids for the current page
  set start [expr ($pagenum - 1) * $pagesize]
  set end [expr $start + $pagesize - 1]
  set ids [lrange $properties(row_ids) $start $end]

  return $ids
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
  set end [expr $start + $group_size]

  if { $end > $page_count } { set end $page_count }

  set pages [list]

  for { set i $start } { $i < $end } { incr i } {
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
  set end [expr $start + $group_size * $page_size - 1]

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

  foreach page $pages {

    incr rowcount
    upvar 2 $datasource:$rowcount row

    set row(rownum) $rowcount
    set row(page) $page
    set row(context) [lindex $context_ids [expr $page - 1]]
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

  return $properties(row_count)
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

  set info(page_count) $properties(page_count)

  array set info [list next_page {} previous_page {} \
      next_group {} previous_group {}]

  if { $page > 1 } { 
    set info(previous_page) [expr $page - 1] 
  }

  if { $page < $properties(page_count) } { 
    set info(next_page) [expr $page + 1] 
  }

  set group [get_group $name $page]
  set groupsize $properties(groupsize)

  if { $group > 1 } {
    set info(previous_group) [expr ($group - 2) * $groupsize + 1]
  }

  if { $group < $properties(group_count) } {
    set info(next_group) [expr $group * $groupsize + 1]
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
  set query [uplevel 2 "db_map ${statement_name}_partial"]
  set in_list [join $ids ","]
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

