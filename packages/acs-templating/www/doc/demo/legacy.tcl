set text "This is a traditional Tcl page that builds up HTML in "

append text "procedural code and returns it at the end."

ns_return 200 text/html $text
