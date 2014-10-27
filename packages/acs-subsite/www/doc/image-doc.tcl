# to regenerate images.html, use
#     tclsh image-doc.tcl > images.html
# in this directory
#
# -gn

set text {<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
 <head>
  <title>ACS Subsite Documentation</title>
 </head>

<body bgcolor="#ffffff">
<h2>Images available from the acs-subsite package</h2>

Image can be included with a link of the form &lt;img src=&quot;/resources/acs-subsite/FILENAME\" /&gt;
<table border="0">
}
foreach i [glob ../resources/*.*] {
    set name [file tail $i]
    if {[file extension $name] in {.js .css}} continue
    append text {<tr><td><img src="/resources/acs-subsite/} $name {"></td><td> } $name {</td></tr>} \n
}
append text "</table>"

puts $text
