#/packages/lang/tcl/localization-data-init.tcl
ad_library {

    Database required for localization routines
    Currently only supports five locales (US, UK, France, Spain and Germany).
    Add new entries to support additional locales.

    @creation-date 10 September 2000
    @author Jeff Davis (davis@xarg.net)
    @cvs-id $Id$
}

# Monetary amounts
# number after money: is interpreted like this:
# 
#   first digit: currency symbol position: 
#      0 = currency symbol after amount
#      1 = currency symbol before amount
#
#   second digit: position of sign
#      0 = wrap number in parenthesis, no sign symbol
#      1 = sign symbol precedes number and currency symbol
#      2 = sign symbol follows number and currency symbol
#      3 = sign comes before the currency symbol
#      4 = sign comes after the currency symbol
#
#   third digit: space separation
#      0 = no space
#      1 = there's a space somewhere
#      2 = there's a space somewhere
#
#      TODO: Ask Jeff
#      It looks like the logic *should* be that 1 means a space in the first position,
#      2 is a space in the second position, but that's not what the table below does
#

nsv_set locale money:000  {($num$sym)}
nsv_set locale money:001  {($num $sym)}
nsv_set locale money:002  {($num$sym)} 
nsv_set locale money:010  {$sign$num$sym}
nsv_set locale money:011  {$sign$num $sym}
nsv_set locale money:012  {$sign$num $sym} 
nsv_set locale money:020  {$num$sym$sign}
nsv_set locale money:021  {$num $sym$sign}
nsv_set locale money:022  {$num$sym $sign}
nsv_set locale money:030  {$num$sign$sym}
nsv_set locale money:031  {$num $sign$sym}
nsv_set locale money:032  {$num$sign $sym}
nsv_set locale money:040  {$num$sym$sign}
nsv_set locale money:041  {$num $sym$sign}
nsv_set locale money:042  {$num$sym $sign}
nsv_set locale money:100  {($sym$num)}
nsv_set locale money:101  {($sym$num)}
nsv_set locale money:102  {($sym$num)}
nsv_set locale money:110  {$sign$sym$num}
nsv_set locale money:111  {$sign$sym$num}
nsv_set locale money:112  {$sign$sym$num} 
nsv_set locale money:120  {$sym$num$sign}
nsv_set locale money:121  {$sym$num$sign}
nsv_set locale money:122  {$sym$num$sign} 
nsv_set locale money:130  {$sign$sym$num}
nsv_set locale money:131  {$sign$sym$num}
nsv_set locale money:132  {$sign$sym$num} 
nsv_set locale money:140  {$sym$sign$num}
nsv_set locale money:141  {$sym$sign$num}
nsv_set locale money:142  {$sym$sign$num} 

namespace eval ::lang::util {
    variable percent_match

    # Date format codes.  This was brought over from lc_time_fmt, to avoid having to rebuild the
    # array each time the procedure is called, which is often.

    # AG: FOR BUGFREE OPERATION it's important that variable names get
    # properly delimited.  This is not usually a problem because most
    # of the assignments occur in square brackets where spaces are
    # allowed.  But it can be a problem with array values that are set
    # to single variables.  Example:
    #
    #   Bad:      set percent_match(Y) {$lc_time_year}
    #   Good:     set percent_match(Y) {${lc_time_year}}
    #
    # The error trigger is: message catalog messages that don't have any
    # whitespace between the variable name and other parts of the message.  In
    # this case the lc_time_fmt_compile function may return expressions where
    # the variable name is appended to by the message catalog contents,
    # resulting in variables that look like this: $lc_time_year\345\271\264
    # Tcl will throw an error when it encounters undefined variables.

    # Unsupported number things
    set percent_match(W) ""
    set percent_match(U) ""
    set percent_match(u) ""
    set percent_match(j) ""
    
    # Composites, now directly expanded, note that writing for %r specifically would be quicker than what we have here.
    set percent_match(T) {[lc_leading_zeros $lc_time_hours 2]:[lc_leading_zeros $lc_time_minutes 2]:[lc_leading_zeros $lc_time_seconds 2]}
    set percent_match(D) {[lc_leading_zeros $lc_time_days 2]/[lc_leading_zeros $lc_time_month 2]/[lc_leading_zeros [expr {$lc_time_year%100}] 2]}
    set percent_match(F) {${lc_time_year}-[lc_leading_zeros $lc_time_month 2]-[lc_leading_zeros $lc_time_days 2]}
    set percent_match(r) {[lc_leading_zeros [lc_time_drop_meridian $lc_time_hours] 2]:[lc_leading_zeros $lc_time_minutes 2] [lc_time_name_meridian $locale $lc_time_hours]}
    
    # Direct Subst
    set percent_match(e) {[lc_leading_space $lc_time_days]}
    set percent_match(E) {[lc_leading_space $lc_time_month]}
    set percent_match(f) {[lc_wrap_sunday $lc_time_day_no]}
    set percent_match(Y) {${lc_time_year}}

    # Plus padding
    set percent_match(d) {[lc_leading_zeros $lc_time_days 2]}
    set percent_match(H) {[lc_leading_zeros $lc_time_hours 2]}
    set percent_match(S) {[lc_leading_zeros $lc_time_seconds 2]}
    set percent_match(m) {[lc_leading_zeros $lc_time_month 2]}
    set percent_match(M) {[lc_leading_zeros $lc_time_minutes 2]}

    # Calculable values (based on assumptions above)
    set percent_match(C) {[expr {int($lc_time_year/100)}]}
    set percent_match(I) {[lc_leading_zeros [lc_time_drop_meridian $lc_time_hours] 2]}
    set percent_match(w) {[expr {$lc_time_day_no}]}
    set percent_match(y) {[lc_leading_zeros [expr {$lc_time_year%100}] 2]}
    set percent_match(Z) [lang::conn::timezone]

    # Straight (localian) lookups
    set percent_match(a) {[lindex [lc_get -locale $locale "abday"] $lc_time_day_no]}
    set percent_match(A) {[lindex [lc_get -locale $locale "day"] $lc_time_day_no]}
    set percent_match(b) {[lindex [lc_get -locale $locale "abmon"] $lc_time_month-1]}
    set percent_match(h) {[lindex [lc_get -locale $locale "abmon"] $lc_time_month-1]}
    set percent_match(B) {[lindex [lc_get -locale $locale "mon"] $lc_time_month-1]}
    set percent_match(p) {[lc_time_name_meridian $locale $lc_time_hours]}

    # Finally, static string replacements
    set percent_match(t) {\t}
    set percent_match(n) {\n}
    set percent_match(%) {%}
}
