
#
# Query Dispatching for multi-RDBMS capability
# The OpenACS Project
#
# Ben Adida (ben@mit.edu)
#
# STATE OF THIS FILE (7/12/2001) - ben:
# This is now patched to use ns_xml 1.4 which works!
#

# The Query Dispatcher is documented at http://openacs.org/

# This doesn't use the ad_proc construct, or any significant aD constructs,
# because we want this piece to be usable in a separate context. While this makes
# the coding somewhat more complicated, it's still easy to document and write clear,
# virgin Tcl code.

# This needs ns_xml to work.

##################################
# The RDBMS Data Abstraction
##################################

proc db_rdbms_create {type version} {
    return [list $type $version]
}

proc db_rdbms_get_type {rdbms} {
    return [lindex $rdbms 0]
}

proc db_rdbms_get_version {rdbms} {
    return [lindex $rdbms 1]
}

proc db_rdbms_compatible_p {rdbms_test rdbms_pattern} {
    db_qd_log Debug "The RDBMS_TEST is [db_rdbms_get_type $rdbms_test] - [db_rdbms_get_version $rdbms_test]"
    db_qd_log Debug "The RDBMS_PATTERN is [db_rdbms_get_type $rdbms_pattern] - [db_rdbms_get_version $rdbms_pattern]"

    # If the pattern is for all RDBMS, then yeah, compatible
    if {[empty_string_p [db_rdbms_get_type $rdbms_test]]} {
	return 1
    }

    # If the RDBMS types are not the same, we have a problem
    if {[db_rdbms_get_type $rdbms_test] != [db_rdbms_get_type $rdbms_pattern]} {
	db_qd_log Debug "compatibility - RDBMS types are different!"
	return 0
    }

    # If the pattern has no version
    if {[empty_string_p [db_rdbms_get_version $rdbms_pattern]]} {
	return 1
    }

    # If the query being tested was written for a version that is older than 
	# the current RDBMS then we have compatibility. Otherwise we don't.
    if {[db_rdbms_get_version $rdbms_test] <= [db_rdbms_get_version $rdbms_pattern]} {
	return 1
    }

    db_qd_log Debug "compatibility - version numbers are bad!"
    return 0
}



##################################
# The FullQuery Data Abstraction
##################################



# The Constructor

proc db_fullquery_create {queryname querytext bind_vars_lst query_type rdbms load_location} {
    return [list $queryname $querytext $bind_vars_lst $query_type $rdbms $load_location]
}

# The Accessor procs

proc db_fullquery_get_name {fullquery} {
    return [lindex $fullquery 0]
}

proc db_fullquery_get_querytext {fullquery} {
    return [lindex $fullquery 1]
}

proc db_fullquery_get_bind_vars {fullquery} {
    return [lindex $fullquery 2]
}

proc db_fullquery_get_query_type {fullquery} {
    return [lindex $fullquery 3]
}

proc db_fullquery_get_rdbms {fullquery} {
    return [lindex $fullquery 4]
}

proc db_fullquery_get_load_location {fullquery} {
    return [lindex $fullquery 5]
}


################################################
#
# QUERY COMPATIBILITY
#
################################################

# For now, we're going to say that versions are numbers and that
# there is always backwards compatibility.
proc db_qd_pick_most_specific_query {rdbms query_1 query_2} {
    set rdbms_1 [db_fullquery_get_rdbms $query_1]
    set rdbms_2 [db_fullquery_get_rdbms $query_2]

    # We ASSUME that both queries are at least compatible.
    # Otherwise this is a stupid exercise

    if {[empty_string_p [db_rdbms_get_version $rdbms_1]]} {
	return $query_2
    }

    if {[empty_string_p [db_rdbms_get_version $rdbms_2]]} {
	return $query_1
    }

    if {[db_rdbms_get_version $rdbms_1] > [db_rdbms_get_version $rdbms_2]} {
	return $query_1
    } else {
	return $query_2
    }
}

################################################
#
#
# QUERY DISPATCHING
#
#
################################################

