# @datasource users multirow
# Complete list of sample users
# @column first_name First name of the user.
# @column last_name Last name of the user.


db_multirow users get_users {
    select last_name, first_name, first_name || ' ' || last_name as full_name from ad_template_sample_users
}  { 
    set full_name "${last_name}, $first_name" 
}

# Manually access the datasource 

# Get the size
set size [multirow size users]

# Access one column
set very_last_name [multirow get users $size last_name]

# Access one row
multirow get users $size
set last_first_name $users(first_name)

# Mutate a row
multirow set users $size last_name "(Classified)"


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
