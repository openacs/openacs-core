
#
# Query Dispatching for multi-RDBMS capability
# The OpenACS Project
#
# Ben Adida (ben@mit.edu)
#
# STATE OF THIS FILE (3/29/2001) - BMA:
# This is starting to work, but isn't yet ready for actual dev work
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
    ns_log Notice "QD/COMPATIBILITY = The RDBMS_TEST is [db_rdbms_get_type $rdbms_test] - [db_rdbms_get_version $rdbms_test]"
    ns_log Notice "QD/COMPATIBILITY = The RDBMS_PATTERN is [db_rdbms_get_type $rdbms_pattern] - [db_rdbms_get_version $rdbms_pattern]"

    # If the pattern is for all RDBMS, then yeah, compatible
    if {[empty_string_p [db_rdbms_get_type $rdbms_pattern]]} {
	return 1
    }

    # If the RDBMS types are not the same, we have a problem
    if {[db_rdbms_get_type $rdbms_test] != [db_rdbms_get_type $rdbms_pattern]} {
	ns_log Notice "QD - compatibility - RDBMS types are different!"
	return 0
    }

    # If the pattern has no version
    if {[empty_string_p [db_rdbms_get_version $rdbms_pattern]]} {
	return 1
    }

    # If the query being tested was written for a version that is older than the current RDBMS
    # then we have compatibility. Otherwise we don't.
    if {[db_rdbms_get_version $rdbms_pattern] <= [db_rdbms_get_version $rdbms_test]} {
	return 1
    }

    ns_log Notice "QD - compatibility - version numbers are bad!"
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
proc db_fullquery_pick_most_specific_query {rdbms query_1 query_2} {
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

# Find the fully qualified name of the query
proc db_fullquery_get_fullname {local_name {added_stack_num 1}} {
    # We do a check to see if we already have a fullname.
    # Since the DB procs are a bit incestuous, this might get
    # called more than once. DAMMIT! (ben)
    if {[regexp {^acs\.} $local_name all]} {
	return $local_name
    }

    # Get the proc name being executed.
    set proc_name [info level [expr "-1 - $added_stack_num"]]

    # We check if we're running the special ns_ proc that tells us
    # whether this is an URL or a Tcl proc.
    if {[regexp {^ns_sourceproc} $proc_name all]} {

	# Means we are running inside an URL

	# Get the URL and remove the .tcl
	set url [ns_conn url]
	regsub {.tcl$} $url {} url

	# Change all dots to colons, and slashes to dots
	regsub -all {\.} $url {:} url
	regsub -all {/} $url {.} url

	# We insert the "www" after the package key
	regexp {^([^\.]*)(.*)} url all package_key rest

	set full_name "acs.${package_key}.www.${rest}.${local_name}"
    } else {
	# Let's find out where this Tcl proc is defined!!
	# Get the first word, which is the Tcl proc
	regexp {^([^ ]*).*} $proc_name all proc_name
	ns_log Notice "QD = proc_name is -$proc_name-"

	# We use the ad_proc construct!! 
	# (woohoo, can't believe that was actually useful!)
	
	# First we check if the proc is there. If not, then we're
	# probably dealing with one of the bootstrap procs, and so we just
	# return a bogus proc name
	if {![nsv_exists api_proc_doc $proc_name]} {
	    ns_log Notice "QD: there is no documented proc with name $proc_name -- we used default SQL"
	    return "acs.NULL"
	}

	array set doc_elements [nsv_get api_proc_doc $proc_name]
	set url $doc_elements(script)

	# ns_log Notice "QD = tcl file is $url"

	regsub {.tcl$} $url {} url

	# Change all dots to colons, and slashes to dots
	regsub -all {\.} $url {:} url
	regsub -all {/} $url {.} url

	# We get something like packages.acs-tcl.tcl.acs-kernel-procs
	# We need to remove packages.
	regexp {^packages\.(.*)} $url all rest

	ns_log Notice "TEMP - QD: proc_name is $proc_name"
	ns_log Notice "TEMP - QD: local_name is $local_name"

	set full_name "acs.$rest.${proc_name}.${local_name}"
    }

    return $full_name
}

# Fetch a query with a given name
#
# This procedure returns the latest FullQuery data structure
# given proper scoping rules for a complete/global query name.
# This may or may not be cached, the caller need not know.
proc db_fullquery_fetch {fullquery_name {rdbms {}}} {
    # For now we consider that everything is cached
    # from startup time
    return [db_fullquery_internal_get_cache $fullquery_name]
}

# Do the right thing 
proc db_fullquery_replace_sql {statement_name sql} {
    set fullquery [db_fullquery_fetch $statement_name]

    if {![empty_string_p $fullquery]} {
	set sql [db_fullquery_get_querytext $fullquery]
    } else {
	ns_log Notice "QD = NO FULLQUERY FOR $statement_name --> using default SQL"
    }

    return $sql
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
proc db_fullquery_internal_load_queries {file_pointer file_tag} {
    # While there are surely efficient ways of loading large files,
    # we're going to assume smaller files for now. Plus, this doesn't happen
    # often.

    ns_log Notice "QD = Loading $file_tag"

    # Read entire contents
    set whole_file [read $file_pointer]

    # Iterate and parse out each query
    set parsing_state [db_fullquery_internal_parse_init $whole_file]
    
    ns_log Notice "QD = parsing state - $parsing_state"
    
    while {1} {
	set result [db_fullquery_internal_parse_one_query $parsing_state]
	
	ns_log Notice "QD = one parse result -$result-"

	# If we get the empty string, we are done parsing
	if {$result == ""} {
	    break
	}

	set one_query [lindex $result 0]
	set parsing_state [lindex $result 1]

	ns_log Notice "QD = loaded one query - [db_fullquery_get_name $one_query]"

	# Store the query
	db_fullquery_internal_store_cache $one_query
    }
}


# Load from Cache
proc db_fullquery_internal_get_cache {fullquery_name} {

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

    # What we get back from the cache is the FullQuery structure
    return $fullquery_array
}

# Store in Cache
#
# The load_location is the file where this query was found
proc db_fullquery_internal_store_cache {fullquery} {

    # Check if it's compatible at all!
    if {![db_rdbms_compatible_p [db_fullquery_get_rdbms $fullquery] [db_current_rdbms]]} {
	ns_log Notice "QD = Query [db_fullquery_get_name $fullquery] is *NOT* compatible"
	return
    }

    set name [db_fullquery_get_name $fullquery]

    ns_log Notice "QD = Query $name is compatible!"

    # If we already have a query for that name, we need to
    # figure out which one is *most* compatible.
    if {[nsv_exists OACS_FULLQUERIES $name]} {
	set old_fullquery [nsv_get OACS_FULLQUERIES $name]

	set fullquery [db_fullquery_pick_most_specific_query [db_current_rdbms] $old_fullquery $fullquery]
    }


    nsv_set OACS_FULLQUERIES $name $fullquery
}

# Flush queries for a particular file path, and reload them
proc db_fullquery_internal_load_cache {file_path} {
    # First we actually need to flush queries that are associated with that file tag
    # in case they are not all replaced by reloading that file. That is nasty! Oh well.

    # We'll do this later
    
    # we just reparse the file
    set stream [open $file_path "r"]
    db_fullquery_internal_load_queries $stream $file_path
    close $stream
}



##
## PARSING
##

## We want to parse iteratively
## The architecture of this parsing scheme allows for streaming XML parsing
## in the future. But right now we keep things simple

# Initialize the parsing state
proc db_fullquery_internal_parse_init {stuff_to_parse} {
    
    # Do initial parse
    set parsed_doc [ns_xml parse -persist $stuff_to_parse]

    # Initialize the parsing state
    set index 0

    # Get the list of queries out
    set root_node [ns_xml doc root $parsed_doc]

    # Check that it's a queryset
    if {[ns_xml node name $root_node] != "queryset"} {
	# CHANGE THIS: throw an error!!!
	return ""
    }

    set parsed_stuff [ns_xml node children $root_node]

    return [list $index $parsed_stuff $parsed_doc]
}

# Parse one query using the query state
proc db_fullquery_internal_parse_one_query {parsing_state} {
    
    # Find the index that we're looking at
    set index [lindex $parsing_state 0]
    
    # Find the list of nodes
    set node_list [lindex $parsing_state 1]

    ns_log Notice "QD = node_list is $node_list with length [llength $node_list] and index $index"

    # BASE CASE
    if {[llength $node_list] <= $index} {
	# Clean up
	ns_xml doc free [lindex $parsing_state 2]

	ns_log Notice "QD = Cleaning up, done parsing"

	# return nothing
	return ""
    }

    # Get one query
    set one_query_xml [lindex $node_list $index]
    
    # increase index
    incr index

    # Update the parsing state so we know
    # what to parse next 
    set parsing_state [list $index $node_list [lindex $parsing_state 2]]

    # Parse the actual query from XML
    set one_query [db_fullquery_internal_parse_one_query_from_xml_node $one_query_xml]

    # Return the query and the parsing state
    return [list $one_query $parsing_state]

}


# Parse one query from an XML node
proc db_fullquery_internal_parse_one_query_from_xml_node {one_query_node} {
    ns_log Notice "QD = parsing one query node in XML with name -[ns_xml node name $one_query_node]-"

    # Check that this is a fullquery
    if {[ns_xml node name $one_query_node] != "fullquery"} {
	return ""
    }
    
    set queryname [ns_xml node getattr $one_query_node name]

    # Get the text of the query
    set querytext [ns_xml node getcontent [lindex [xml_find_child_nodes $one_query_node querytext] 0]]

    # Get the RDBMS
    set rdbms_node [lindex [xml_find_child_nodes $one_query_node rdbms] 0]
    set rdbms [db_rdbms_parse_from_xml_node $rdbms_node]

    return [db_fullquery_create $queryname $querytext [list] "" $rdbms ""]
}

# Parse and RDBMS struct from an XML fragment node
proc db_rdbms_parse_from_xml_node {rdbms_node} {
    # Check that it's RDBMS
    if {[ns_xml node name $rdbms_node] != "rdbms"} {
	ns_log Notice "QD/PARSER = BAD RDBMS NODE!"
	return ""
    }

    # Get the type and version tags
    set type [ns_xml node getcontent [lindex [xml_find_child_nodes $rdbms_node type] 0]]
    set version [ns_xml node getcontent [lindex [xml_find_child_nodes $rdbms_node version] 0]]

    ns_log Notice "QD/PARSER = RDBMS parser - $type - $version"

    return [db_rdbms_create $type $version]
}