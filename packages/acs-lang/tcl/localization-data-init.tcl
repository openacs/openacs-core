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