# A procedure that is called from the outside world (APM) 
# to load a particular file
proc db_qd_load_query_file {file_path} {
    if { [catch {db_qd_internal_load_cache $file_path} errmsg] } {
        db_qd_log Error "Error parsing queryfile $file_path:\n\n$errmsg"
    }
}

# Find the fully qualified name of the query
proc db_qd_get_fullname {local_name {added_stack_num 1}} {
    # We do a check to see if we already have a fullname.
    # Since the DB procs are a bit incestuous, this might get
    # called more than once. DAMMIT! (ben)
    if {![db_qd_relative_path_p $local_name]} {
	return $local_name
    }

    # Get the proc name being executed.
    # We catch this in case we're being called from the top level
    # (eg. from bootstrap.tcl), in which case we return what we
    # were given
    if { [catch {string trimleft [info level [expr "-1 - $added_stack_num"]] ::} proc_name] } {
	return $local_name
    }

    # If util_memoize, we have to go back up one in the stack
    if {[lindex $proc_name 0] == "util_memoize"} {
	db_qd_log Debug "util_memoize! going up one level"
	set proc_name [info level [expr "-2 - $added_stack_num"]]
    }

    set list_of_source_procs {ns_sourceproc apm_source template::adp_parse template::frm_page_handler rp_handle_tcl_request}

    # We check if we're running the special ns_ proc that tells us
    # whether this is an URL or a Tcl proc.
    if {[lsearch $list_of_source_procs [lindex $proc_name 0]] != -1} {

	# Means we are running inside an URL

	# TEST
	for {set i 0} {$i < 6} {incr i} {
	    if {[catch {db_qd_log Debug "LEVEL=$i= [info level [expr "-1 - $i"]]"} errmsg]} {}
	}

	# Check the ad_conn stuff
	if {[ns_conn isconnected]} {
	    if {[catch {db_qd_log Debug "the ad_conn file is [ad_conn file]"} errmsg]} {}
	}

	# Now we do a check to see if this is a directly accessed URL or a 
        # sourced URL

        # added case for handling .vuh files which are sourced from 
        # rp_handle_tcl_request.  Otherwise, QD was forming fullquery path 
        # with the assumption that the query resided in the 
        # rp_handle_tcl_request proc itself. (Openacs - DanW)

        switch $proc_name {

            ns_sourceproc {
                db_qd_log Debug "We are in a WWW page, woohoo!"
                set real_url_p 1
                set url [ns_conn url]
            }

            rp_handle_tcl_request {
                db_qd_log Debug "We are in a VUH page sourced by rp_handle_tcl_request, woohoo!"
                set real_url_p 0
                regsub {\.vuh} [ad_conn file] {} url
                set url [ad_make_relative_path $url]
                regsub {^/?packages} $url {} url
            }

            template::frm_page_handler {
                db_qd_log Debug "We are in the template system's form page debugger!"
                set real_url_p 1
                regsub {\.frm} [ad_conn url] {} url
            }

            default {
                db_qd_log Debug "We are in a WWW page sourced by apm_source, woohoo!"
                set real_url_p 0
                set url [lindex $proc_name 1]
                set url [ad_make_relative_path $url]
                regsub {^/?packages} $url {} url
            }
        }

	# Get the URL and remove the .tcl
	regsub {^/} $url {} url
	regsub {\.tcl$} $url {} url
	regsub {\.vuh$} $url {} url

	# Change all dots to colons, and slashes to dots
	regsub -all {\.} $url {:} url
	regsub -all {/} $url {.} url

	# We insert the "www" after the package key
	regexp {^([^\.]*)(.*)} $url all package_key rest

	db_qd_log Debug "package key is $package_key and rest is $rest"

	if {$real_url_p} {
	    set full_name [db_qd_make_absolute_path "${package_key}.www${rest}." $local_name]
	    # set full_name "acs.${package_key}.www${rest}.${local_name}"
	} else {
	    set full_name [db_qd_make_absolute_path "${package_key}${rest}." $local_name]
	    # set full_name "acs.${package_key}${rest}.${local_name}"
	}
    } else {
	# Let's find out where this Tcl proc is defined!!
	# Get the first word, which is the Tcl proc
	regexp {^([^ ]*).*} $proc_name all proc_name

        # check to see if a package proc is being called without 
        # namespace qualification.  If so, add the package qualification to the
        # proc_name, so that the correct query can be looked up. 
        # (Openacs - DanW)

        set calling_namespace [string range [uplevel [expr 1 + $added_stack_num] {namespace current}] 2 end]
        db_qd_log Debug "calling namespace = $calling_namespace"

        if {![string equal $calling_namespace ""] && 
            ![regexp {::} $proc_name all]} {

            set proc_name ${calling_namespace}::${proc_name}
        }
	db_qd_log Debug "proc_name is -$proc_name-"

	# We use the ad_proc construct!! 
	# (woohoo, can't believe that was actually useful!)
	
	# First we check if the proc is there. If not, then we're
	# probably dealing with one of the bootstrap procs, and so we just
	# return a bogus proc name
	if {![nsv_exists api_proc_doc $proc_name]} {
	    db_qd_log Debug "there is no documented proc with name $proc_name -- we used default SQL"
	    return [db_qd_null_path]
	}

	array set doc_elements [nsv_get api_proc_doc $proc_name]
	set url $doc_elements(script)

	db_qd_log Debug "tcl file is $url"

	regsub {.tcl$} $url {} url

	# Change all dots to colons, and slashes to dots
	regsub -all {\.} $url {:} url
	regsub -all {/} $url {.} url

	# We get something like packages.acs-tcl.tcl.acs-kernel-procs
	# We need to remove packages.
	regexp {^packages\.(.*)} $url all rest

	db_qd_log Debug "TEMP - QD: proc_name is $proc_name"
	db_qd_log Debug "TEMP - QD: local_name is $local_name"

	# set full_name "acs.$rest.${proc_name}.${local_name}"
	set full_name [db_qd_make_absolute_path "${rest}.${proc_name}." $local_name]
    }

    db_qd_log Debug "generated fullname of $full_name"
    return $full_name
}

