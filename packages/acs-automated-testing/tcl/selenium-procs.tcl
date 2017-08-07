# selenium.tcl
#
#       This code implements a driver to control Selenium, an open source
#       test tool for web applications, see http://selenium.openqa.org/
#
#       This code is modeled after the Python and Ruby drivers.  It differs
#       by not implementing each supported command separately, but instead
#       using a default dispatch to pass commands to the Selenium server with
#       very little modification.  This is why the commands are not called
#       get_title, wait_for_page_to_load, etc. but with the same "camelCase"
#       names used by Selenium itself, i.e. getTitle, waitForPageToLoad, etc.
#
#       All commands known to return a list are singled out and their return
#       string is converted before returning the result.  Since everything is
#       a string in Tcl, no special handling is needed for numbers and booleans
#       (boolean results will be the same as in Selenium, i.e. "true"/"false").
#
# Note: This code requires a new HTTP/1.1 aware version of geturl - the current
#       http 2.4 package in Tcl doesn't know how to keep a 1.1 connection alive
#       and will slow down because *each* Selenium request will time out.
#       
# Example use:
#
#       package require selenium
#       
#       Se init localhost 4444 *firefox http://www.google.com/webhp
#       Se start
#       
#       Se open http://www.google.com/webhp
#       Se type q "hello world"
#       Se clickAndWait btnG
#       Se assertTitle "hello world - Google Search"
#       
#       Se stop
#
# by Jean-Claude Wippler, 2007-02-24

source [file dirname [info script]]/http.tcl
package require http

package provide selenium 0.1

proc Se {cmd args} {
    global selenium
    switch -- $cmd {
        
        init {
            set selenium(host) [lindex $args 0]
            set selenium(port) [lindex $args 1]
            set selenium(browserStartCommand) [lindex $args 2]
            set selenium(browserURL) [lindex $args 3]
            set selenium(sessionId) ""
        }
        
        start {
            set selenium(sessionId) [Se getNewBrowserSession \
                                        $selenium(browserStartCommand) \
                                        $selenium(browserURL)]
        }
        
        stop {
            Se testComplete
            set selenium(sessionId) ""
        }
        
        default {
            set query [list http::formatQuery cmd $cmd]
            set i 0
            foreach arg $args {
                lappend query [incr i] $arg
            }
            if {$selenium(sessionId) ne ""} {
                lappend query sessionId $selenium(sessionId)
            }
            set url "http://$selenium(host):$selenium(port)"
            append url /selenium-server/driver/? [eval $query]
            #puts "url $url"
            set token [http::geturl $url]
            #puts " status [http::status $token] code [http::code $token]"
            set data [http::data $token]
            #puts " result: $data"
            http::cleanup $token
            if {[string range $data 0 1] ne "OK"} {
                error $data
            }
            switch -- $cmd {
                getSelectedLabels -
                getSelectedValues -
                getSelectedIndexes -
                getSelectedIds -
                getSelectOptions -
                getAllButtons -
                getAllLinks -
                getAllFields -
                getAttributeFromAllWindows -
                getAllWindowIds -
                getAllWindowNames -
                getAllWindowTitles {
                    set token ""
                    set tokens {}
                    set escape 0
                    foreach letter [split $data ""] {
                        if {$escape} {
                            append token $letter
                            set escape 0
                        } else {
                            switch -- $letter {
                                \\      { set escape 1 }
                                ,       { lappend tokens $token; set token "" }
                                default { append token $letter }
                            }
                        }
                    }
                    lappend tokens $token
                    return [lrange $tokens 1 end]       ;# drop the "OK" element
                }
                default {
                    return [string range $data 3 end]   ;# drop the "OK," prefix
                }
            }
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
