
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

proc db_fullquery_create {querytext bind_vars_lst query_type rdbms} {
    return [list $querytext $bind_vars_lst $query_type $rdbms_type $rdbms_version]
}

# The Accessor procs

proc db_fullquery_get_querytext {fullquery} {
    return [list $fullquery 0]
}

proc db_fullquery_get_bind_vars {fullquery} {
    return [list $fullquery 1]
}

proc db_fullquery_get_query_type {fullquery} {
    return [list $fullquery 2]
}

proc db_fullquery_get_rdbms {fullquery} {
    return [list $fullquery 3]
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
}

# Store in Cache
#
# The load_location is the file where this query was found
proc db_fullquery_internal_store_cache {fullquery_name load_location fullquery} {
}

# Flush queries for a particular file tag
proc db_fullquery_internal_flush_cache {file_tag} {
}



##
## PARSING
##

## We want to parse iteratively
## The architecture of this parsing scheme allows for streaming XML parsing
## in the future. But right now we keep things simple

# Initialize the parsing state
proc db_fullquery_internal_parse_init {stuff_to_parse} {
    
    ## NOTE: note done, must actually XML parse here
    ## using ns_xml
    set parsed_stuff ""

    set index 0

    return [list $index $parsed_stuff]
}

# Parse one query using the query state
proc db_fullquery_internal_parse_one_query {parsing_state} {
    
    ## Get the right query using the state
    ## Note: not done!!
    set one_query_xml ""

    # BASE CASE: if there are no more queries, return empty string

    # Increase the index
    set index [lindex $parsing_state 0]
    incr index

    # Update the parsing state so we know
    # what to parse next 
    set parsing_state [list $index [lindex $parsing_state 1]]

    # Parse the actual query from XML
    set one_query [db_fullquery_internal_parse_one_query_from_xml_node $one_query_xml]

    # Return the query, the query name, and the parsing state
    return [list [lindex $one_query 0] [lindex $one_query 1] $parsing_state]

}