# Fetch a query with a given name
#
# This procedure returns the latest FullQuery data structure
# given proper scoping rules for a complete/global query name.
# This may or may not be cached, the caller need not know.
proc db_qd_fetch {fullquery_name {rdbms {}}} {
    # For now we consider that everything is cached
    # from startup time
    return [db_qd_internal_get_cache $fullquery_name]
}

# Do the right thing 
proc db_qd_replace_sql {statement_name sql} {
    set fullquery [db_qd_fetch $statement_name]

    if {![empty_string_p $fullquery]} {
	set sql [db_fullquery_get_querytext $fullquery]
    } else {
	db_qd_log Debug "NO FULLQUERY FOR $statement_name --> using default SQL"
    }

    return $sql
}

# fetch a query snippet.  used to provide db-specific query snippets when 
# porting highly dynamic queries.  (OpenACS - DanW)
proc db_map {snippet_name} {
    set fullname [db_qd_get_fullname $snippet_name]
    set fullquery [db_qd_fetch $fullname]
    set sql [db_fullquery_get_querytext $fullquery]

    db_qd_log Debug "PARTIALQUERY FOR $fullname: $sql"
    return [uplevel 1 [list subst -nobackslashes $sql]]
}

# Check compatibility of a FullQuery against an RDBMS
#
# This procedure returns true or false. The RDBMS argument
# can be left out, in which case, the currently running RDBMS
# is the one against which compatibility will be checked.
proc db_fullquery_compatible_p {fullquery {rdbms {}}} {
    set query_rdbms [db_fullquery_get_rdbms $fullquery]

    # NOTE: not complete
    # return something depending on compatibility of RDBMSs
}



######################################################
#
# Utility Procedures 
# (these are *not* to be called by code other than
# the above)
#
######################################################

# Load up a bunch of queries from a file pointer
#
# The file_tag parameter is for later flushing of a series
# of queries when a particular query file has been changed.
#
# DRB: it is now used to track the mtime of the query file when loaded,
# used by the APM to determine when a package should be reloaded.  This
# code depends on the file tag parameter being set to the actual file path
# to the query file.

