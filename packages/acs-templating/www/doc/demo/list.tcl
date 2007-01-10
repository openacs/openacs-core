ad_page_contract {
    set up a list for demonstrating the <list> tag.
} -properties {
    factorial:onevalue
}
# should be onelist, but ad_page_contract does not understand that

for {set f 1; set n 1} {$n < 12} {incr n} {
    lappend factorial [set f [expr {$f*$n}]]
}
