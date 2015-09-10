# suppose this template was obtained from a database query
set template "
  @name@ ordered
  <ul><list name='food'><li>@food:item@</list></li>\n</ul>"

set code [adp_compile -string $template]; 	# compile the template

set name John
set food [list "potato salad" "penne all' arrabiata" "steak" "baked alaska"]
adp_eval code;					# running code sets __adp_ouput
lappend body $__adp_output

set name Jill
set food [list "chilled sea food" "soup"]
adp_eval code;			        	# run compiled template again
lappend body $__adp_output

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
