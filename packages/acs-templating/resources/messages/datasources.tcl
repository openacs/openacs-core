# code_stub should be set

set code [template::util::read_file $code_stub.tcl]

template::get_datasources $code

