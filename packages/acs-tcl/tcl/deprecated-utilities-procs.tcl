ad_library {

    Provides a variety of non-ACS-specific utilities that have been
    deprecated

    Note the 5.2 deprecated procs have been moved to deprecated/5.2/acs-tcl


    @author yon [yon@arsdigita.com]
    @creation-date 9 Jul 2000
    @cvs-id $Id$

}

# if you do a 
#   set selection [ns_db 1row $db "select foo,bar from my_table where key=37"]
#   set_variables_after_query
# then you will find that the Tcl vars $foo and $bar are set to whatever
# the database returned.  If you don't like these var names, you can say
#   set selection [ns_db 1row $db "select count(*) as n_rows from my_table"]
#   set_variables_after_query
# and you will find the Tcl var $n_rows set

# You can also use this in a multi-row loop
#   set selection [ns_db select $db "select *,email from mailing_list order by email"]
#   while { [ns_db getrow $db $selection] } {
#        set_variables_after_query
#         ... your code here ...
#   }
# then the appropriate vars will be set during your loop

#
# CAVEAT NERDOR:  you MUST use the variable name "selection"
# 

#
# we pick long names for the counter and limit vars
# because we don't want them to conflict with names of
# database columns or in parent programs
#

ad_proc -deprecated -warn set_variables_after_query {} {
    to be removed.


    @see packages/acs-tcl/tcl/00-database-procs.tcl
} { 
    uplevel {
	    set set_variables_after_query_i 0
	    set set_variables_after_query_limit [ns_set size $selection]
	    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
		set [ns_set key $selection $set_variables_after_query_i] [ns_set value $selection $set_variables_after_query_i]
		incr set_variables_after_query_i
	    }
    }
}

# as above, but you must use sub_selection

ad_proc -deprecated -warn set_variables_after_subquery {} {
    to be removed.


    @see packages/acs-tcl/tcl/00-database-procs.tcl
} { 
    uplevel {
	    set set_variables_after_query_i 0
	    set set_variables_after_query_limit [ns_set size $sub_selection]
	    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
		set [ns_set key $sub_selection $set_variables_after_query_i] [ns_set value $sub_selection $set_variables_after_query_i]
		incr set_variables_after_query_i
	    }
    }
}

#same as philg's but you can:
#1. specify the name of the "selection" variable
#2. append a prefix to all the named variables

ad_proc -deprecated -warn set_variables_after_query_not_selection {selection_variable {name_prefix ""}} {
    to be removed.


    @see packages/acs-tcl/tcl/00-database-procs.tcl
} { 
    set set_variables_after_query_i 0
    set set_variables_after_query_limit [ns_set size $selection_variable]
    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
        # NB backslash squarebracket needed since mismatched {} would otherwise mess up value stmt.
	uplevel "
	set ${name_prefix}[ns_set key $selection_variable $set_variables_after_query_i] \[ns_set value $selection_variable $set_variables_after_query_i]
	"
	incr set_variables_after_query_i
    }
}
