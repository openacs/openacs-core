
#
# Query Dispatching for multi-RDBMS capability
# The OpenACS Project
#
# Ben Adida (ben@mit.edu)
#
# STATE OF THIS FILE (3/17/2001) - BMA:
# Just function prototypes and some initial simple implementations to start clearing the field.
# Don't expect any of this to work just yet!
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


##################################
# The FullQuery Data Abstraction
##################################



# The Constructor

proc db_fullquery_create {queryname querytext bind_vars_lst query_type rdbms load_location} {
    return [list $queryname $querytext $bind_vars_lst $query_type $rdbms_type $rdbms_version $load_location]
}

# The Accessor procs

proc db_fullquery_get_name {fullquery} {
    return [list $fullquery 0]
}

proc db_fullquery_get_querytext {fullquery} {
    return [list $fullquery 1]
}

proc db_fullquery_get_bind_vars {fullquery} {
    return [list $fullquery 2]
}

proc db_fullquery_get_query_type {fullquery} {
    return [list $fullquery 3]
}

proc db_fullquery_get_rdbms {fullquery} {
    return [list $fullquery 4]
}

proc db_fullquery_get_load_location {fullquery} {
    return [list $fullquery 5]
}


################################################
#
#
# QUERY DISPATCHING
#
#
################################################

# Fetch a query with a given name
#
# This procedure returns the latest FullQuery data structure
# given proper scoping rules for a complete/global query name.
# This may or may not be cached, the caller need not know.
proc db_fullquery_fetch {fullquery_name} {
    # For now we consider that everything is cached
    # from startup time
    return [db_fullquery_internal_get_cache $fullquery_name]
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

    # Read entire contents
    set whole_file [read $file_pointer]

    # Iterate and parse out each query
    set parsing_state [db_fullquery_internal_parse_init $whole_file]
    
    while {1} {
	set result [db_fullquery_internal_parse_one_query $parsing_state]
	
	# If we get the empty string, we are done parsing
	if {$result == ""} {
	    break
	}

	set one_query [lindex $result 0]
	set one_query_name [lindex $result 1]
	set parsing_state [lindex $result 2]

	# Store the query
	db_fullquery_internal_store_cache $one_query_name $file_tag $one_query
    }
}


# Load from Cache
proc db_fullquery_internal_get_cache {fullquery_name} {
    set fullquery_struct [nsv_get OACS_FULLQUERIES $fullquery_name]

    # If this isn't cached!
    if {$fullquery_struct == ""} {
	# we need to do something
    }

    # What we get back from the cache is the FullQuery structure
    return $fullquery_struct
}

# Store in Cache
#
# The load_location is the file where this query was found
proc db_fullquery_internal_store_cache {fullquery} {
    set name [db_fullquery_get_name $fullquery]

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

    # BASE CASE
    if {[llength $node_list] >= $index} {
	# Clean up
	ns_xml doc free [lindex $parsing_state 2]

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

    # Return the query, the query name, and the parsing state
    return [list [lindex $one_query 0] [lindex $one_query 1] $parsing_state]

}


# Parse one query from an XML node
proc db_fullquery_internal_parse_one_query_from_xml_node {one_query_node} {
    
}
