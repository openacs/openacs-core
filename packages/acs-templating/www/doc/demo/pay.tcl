form create pay_bill -section required -elements {
  payee -label "Payee" -datatype text -widget text 
  amount -label "Amount" -datatype integer -widget text 
} 
template::form::section pay_bill optional
template::element::create pay_bill note -label "Note" -datatype text -widget text -optional

    

# check if this is the initial submission or the confirmation page
if { [ns_queryexists form:confirm] } {

    # do the dml and forward

    # ns_ora dml ...

    template::forward index.html

}

if { [form is_valid pay_bill] } {

  # use the form export proc (in form-procs.tcl) to capture all the form data
  # as hidden elements
  set confirm_data [form export]

  # add the form:confirm element
  append confirm_data "<input type=hidden name=\"form:confirm\" value=confirm>"

  template::set_file "[file dir $__adp_stub]/pay-confirm"
}
