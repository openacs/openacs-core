# /packages/subsite/tcl/party-procs.tcl

ad_library {

    Procs to manage groups

    @author oumi@arsdigita.com
    @creation-date 2001-02-06
    @cvs-id $Id$

}


namespace eval party {

    ad_proc -public permission_p { 
	{ -user_id "" }
	{ -privilege "read" }
	party_id
    } {
	Wrapper for ad_permission to allow us to bypass having to
	specify the read privilege

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 10/2000

    } {
	return [permission::permission_p -party_id $user_id -object_id $party_id -privilege $privilege]
    }


    ad_proc new { 
	{ -form_id "" }
	{ -variable_prefix "" }
	{ -creation_user "" }
	{ -creation_ip "" }
	{ -party_id "" } 
	{ -context_id "" } 
	{ -email "" }
	party_type 
    } {
	Creates a party of this type by calling the .new function for
	the package associated with the given party_type. This
	function will fail if there is no package.
	
	<p> 
	There are now several ways to create a party of a given
	type. You can use this Tcl API with or without a form from the form
	system, or you can directly use the PL/SQL API for the party type.

	<p><b>Examples:</b>
	<pre>

	# OPTION 1: Create the party using the Tcl Procedure. Useful if the
	# only attribute you need to specify is the party name
	
	db_transaction {
	    set party_id [party::new -email "joe@foo.com" $party_type]
	}
	
	
	# OPTION 2: Create the party using the Tcl API with a templating
	# form. Useful when there are multiple attributes to specify for the
	# party
	
	template::form create add_party
	template::element create add_party email -value "joe@foo.com"
	
	db_transaction {
	    set party_id [party::new -form_id add_party $party_type ]
	}
	
	# OPTION 3: Create the party using the PL/SQL package automatically
	# created for it
	
	# creating the new party
	set party_id [db_exec_plsql add_party "
	  begin
	    :1 := ${party_type}.new (email => 'joe@foo.com');
	  end;
	"]
	
	</pre>

	@author Oumi Mehrotra (oumi@arsdigita.com)
	@creation-date 2001-02-08

	@return <code>party_id</code> of the newly created party

	@param form_id The form id from templating form system (see
	example above)

	@param email The email of this party. Note that if
	email is specified explicitly, this value will be used even if
	there is a email attribute in the form specified by
	<code>form_id</code>.

	@param party_type The type of party we are creating

    } {

	# We select out the name of the primary key. Note that the
	# primary key is equivalent to party_id as this is a subtype of
	# acs_party
		
	if { ![db_0or1row package_select {
	    select t.package_name, lower(t.id_column) as id_column
	      from acs_object_types t
	     where t.object_type = :party_type
	}] } {
	    error "Object type \"$party_type\" does not exist"
	}

	set var_list [list \
		[list context_id $context_id]  \
		[list $id_column $party_id] \
		[list "email" $email]]

	return [package_instantiate_object \
		-creation_user $creation_user \
		-creation_ip $creation_ip \
		-package_name $package_name \
		-start_with "party" \
		-var_list $var_list \
		-form_id $form_id \
		-variable_prefix $variable_prefix \
		$party_type]

    }

    ad_proc types_valid_for_rel_type_multirow {
	{-datasource_name object_types}
	{-start_with party}
	{-rel_type "membership_rel"}
    } {
	creates multirow datasource containing party types starting with
	the $start_with party type.  The datasource has columns that are 
	identical to the relation_types_allowed_to_group_multirow, which is why
	the columns are broadly named "object_*" instead of "party_*".  A 
	common template can be used for generating select widgets etc. for 
	both this datasource and the relation_types_allowed_to_groups_multirow
	datasource.

	All subtypes of $start_with are returned, but the "valid_p" column in 
	the datasource indicates whether the type is a valid one for $group_id.

	Includes fields that are useful for
	presentation in a hierarchical select widget:
	<ul>
	<li> object_type
	<li> object_type_enc - encoded object type
	<li> indent          - an html indentation string
	<li> pretty_name     - pretty name of object type
	<li> valid_p         - 1 or 0 depending on whether the type is valid
	</ul>

	@author Oumi Mehrotra (oumi@arsdigita.com)
	@creation-date 2000-02-07
    
	@param datasource_name
	@param start_with
	@param rel_type - if unspecified, then membership_rel is used 
    } {

	template::multirow create $datasource_name \
		object_type object_type_enc indent pretty_name valid_p

	# Special case "party" because we don't want to display "party" itself
	# as an option, and we don't want to display "rel_segment" as an
	# option.
	if {$start_with eq "party"} {
	    set start_with_clause [db_map start_with_clause_party]
	} else {
	    set start_with_clause [db_map start_with_clause]
	}

	db_foreach select_sub_rel_types "
	select 
	    types.pretty_name, 
	    types.object_type, 
	    types.tree_level, 
	    types.indent,
	    decode(valid_types.object_type, null, 0, 1) as valid_p
	from 
	    (select
	        t.pretty_name, t.object_type, level as tree_level,
	        replace(lpad(' ', (level - 1) * 4), 
	                ' ', '&nbsp;') as indent,
	        rownum as tree_rownum
	     from 
	        acs_object_types t
	     connect by 
	        prior t.object_type = t.supertype
	     start with 
	        $start_with_clause ) types,
	    (select 
	        object_type 
	     from 
	        rel_types_valid_obj_two_types
	     where 
	        rel_type = :rel_type ) valid_types
	where 
	    types.object_type = valid_types.object_type(+)
	order by tree_rownum
	" {
	    template::multirow append $datasource_name $object_type [ad_urlencode $object_type] $indent $pretty_name $valid_p
	}

    }
    
    ad_proc -public email {
	{-party_id:required}
    } {
	this returns the parties email. Cached
    } {
	return [util_memoize [list ::party::email_not_cached -party_id $party_id]]
    }
    
    ad_proc -private email_not_cached {
	{-party_id:required}
    } {
	this returns the contact's name
    } {
	set email [db_string get_party_email { select email from parties where party_id = :party_id } -default {}]
	return $email
    }

    ad_proc -public name {
	{-party_id ""}
	{-email ""}
    } {
	Gets the party name of the provided party_id
	
	@author Miguel Marin (miguelmarin@viaro.net)
	@author Viaro Networks www.viaro.net

	@author Malte Sussdorff (malte.sussdorff@cognovis.de)

	@param party_id The party_id to get the name from.
	@param email The email of the party

	@return The party name
    } {
	if {$party_id eq "" && $email eq ""} {
	    error "You need to provide either party_id or email"
	} elseif {"" ne $party_id && "" ne $email } {
	    error "Only provide provide party_id OR email, not both"
	}
	
	if {$party_id eq ""} {
	    set party_id [party::get_by_email -email $email]
	}

	if {[person::person_p -party_id $party_id]} {
	    set name [person::name -person_id $party_id]
	} else {
	    if { [apm_package_installed_p "organizations"] } {
		set name [db_string get_org_name {} -default ""]
	    } 
	    
	    if { $name eq "" } {
		set name [db_string get_group_name {} -default ""]
	    }

	    if { $name eq "" } {
		set name [db_string get_party_name {} -default ""]
	    }
	    
	}
	return $name
    }

    ad_proc -public party_p {
	-object_id:required
    } {
	
	@author Malte Sussdorff
	@creation-date 2007-01-26
	
	@param object_id object_id which is checked if it is a party
	@return true if object_id is a party
	
    } {
	return [db_string party_p {} -default 0]
    }
    
}
