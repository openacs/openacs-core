ReturnHeaders text/plain

proc ns_walk {ns n} { 
    set nsp [namespace eval $ns {info procs}]
    set bytes 0
    foreach ::p $nsp { 
        incr bytes [string bytelength [namespace eval $ns {info body $::p}]]
    }
    ns_write "[format "%7d" $bytes] [string repeat " " $n]$ns ([llength $nsp])\n"
    set kids [namespace children $ns]
    foreach nsc $kids { 
        incr bytes [ns_walk $nsc [expr $n + 1]]
    } 
    return $bytes
}    
             
ns_write "Total: [ns_walk :: 0]"
