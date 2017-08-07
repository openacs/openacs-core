# @onerow namespace, with columns name, overview, author
# @multirow see_info
# @column name
# @column type 
# @column url 

array set namespace $data
set namespace(url) [doc::util::dbl_colon_fix $namespace(name)]

template::util::list_to_multirow see_info $namespace(see)





# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
