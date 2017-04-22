# @datasource address multirow
# a listing of address book entries
# @column first_names
# @column last_name
# @column title 
# title by which this person is to be addressed
# @column birthday
# birthdate, actually
# @column gender
# again, "m" for lads "f" for lassies
# @column address
# street address of residence or work
# @column city
# @column state
# @column zip
# @column country
# @column email
# @column relation_types
# a space-separated list of keywords indicating types of relation;
# values include "relative" "friend" "business" and "paramour"
# @column home_phone 
# @column work_phone
# @column cell_phone
# @column pager
# @column fax
# @column primary_phone
# a text string indicating which type of phone serves as the entry 
# subject's primary mode of telephone contact

# @data_input add_entry form
# a form for entering address book entries
# @input first_names text
# @input last_name text
# @input title text form of address for entry subject
# @input birthday date birthdate w/ "MONTH DD YYYY" format
# @input gender radio

# @datasource num_rows onevalue
# the maximum number of rows to show on the page, default value is 10

# @datasource start_row onevalue
# the rownumber on which the address listing should start; default 1

# @datasource next_set onevalue
# the rownumber at which the following set of unlisted rows begins;
# if there are no unlisted rows, next_set is an empty string

# @datasource previous_set onevalue
# the rownumber at which the previous set of unlisted rows begins;
# if start_row already equals 1, than this is an empty string

# @datasource last_set onevalue
# the rownumber at which the last set of unlisted rows begins;
# if the last row is already in display, than contains an empty string

set start_row [ns_queryget start_row]

if { $start_row eq "" } {
    set start_row 1
}

if {![info exists num_rows] || [string trim $num_rows] ne ""} {
  set num_rows 5
}


form create add_entry -elements {
    first_names -html { size 30 } -label "First Name" -datatype text
    last_name -html { size 30 } -label "Last Name" -datatype text
    title -label "Title" -datatype text -widget select -optional -options {{Mr. Mr.} {Mrs. Mrs.} {Ms. Ms.} {Dr. Dr.} }
    birthday -label "Birthday" -datatype date -widget date -format "MONTH DD, YYYY" -optional
    gender -label "Gender" -datatype text -widget radio -options { {male m} {female f}}
    address -html { size 40 } -label "Address" -optional -datatype text
    city -html { size 30 } -label "City" -optional -datatype text
    state -html { size 3 maxlength 2 } -label "State" -optional -datatype keyword \
	-validate { {expr [string length $value ] ==  2 } {Entry for tate must be two characters in length } }
    zip -html { size 10 } -label "Zip" -optional -datatype text
    country  -html { size 30 } -label "Country" -optional -datatype text
    email -html { size 30 } -label "Email" -optional -datatype text
    relationship -label "Type of acquaintance" -datatype text -widget checkbox -optional \
	-options { {relative relative} {friend friend} {{business acquaintance} business} {paramour paramour}}
    home -html { size 12 } -label "Home phone" -optional -datatype text
    work -html { size 12 } -label "Work" -optional -datatype text
    cell -html { size 12 } -label "Cell" -optional -datatype text
    pager -html { size 12 } -label "Pager" -optional -datatype text
    fax -html { size 12 } -label "Fax" -optional -datatype text
    primary_phone -label "Primary phone" -datatype text -widget radio -options { {home home}\
	    {work work} {cell cell} {pager pager} {fax fax}} -optional
}
    
if {[form is_request add_entry]} {
  ns_log error "this is a request for add_entry"
}


if { [form is_valid add_entry] } {

    [template::form get_values add_entry birthday]
   
    db_dml insert_form -bind [ns_getform] "
      insert into 
        address_book
      values (
        :first_names, :last_name, :title, 
          '[template::util::date get_property sql_date $birthday]',
          :gender, :address, :city, :state, :zip, :country,
          :email, :relationship, :primary_phone, :home, :work, :cell, :pager, :fax
      )"

    # can't seem to get orable to bind array variables birthday.day, birthday.month and birthday.year
    # okay, turns out oracle doesn't support arrays, will have to do this in Tcl first
 
    template::forward form-sample.acs
}

db_multirow address get_address ""

set rowcount [set address:rowcount]

if { $rowcount > $start_row + $num_rows } {
    set next_set [expr {$start_row + $num_rows}]
} else {
    set next_set ""
}

if { $start_row > 1 } {
    set previous_set [expr {$start_row - $num_rows}]
} else {
    set previous_set ""
}

if { $previous_set < 1} {
    set previous_set 1 
}

if {$rowcount > $next_set + $num_rows} {
    set last_set [expr {$rowcount - ($rowcount % $num_rows)}]
} else {
    set last_set ""
}






# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