proc db_qd_internal_load_queries {file_pointer file_tag} {
    # While there are surely efficient ways of loading large files,
    # we're going to assume smaller files for now. Plus, this doesn't happen
    # often.

    db_qd_log Debug "Loading $file_tag"

    # Read entire contents
    set whole_file [read $file_pointer]

    # PREPARE THE FILE (ben - this is in case the file needs massaging before parsing)
    set whole_file [db_qd_internal_prepare_queryfile_content $whole_file]

    # Iterate and parse out each query
    set parsing_state [db_qd_internal_parse_init $whole_file $file_tag]
    
    db_qd_log Debug "parsing state - $parsing_state"

    # We need this for queries with relative paths
    set acs_file_path [ad_make_relative_path $file_tag]
    set queryname_root [db_qd_internal_get_queryname_root $acs_file_path]

    db_qd_log Debug "queryname root is $queryname_root"

    while {1} {
	set result [db_qd_internal_parse_one_query $parsing_state]
	
	db_qd_log Debug "one parse result -$result-"

	# If we get the empty string, we are done parsing
	if {$result == ""} {
	    break
	}

	set one_query [lindex $result 0]
	set parsing_state [lindex $result 1]

	db_qd_log Debug "loaded one query - [db_fullquery_get_name $one_query]"

	# Relative Path for the Query
	if {[db_qd_relative_path_p [db_fullquery_get_name $one_query]]} {
	    set new_name [db_qd_make_absolute_path $queryname_root [db_fullquery_get_name $one_query]]

	    set new_fullquery [db_fullquery_create \
		    $new_name \
		    [db_fullquery_get_querytext $one_query] \
		    [db_fullquery_get_bind_vars $one_query] \
		    [db_fullquery_get_query_type $one_query] \
		    [db_fullquery_get_rdbms $one_query] \
		    [db_fullquery_get_load_location $one_query]]

	    set one_query $new_fullquery

	    db_qd_log Debug "relative path, replaced name with $new_name"
	}

	# Store the query
	db_qd_internal_store_cache $one_query
    }

    set relative_path [string range $file_tag \
        [expr { [string length [acs_root_dir]] + 1 }] end]
    nsv_set apm_library_mtime $relative_path [file mtime $file_tag]
}


# Load from Cache
proc db_qd_internal_get_cache {fullquery_name} {

    # If we have no record
    if {![nsv_exists OACS_FULLQUERIES $fullquery_name]} {
	return ""
    }

    set fullquery_array [nsv_get OACS_FULLQUERIES $fullquery_name]

    # If this isn't cached!
    if {$fullquery_array == ""} {
	# we need to do something
	return ""
    }

    # See if we have the correct location for this query
    db_qd_log Debug "query $fullquery_name from [db_fullquery_get_load_location $fullquery_array]"

    # reload the fullquery
    set fullquery_array [nsv_get OACS_FULLQUERIES $fullquery_name]

    # What we get back from the cache is the FullQuery structure
    return $fullquery_array
}

# Store in Cache
#
# The load_location is the file where this query was found
proc db_qd_internal_store_cache {fullquery} {

    # Check if it's compatible at all!
    if {![db_rdbms_compatible_p [db_fullquery_get_rdbms $fullquery] [db_current_rdbms]]} {
	db_qd_log Debug "Query [db_fullquery_get_name $fullquery] is *NOT* compatible"
	return
    }

    set name [db_fullquery_get_name $fullquery]

    db_qd_log Debug "Query $name is compatible! fullquery = $fullquery, name = $name"

    # If we already have a query for that name, we need to
    # figure out which one is *most* compatible.
    if {[nsv_exists OACS_FULLQUERIES $name]} {
	set old_fullquery [nsv_get OACS_FULLQUERIES $name]

	set fullquery [db_qd_pick_most_specific_query [db_current_rdbms] $old_fullquery $fullquery]
    }

    nsv_set OACS_FULLQUERIES $name $fullquery
}

# Flush queries for a particular file path, and reload them
proc db_qd_internal_load_cache {file_path} {
    # First we actually need to flush queries that are associated with that file tag
    # in case they are not all replaced by reloading that file. That is nasty! Oh well.

    # We'll do this later
    
    # we just reparse the file
    set stream [open $file_path "r"]
    db_qd_internal_load_queries $stream $file_path
    close $stream
}


