# Data sources for an individual procedure:

# The input to this procedure should be a pre-parsed chunk of data
# from Tcl code representing the complete documentation for a single
# procedure.

# The pre-parse chunk should have the form:

# { { info in list form } { params in list form } \
#   { options in list form } { see also in list form } }

# this is only for parsing the URL request string

#template::request create -params {
#    info -datatype text
#    param -datatype text
#    option -datatype text
#    see -datatype text
#}


# @datasource info onerow
# Basic procedure information
# @column author Name and e-mail address of author
# @column description Description of procedure
# @column return Return value of procedure

array set info [lindex $data 0] 

# @datasource params multirow
# Required parameters to the procedure
# @column name Parameter name
# @column default Default parameter value
# @column description Description of parameter

util::list_to_multirow params [lindex $data 1]

# @datasource options multirow
# Optional parameters to the procedure (specified with leading dashes)
# @column name Option name
# @column default Default option value
# @column description Description of option

util::list_to_multirow options [lindex $data 2]

# @datasource see multirow
# References to other procedures or namespaces
# @column name Name of procedure or namespace
# @column type Type of reference (procedure, namespace, or arbitrary URL)
# @column url URL of reference

util::list_to_multirow see [lindex $data 3]

set required_marker "<font color='red'>*</font>"






# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
