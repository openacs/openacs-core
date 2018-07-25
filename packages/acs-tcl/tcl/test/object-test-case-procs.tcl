ad_library {
    
    @author byron Haroldo Linares Roman (bhlr@galileo.edu)
    @creation-date 2006-08-11
    @cvs-id $Id$
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        acs_object::get
        acs_object::get_element
        acs_object::set_context_id
    } acs_object_procs_test \
    {
	test the acs_object::* procs
    } {

	set pretty_name [ad_generate_random_string]
	set object_type [string tolower $pretty_name]
	set name_method "${object_type}.name"
	set creation_user [ad_conn user_id]
	set creation_ip [ad_conn peeraddr]
	set context_id  [ad_conn package_id]
	set context_id2 [apm_package_id_from_key "acs-tcl"]
	set the_id [db_nextval acs_object_id_seq]
	aa_run_with_teardown -test_code {  

	    if {[db_name] eq "PostgreSQL"} {
		set type_create_sql "select acs_object_type__create_type (
					      :object_type,
					      :pretty_name,
					      :pretty_name,
					      'acs_object',
					      null,
					      null,
					      null,
					      'f',
					      null,
					      :name_method);"
	
		set new_type_sql "select acs_object__new (
				 :the_id,
				 :object_type,
				 now(),
				 :creation_user,
				 :creation_ip,
				 :context_id
				 );"
		set object_del_sql "select acs_object__delete(:the_id)"
		set type_drop_sql "select acs_object_type__drop_type(
 								     :object_type,
 								     't'
								     )"
	    } else {
		# oracle
		set type_create_sql "begin 
		acs_object_type.create_type (
			object_type => :object_type,
			pretty_name => :pretty_name,
			pretty_plural => :pretty_name,
			supertype => 'acs_object',
			abstract_p => 'f',
			name_method => :name_method);
                end;"
	
		set new_type_sql "begin 
                :1 := acs_object.new (
			object_id => :the_id,
			object_type => :object_type,
			creation_user => :creation_user,
			creation_ip => :creation_ip,
			context_id => :context_id);
                end;"

		set object_del_sql "begin
                  acs_object.del(:the_id);
                  end;"

		set type_drop_sql "begin
                  acs_object_type.drop_type(object_type => :object_type);
                  end;"
	    }




	    aa_log "test object_type $object_type :: $context_id2"

	    db_exec_plsql type_create $type_create_sql
	
	    set the2_id [db_exec_plsql new_type $new_type_sql]
	    
	   acs_object::get -object_id $the_id -array array
	   
	   aa_true "object_id $the_id :: $array(object_id)" \
		[string match $the_id $array(object_id)]
	   
	   aa_true "object_type $object_type :: $array(object_type)" \
		[string match $object_type $array(object_type)]
	   
	   aa_true "context_id $context_id :: $array(context_id)" \
		[string match $context_id $array(context_id)]
        
	   aa_true \
		"creation_user $creation_user :: [acs_object::get_element -object_id $the_id -element creation_user]" \
		[string match $creation_user [acs_object::get_element \
						  -object_id $the_id \
						  -element creation_user]]
	   aa_true \
		"creation_ip $creation_ip :: [acs_object::get_element -object_id $the_id -element creation_ip]" \
	   [string match $creation_ip [acs_object::get_element \
					    -object_id $the_id \
					    -element creation_ip]]

	    acs_object::set_context_id -object_id $the_id \
		-context_id $context_id2
	    
	    aa_true \
		"context_id $context_id2 :: [acs_object::get_element -object_id $the_id -element  context_id]" \
	    [string match $context_id2 [acs_object::get_element \
                                            -object_id $the_id \
                                            -element context_id]]
								  

 	} -teardown_code {

	    db_exec_plsql object_del $object_del_sql
	    db_exec_plsql type_drop $type_drop_sql
	}
    }



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