##
## NAMING
##

proc db_qd_internal_get_queryname_root {relative_path} {
    # remove the prepended "/packages/" string
    regsub {^\/?packages\/} $relative_path {} relative_path

    # remove the last chunk of the file name, since we're just looking for the root path
    # NOTE: THIS MAY NEED BETTER ABSTRACTION, since this assumes a naming scheme
    # of -rdbms.XXX (ben)
    regsub {\.xql} $relative_path {} relative_path
    regsub -- "\-[db_type]$" $relative_path {} relative_path

    # Change all . to :
    regsub -all {\.} $relative_path {:} relative_path    

    # Change all / to . (hah, no reference to News for Nerds)
    regsub -all {/} $relative_path {.} relative_path

    # We append a "." at the end, since we want easy concatenation
    return "${relative_path}."
}

##
## PARSING
##

## We want to parse iteratively
## The architecture of this parsing scheme allows for streaming XML parsing
## in the future. But right now we keep things simple

# Initialize the parsing state
proc db_qd_internal_parse_init {stuff_to_parse file_path} {
    
    # Do initial parse
    set parsed_doc [xml_parse -persist $stuff_to_parse]

    # Initialize the parsing state
    set index 0

    # Get the list of queries out
    set root_node [xml_doc_get_first_node $parsed_doc]

    # Check that it's a queryset
    if {[xml_node_get_name $root_node] != "queryset"} {
	db_qd_log Debug "OH OH, error, first node is [xml_node_get_name $root_node]"
	# CHANGE THIS: throw an error!!!
	return ""
    }

    # Extract the default RDBMS if there is one
    set rdbms_nodes [xml_node_get_children_by_name $root_node rdbms]
    if {[llength $rdbms_nodes] > 0} {
	set default_rdbms [db_rdbms_parse_from_xml_node [lindex $rdbms_nodes 0]]
	db_qd_log Debug "Detected DEFAULT RDBMS for whole queryset: $default_rdbms"
    } else {
	set default_rdbms ""
    }

    set parsed_stuff [xml_node_get_children_by_name $root_node fullquery]

    db_qd_log Debug "end of parse_init: $index; $parsed_stuff; $parsed_doc; $default_rdbms; $file_path"

    return [list $index $parsed_stuff $parsed_doc $default_rdbms $file_path]
}

# Parse one query using the query state
proc db_qd_internal_parse_one_query {parsing_state} {
    
    # Find the index that we're looking at
    set index [lindex $parsing_state 0]
    
    # Find the list of nodes
    set node_list [lindex $parsing_state 1]

    # Parsed Doc Pointer
    set parsed_doc [lindex $parsing_state 2]

    # Default RDBMS
    set default_rdbms [lindex $parsing_state 3]
    set file_path [lindex $parsing_state 4]

    db_qd_log Debug "default_rdbms is $default_rdbms"

    db_qd_log Debug "node_list is $node_list with length [llength $node_list] and index $index"

    # BASE CASE
    if {[llength $node_list] <= $index} {
	# Clean up
	xml_doc_free $parsed_doc

	db_qd_log Debug "Cleaning up, done parsing"

	# return nothing
	return ""
    }

    # Get one query
    set one_query_xml [lindex $node_list $index]
    
    # increase index
    incr index

    # Update the parsing state so we know
    # what to parse next 
    set parsing_state [list $index $node_list [lindex $parsing_state 2] $default_rdbms $file_path]

    # Parse the actual query from XML
    set one_query [db_qd_internal_parse_one_query_from_xml_node $one_query_xml $default_rdbms $file_path]

    # Return the query and the parsing state
    return [list $one_query $parsing_state]

}


