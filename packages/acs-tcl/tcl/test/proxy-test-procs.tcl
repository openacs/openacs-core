ad_library {

    Tests for proxy procs.

    @author Nathan Coulter ncoulter@wu.ac.at
    @creation-date 2021-03-18
}

aa_register_case \
    -cats {api smoke} -procs {
    proxy::exec
} exec_binary_input {
    When the encoding is iso8859-1, Tcl's exec does not do line
    translation.  the exec wrapper should be sensitive to this.  Use a
    temporary file to work around the fact that there is no way to
    disable line translation on the result of [exec].
} {
    set tclsh ${::env(HOME)}/bin/tclsh
    set data0 [encoding convertto utf-8 зайчик]

    set chan [file tempfile filename]
    chan configure $chan -translation binary
    try {
        if {[catch {
            set encoding [encoding system]
            try {
                encoding system iso8859-1
                ::proxy::exec -call [list $tclsh - << "
						chan configure stdin -translation binary
						# assume tclsh now reads the rest of this script in binary mode
						chan configure stdout -translation binary
						puts -nonewline stdout [list $data0]
					" >> [list $filename]]
            } finally {
                encoding system $encoding
            }
        } cres copts]} {
            regsub -all {[^[:print:]]} $cres ? cres
            regsub -all {[^[:print:]]} $copts ? copts
            return -options $copts $cres
        }
        set data1 [read $chan]
    } finally {
        close $chan
        file delete $filename
    }

    binary scan $data0 H* data0hex
    binary scan $data1 H* data1hex

    aa_equals data $data1hex $data0hex
}


