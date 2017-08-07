

# @datasource name onevalue
# your name

# @datasource address onevalue
# @datasource home_number onevalue
# @datasource work_number onevalue
# @datasource people onevalue
# @datasource email onevalue
# your email address 

# @datasource time_periods onevalue
# units by which you measure the period of time required to make this page

# @datasource friends multirow
# a list of friends and their vital stats
# @column first_names friend's first and middle names
# @column last_name this is straightforward enough
# @column age
# @column gender column will contain one of three values: "m" for male, "f" 
# for female or an empty string
# @column address
# @column likes_chocolate_p either "t" for chocolate-lovers, "f" for choco-phobes
# and an empty string if I don't know  
# @column email friend's email address 

# @datasource movies multirow
# information and comments on movies you've recently seen
# @column title 
# @column director
# @column cast a text string listing cast members
# @column year release year
# @column comments a short blurb reviewing the movie


# This is a simple, sample .tcl page that sets the variables you'll be using 
# in your template.  If you wish, you can change the values of those variables
# in this page.


# First, let's set the name variable, which can be displayed in your template using 
# the @name@ marker

#if {![info exists name] || $name eq ""} {
    set name "(Your Name)"
#}

set title "$name"
append title "'s Personal Web Page"


# And here are a few other variables to play with:
set address "2311 LeConte Berkeley, California 94709"

set home_number "510-555-5555"
set work_number "510-555-5556"
set email "youremail@you.com"

set time_periods "months"

# create the multirow variables


# Now, let's set a list variable containing a few dummy values

set hobbies [list "listening to Ricky Martin 'cuz he's awsome!" \
	"hanging out with my best buds" \
	"telling jokes -- my friends say I've got a great sense of humor!"]

db_multirow friends get_friends ""

#template::multirow create foo_multirow columns1 columns2 columns3
template::multirow extend friends extra_column

for {set i 1} {$i <= ${friends:rowcount}} {incr i} {
  set row friends:$i
  set ${row}(extra_column) "hey there"
}

set friends:1(extra_column) "${friends:1(first_names)} is da bomb totally"

template::multirow foreach friends {
    set friends.extra_column "@friends.first_names@ is a good person"
}

template::multirow extend friends another_column

template::multirow foreach friends {
  if {[info exists friends.extra_column]} {
    set friends.another_column "there is stuff in dere"
  } else {
    set friends.another_column "no stuff in dere"
  }
}


if {![info exists header]} {
    set header ""
}





# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
