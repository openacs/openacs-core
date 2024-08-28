#
# This file is intended to be the first *-init.tcl file to be called
# after loading the *-proc.tcl files.
#

set ::acs::kernel_id [ad_acs_kernel_id]

::acs::dc create_db_function_interface ;# -verbose ;# -match test.*
