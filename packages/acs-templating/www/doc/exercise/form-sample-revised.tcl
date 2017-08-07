
form create add_entry -elements {
    first_names -html { size 30 } -label "First Name" -datatype text
    last_name -html { size 30 } -label "Last Name" -datatype text
    title -label "Title" -datatype text -widget select -optional -options {{Mr. Mr.} {Mrs. Mrs.} {Ms. Ms.} {Dr. Dr.}}
    birthday -label "Birthday" -datatype date -widget date -format "MONTH DD, YYYY" -optional
    gender -label "Gender" -datatype text -widget radio -options { {male m} {female f}}
    address -html { size 40 } -label "Address" -optional -datatype text
    city -html { size 30 } -label "City" -optional -datatype text
    state -html { size 3 maxlength 2 } -label "State" -optional -datatype keyword \
	-validate { {expr [string length $value ] == 2 } {Entry for tate must be two characters in length } }
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
    ns_log error "now we've gotten past the if statement"

    db_dml insert_address -bind [ns_getform] "
      insert into 
        address_book
      values (
        :first_names, :last_name, :title, null, :gender, :address, :city, :state, :zip, :country,
          :email, :relationship, :primary_phone, :home, :work, :cell, :pager, :fax
      )"
 
    template::forward index.html
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
