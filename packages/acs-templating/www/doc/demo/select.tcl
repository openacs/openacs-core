form create car_opts

element create car_opts extras \
 -label "Car Accessories" -datatype text -widget multiselect \
 -options {
    {{Power Windows} windows} 
    {{Anti-Lock Brakes} brakes} 
    {{AI Alarm System} alarm}
    {{Rocket Laucnher} rocket}
 }

element create car_opts payment \
 -label "Payment Type" -datatype text -widget select \
 -options {{Cash cash} {{ATM Card} atm} {{Credit Card} credit}}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
