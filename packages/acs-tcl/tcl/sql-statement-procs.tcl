#
# Procs for manipulating SQL statements
#
# lars@pinds.com, May 2000
#
# $Id$
#

#
# How to use this:
#
# You simply call ad_sql_append any number of times, then ad_sql_get to feed to the database.
#
# What you gain from using these two procs is that the parts of the sql statement will
# always be output in the right sequence.
#

#
# How this works:
#
# We represent a SQL statement as a Tcl array of the form
#
# stmt(select) { t1.column1 t2.column2 t2.column3 ... } join by ,
# stmt(from) { { table1 t1} {table2 t2} } join by ,
# stmt(where) { condition1 condition2 } join by and
# stmt(groupby) { groupcol1 groupcol2 } join by ,
# stmt(orderby) { {ordercol1 asc} {ordercol2 desc}} join by ,
#

ad_proc ad_sql_get { 
    { 
    }
    sqlarrayname
} {
    Returns the SQL statement as a string
} {
    upvar $sqlarrayname sql

    if { ![info exists sql(select)] } {
	error "SQL statement doesn't have any SELECT clause"
    }
    if { ![info exists sql(from)] } {
	error "SQL statement doesn't have any FROM clause"
    }

    set sql_string "select [join $sql(select) ", "]\nfrom [join $sql(from) ", "]\n"
    
    if { [info exists sql(where)] && [llength $sql(where)] > 0 } {
	append sql_string "where [join $sql(where) "\nand "]\n"
    }
    
    if { [info exists sql(groupby)] && [llength $sql(groupby)] > 0 } {
	append sql_string "group by [join $sql(groupby) ", "]\n"
    }
    
    if { [info exists sql(orderby)] && [llength $sql(orderby)] > 0 } { 
	append sql_string "order by [join $sql(orderby) ", "]\n"
    }

    return $sql_string
}

ad_proc ad_sql_append { 
    {
	-select {}
	-from {}
	-where {}
	-groupby {}
	-orderby {}
    } 
    sqlarrayname
} { 
    Adds to the SQL statement.
} {
    upvar $sqlarrayname sql
    if { ![empty_string_p $select] } {
	lappend sql(select) $select
    }
    if { ![empty_string_p $from] } {
	lappend sql(from) $from
    }
    if { ![empty_string_p $where] } {
	lappend sql(where) $where
    }
    if { ![empty_string_p $groupby] } {
	lappend sql(groupby) $groupby
    }
    if { ![empty_string_p $orderby] } {
	lappend sql(orderby) $orderby
    }
}

