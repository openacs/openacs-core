ad_page_contract {
  test the <if> tag
} -properties {
  x:onevalue
  y:onevalue
} -query {
  {x:integer 10}
  {y ""}
  {z:optional}
}

# manually construct a multirow datasource v
set v:rowcount 1
set v:1(rownum) 1
set v:1(five) 5

# don't define z

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
