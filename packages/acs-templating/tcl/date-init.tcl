# branimir: (triggered while fixing bug# 1176) this used to be called at the
# end of date-procs.tcl It broke down when we started to internationalize it
# because messages hadn't been loaded at that point. Now we are loading
# messages right before executing *.-init.tcl files so things will work.

# Initialize the months array 

template::util::date::init

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
