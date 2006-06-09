# 

ad_library {
    
    Tests for adp parsing
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-01-01
    @arch-tag: bc76f9ce-ed1c-49dd-a3be-617d5a78c838
    @cvs-id $Id$
}

aa_register_case template_variable {
    test adp variable parsing procedures
} {
    aa_run_with_teardown \
        -test_code {
            set code "=@test_array.test_key@"
            aa_true "Regular array var name detected" [regexp [template::adp_array_variable_regexp] $code discard pre arr var]
            aa_true "Preceding char is '${pre}'" [string equal "=" $pre]
            aa_true "Array name is '${arr}'" \
                [string equal "test_array" $arr]
            aa_true "Variable name is '${var}'" \
                [string equal "test_key" $var]

            set code "=@formerror.test_array.test_key@"
            aa_true "Formerror regular array var name detected" [regexp [template::adp_array_variable_regexp] $code discard pre arr var]
            aa_true "Preceding char is '${pre}'" [string equal "=" $pre]
            aa_true "Array name is '${arr}'" \
                [string equal "formerror" $arr]
            aa_true "Variable name is '${var}'" \
                [string equal "test_array.test_key" $var]            

            set code "=@test_array.test_key;noquote@"
            aa_true "Noquote array var name detected" [regexp [template::adp_array_variable_regexp_noquote] $code discard pre arr var]
            aa_true "Preceding char is '${pre}'" [string equal "=" $pre]
            aa_true "Array name is '${arr}'" \
                [string equal "test_array" $arr]
            aa_true "Variable name is '${var}'" \
                [string equal "test_key" $var]

            set code "=@formerror.test_array.test_key;noquote@"
            aa_true "Noquote formerror array var name detected" [regexp [template::adp_array_variable_regexp_noquote] $code discard pre arr var]
            aa_true "Preceding char is '${pre}'" [string equal "=" $pre]
            aa_true "Array name is '${arr}'" \
                [string equal "formerror" $arr]
            aa_true "Variable name is '${var}'" \
                [string equal "test_array.test_key" $var]
            
            
        }
}

aa_register_case -cats {api smoke} tcl_to_sql_list {
    Tests the tcl_to_sql_list proc.

    @author Torben Brosten
} {
    aa_equals "parses list of 0 items" [template::util::tcl_to_sql_list [list]] ""
    aa_equals "parses list of 2 or more" [template::util::tcl_to_sql_list [list isn't hess' 'bit 'trippy']] "'isn''t', 'hess''', '''bit', '''trippy'''"

}

aa_register_case -cats {api smoke} expand_percentage_signs {
    Test expand percentage signs to make sure it substitures correctly
    
    @author Dave Bauer
    @creation-date 2005-11-20
} {
    set orig_message "Test message %one%"
    set one "\[__does_not_exist__\]"
    set message $orig_message

    aa_false "Expanded square bracket text" [catch {set expanded_message [template::expand_percentage_signs $message]} errmsg]
    aa_log $errmsg
    aa_equals "square brackets safe" $expanded_message "Test message \[__does_not_exist__\]"
    
    set one "\$__does_not_exist"
    aa_false "Expanded dollar test" [catch {set expanded_message [template::expand_percentage_signs $message]} errmsg]
    aa_log $errmsg
    aa_equals "dollar sign safe" $expanded_message "Test message \$__does_not_exist"

    set one "\$two(\$three(\[__does_not_exist\]))"

    aa_false "Square bracket in array key test" [catch {set expanded_message [template::expand_percentage_signs $message]} errmsg]
    aa_log $errmsg
    aa_equals "square brackets in array key safe" $expanded_message "Test message \$two(\$three(\[__does_not_exist\]))"
   
}

aa_register_case -cats {api smoke} tcl_to_sql_list {
    Tests the tcl_to_sql_list proc.

    @author Torben Brosten
} {
    aa_equals "parses list of 0 items" [template::util::tcl_to_sql_list [list]] ""
    aa_equals "parses list of 2 or more" [template::util::tcl_to_sql_list [list isn't hess' 'bit 'trippy']] "'isn''t', 'hess''', '''bit', '''trippy'''"

}

aa_register_case -cats {api smoke} expand_percentage_signs {
    Test expand percentage signs to make sure it substitures correctly
    
    @author Dave Bauer
    @creation-date 2005-11-20
} {
    set orig_message "Test message %one%"
    set one "\[__does_not_exist__\]"
    set message $orig_message

    aa_false "Expanded square bracket text" [catch {set expanded_message [template::expand_percentage_signs $message]} errmsg]
    aa_log $errmsg
    aa_equals "square brackets safe" $expanded_message "Test message \[__does_not_exist__\]"
    
    set one "\$__does_not_exist"
    aa_false "Expanded dollar test" [catch {set expanded_message [template::expand_percentage_signs $message]} errmsg]
    aa_log $errmsg
    aa_equals "dollar sign safe" $expanded_message "Test message \$__does_not_exist"

    set one "\$two(\$three(\[__does_not_exist\]))"

    aa_false "Square bracket in array key test" [catch {set expanded_message [template::expand_percentage_signs $message]} errmsg]
    aa_log $errmsg
    aa_equals "square brackets in array key safe" $expanded_message "Test message \$two(\$three(\[__does_not_exist\]))"
   
}