# Parse one query from an XML node
proc db_qd_internal_parse_one_query_from_xml_node {one_query_node {default_rdbms {}} {file_path {}}} {
    db_qd_log Debug "parsing one query node in XML with name -[xml_node_get_name $one_query_node]-"

    # Check that this is a fullquery
    if {[xml_node_get_name $one_query_node] != "fullquery"} {
	return ""
    }
    
    set queryname [xml_node_get_attribute $one_query_node name]

    # Get the text of the query
    set querytext [xml_node_get_content [xml_node_get_first_child_by_name $one_query_node querytext]]

    # Get the RDBMS
    set rdbms_nodes [xml_node_get_children_by_name $one_query_node rdbms]
    
    # If we have no RDBMS specified, use the default
    if {[llength $rdbms_nodes] == 0} {
	db_qd_log Debug "Wow, Nelly, no RDBMS for this query, using default rdbms $default_rdbms"
	set rdbms $default_rdbms
    } else {
	set rdbms_node [lindex $rdbms_nodes 0]
	set rdbms [db_rdbms_parse_from_xml_node $rdbms_node]
    }

    return [db_fullquery_create $queryname $querytext [list] "" $rdbms $file_path]
}

# Parse and RDBMS struct from an XML fragment node
proc db_rdbms_parse_from_xml_node {rdbms_node} {
    # Check that it's RDBMS
    if {[xml_node_get_name $rdbms_node] != "rdbms"} {
	db_qd_log Debug "PARSER = BAD RDBMS NODE!"
	return ""
    }

    # Get the type and version tags
    set type [xml_node_get_content [xml_node_get_first_child_by_name $rdbms_node type]]
    set version [xml_node_get_content [xml_node_get_first_child_by_name $rdbms_node version]]

    db_qd_log Debug "PARSER = RDBMS parser - $type - $version"

    return [db_rdbms_create $type $version]
}


##
## RELATIVE AND ABSOLUTE QUERY PATHS
##

# The token that indicates the root of all queries
proc db_qd_root_path {} {
    return "dbqd."
}

proc db_qd_null_path {} {
    return "[db_qd_root_path].NULL"
}

# Check if the path is relative
proc db_qd_relative_path_p {path} {
    set root_path [db_qd_root_path]
    set root_path_length [string length $root_path]

    # Check if the path starts with the root
    if {[string range $path 0 [expr "$root_path_length - 1"]] == $root_path} {
	return 0
    } else {
	return 1
    }
}

# Make a path absolute
proc db_qd_make_absolute_path {relative_root suffix} {
    return "[db_qd_root_path]${relative_root}$suffix"
}


##
## Extra Utilities to Massage the system and Rub it in all the right ways
##
proc db_qd_internal_prepare_queryfile_content {file_content} {
    
    set new_file_content ""

    # The lazy way to do it.  partialquery was added for clarification of 
    # the query files, but in fact a partialquery and a fullquery are parsed 
    # exactly the same.  Doing this saves the bother of having to tweak the 
    # rest of the parsing code to handle partialquery.  (OpenACS - DanW)

    regsub -all {(</?)partialquery([ >])} $file_content {\1fullquery\2} rest_of_file_content

    set querytext_open "<querytext>"
    set querytext_close "</querytext>"

    set querytext_open_len [string length $querytext_open]
    set querytext_close_len [string length $querytext_close]

    # We're going to ns_quotehtml the querytext,
    # because ns_xml will choke otherwise
    while {1} {
	set first_querytext_open [string first $querytext_open $rest_of_file_content]
	set first_querytext_close [string first $querytext_close $rest_of_file_content]

	# We have no more querytext to process
	if {$first_querytext_open == -1} {
	    append new_file_content $rest_of_file_content
	    break
	}

	# append first chunk before the querytext including "<querytext>"
	append new_file_content [string range $rest_of_file_content 0 [expr "$first_querytext_open + $querytext_open_len - 1"]]

	# append quoted querytext
	append new_file_content [ns_quotehtml [string range $rest_of_file_content [expr "$first_querytext_open + $querytext_open_len"] [expr "$first_querytext_close - 1"]]]

	# append close querytext
	append new_file_content $querytext_close

	# Set up the rest
	set rest_of_file_content [string range $rest_of_file_content [expr "$first_querytext_close + $querytext_close_len"] end]
    }

    db_qd_log Debug "new massaged file content: \n $new_file_content \n"

    return $new_file_content
}


##
## Logging
##

proc db_qd_log {level msg} {
    # Centralized DB QD logging
    # We switch everything to debug for now
    ns_log $level "QD_LOGGER = $msg"
}

