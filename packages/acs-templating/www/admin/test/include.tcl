if {[llength $l]} {
    set car		[lindex $l 0]
    set cdr		[lrange $l 1 end]
  
    regsub -all {%([a-zA-Z0-9.:_]+)%} $car {@\1@}     condition
    foreach {name rules} {
	true  {"TRUE " ""      FALSE   not                 }
	false { TRUE   not    "FALSE " ""   and %AND%   or and   %AND% or}
    } { # note that this cannot correctly reverse and/or mixes (no grouping)
	set ${name}_condition $condition
	foreach {from to} $rules {
	    regsub -all $from [set ${name}_condition] $to ${name}_condition
	}
	regsub -all \
	    {@([^@ ]+@)} [set ${name}_condition] {@<%%>\1} ${name}_label
    }

    set lt "<"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
