ReturnHeaders text/plain
foreach {k v} [nsv_array get ds_request] {
    lappend d [list $k $v]
}
foreach x [lsort $d] { 
    ns_write "$x\n"
}
