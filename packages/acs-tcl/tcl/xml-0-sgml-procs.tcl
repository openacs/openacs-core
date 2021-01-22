ad_library {

    @original-header
# sgml.tcl --
#
#	This file provides generic parsing services for SGML-based
#	languages, namely HTML and XML.
#
#	NB.  It is a misnomer.  There is no support for parsing
#	arbitrary SGML as such.
#
# Copyright (c) 1998,1999 Zveno Pty Ltd
# http://www.zveno.com/
#
# Zveno makes this software available free of charge for any purpose.
# Copies may be made of this software but all of this notice must be included
# on any copy.
#
# The software was developed for research purposes only and Zveno does not
# warrant that it is error free or fit for any purpose.  Zveno disclaims any
# liability for all claims, expenses, losses, damages and costs any user may
# incur as a result of using, copying or modifying this software.
#
# Copyright (c) 1997 ANU and CSIRO on behalf of the
# participants in the CRC for Advanced Computational Systems ('ACSys').
# 
# ACSys makes this software and all associated data and documentation 
# ('Software') available free of charge for any purpose.  You may make copies 
# of the Software but you must include all of this notice on any copy.
# 
# The Software was developed for research purposes and ACSys does not warrant
# that it is error free or fit for any purpose.  ACSys disclaims any
# liability for all claims, expenses, losses, damages and costs any user may
# incur as a result of using, copying or modifying the Software.
#
    @cvs-id $Id$
}

package provide sgml 1.7

namespace eval sgml {
    namespace export tokenise parseEvent

    namespace export parseDTD

    # Convenience routine
    proc cl x {
	return "\[$x\]"
    }

    # Define various regular expressions

    # Character classes
    variable BaseChar \u0041-\u005A\u0061-\u007A\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u00FF\u0100-\u0131\u0134-\u013E\u0141-\u0148\u014A-\u017E\u0180-\u01C3\u01CD-\u01F0\u01F4-\u01F5\u01FA-\u0217\u0250-\u02A8\u02BB-\u02C1\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03CE\u03D0-\u03D6\u03DA\u03DC\u03DE\u03E0\u03E2-\u03F3\u0401-\u040C\u040E-\u044F\u0451-\u045C\u045E-\u0481\u0490-\u04C4\u04C7-\u04C8\u04CB-\u04CC\u04D0-\u04EB\u04EE-\u04F5\u04F8-\u04F9\u0531-\u0556\u0559\u0561-\u0586\u05D0-\u05EA\u05F0-\u05F2\u0621-\u063A\u0641-\u064A\u0671-\u06B7\u06BA-\u06BE\u06C0-\u06CE\u06D0-\u06D3\u06D5\u06E5-\u06E6\u0905-\u0939\u093D\u0958-\u0961\u0985-\u098C\u098F-\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09DC-\u09DD\u09DF-\u09E1\u09F0-\u09F1\u0A05-\u0A0A\u0A0F-\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32-\u0A33\u0A35-\u0A36\u0A38-\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8B\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2-\u0AB3\u0AB5-\u0AB9\u0ABD\u0AE0\u0B05-\u0B0C\u0B0F-\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32-\u0B33\u0B36-\u0B39\u0B3D\u0B5C-\u0B5D\u0B5F-\u0B61\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99-\u0B9A\u0B9C\u0B9E-\u0B9F\u0BA3-\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB5\u0BB7-\u0BB9\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C33\u0C35-\u0C39\u0C60-\u0C61\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CDE\u0CE0-\u0CE1\u0D05-\u0D0C\u0D0E-\u0D10\u0D12-\u0D28\u0D2A-\u0D39\u0D60-\u0D61\u0E01-\u0E2E\u0E30\u0E32-\u0E33\u0E40-\u0E45\u0E81-\u0E82\u0E84\u0E87-\u0E88\u0E8A\u0E8D\u0E94-\u0E97\u0E99-\u0E9F\u0EA1-\u0EA3\u0EA5\u0EA7\u0EAA-\u0EAB\u0EAD-\u0EAE\u0EB0\u0EB2-\u0EB3\u0EBD\u0EC0-\u0EC4\u0F40-\u0F47\u0F49-\u0F69\u10A0-\u10C5\u10D0-\u10F6\u1100\u1102-\u1103\u1105-\u1107\u1109\u110B-\u110C\u110E-\u1112\u113C\u113E\u1140\u114C\u114E\u1150\u1154-\u1155\u1159\u115F-\u1161\u1163\u1165\u1167\u1169\u116D-\u116E\u1172-\u1173\u1175\u119E\u11A8\u11AB\u11AE-\u11AF\u11B7-\u11B8\u11BA\u11BC-\u11C2\u11EB\u11F0\u11F9\u1E00-\u1E9B\u1EA0-\u1EF9\u1F00-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u2126\u212A-\u212B\u212E\u2180-\u2182\u3041-\u3094\u30A1-\u30FA\u3105-\u312C\uAC00-\uD7A3  
    variable Ideographic \u4E00-\u9FA5\u3007\u3021-\u3029
    variable CombiningChar \u0300-\u0345\u0360-\u0361\u0483-\u0486\u0591-\u05A1\u05A3-\u05B9\u05BB-\u05BD\u05BF\u05C1-\u05C2\u05C4\u064B-\u0652\u0670\u06D6-\u06DC\u06DD-\u06DF\u06E0-\u06E4\u06E7-\u06E8\u06EA-\u06ED\u0901-\u0903\u093C\u093E-\u094C\u094D\u0951-\u0954\u0962-\u0963\u0981-\u0983\u09BC\u09BE\u09BF\u09C0-\u09C4\u09C7-\u09C8\u09CB-\u09CD\u09D7\u09E2-\u09E3\u0A02\u0A3C\u0A3E\u0A3F\u0A40-\u0A42\u0A47-\u0A48\u0A4B-\u0A4D\u0A70-\u0A71\u0A81-\u0A83\u0ABC\u0ABE-\u0AC5\u0AC7-\u0AC9\u0ACB-\u0ACD\u0B01-\u0B03\u0B3C\u0B3E-\u0B43\u0B47-\u0B48\u0B4B-\u0B4D\u0B56-\u0B57\u0B82-\u0B83\u0BBE-\u0BC2\u0BC6-\u0BC8\u0BCA-\u0BCD\u0BD7\u0C01-\u0C03\u0C3E-\u0C44\u0C46-\u0C48\u0C4A-\u0C4D\u0C55-\u0C56\u0C82-\u0C83\u0CBE-\u0CC4\u0CC6-\u0CC8\u0CCA-\u0CCD\u0CD5-\u0CD6\u0D02-\u0D03\u0D3E-\u0D43\u0D46-\u0D48\u0D4A-\u0D4D\u0D57\u0E31\u0E34-\u0E3A\u0E47-\u0E4E\u0EB1\u0EB4-\u0EB9\u0EBB-\u0EBC\u0EC8-\u0ECD\u0F18-\u0F19\u0F35\u0F37\u0F39\u0F3E\u0F3F\u0F71-\u0F84\u0F86-\u0F8B\u0F90-\u0F95\u0F97\u0F99-\u0FAD\u0FB1-\u0FB7\u0FB9\u20D0-\u20DC\u20E1\u302A-\u302F\u3099\u309A
    variable Digit \u0030-\u0039\u0660-\u0669\u06F0-\u06F9\u0966-\u096F\u09E6-\u09EF\u0A66-\u0A6F\u0AE6-\u0AEF\u0B66-\u0B6F\u0BE7-\u0BEF\u0C66-\u0C6F\u0CE6-\u0CEF\u0D66-\u0D6F\u0E50-\u0E59\u0ED0-\u0ED9\u0F20-\u0F29
    variable Extender \u00B7\u02D0\u02D1\u0387\u0640\u0E46\u0EC6\u3005\u3031-\u3035\u309D-\u309E\u30FC-\u30FE
    variable Letter $BaseChar|$Ideographic

    # white space
    variable Wsp " \t\r\n"
    variable noWsp [cl ^$Wsp]

    # variable Char \x9|\xA|\xD|\[\x20-\uD7FF\]|\[\uE000-\uFFFD\]|\[\u10000-\u10FFFF\]

    # Various XML names
    variable NameChar \[-$Letter$Digit._:$CombiningChar$Extender\]
    variable Name \[_:$BaseChar$Ideographic\]$NameChar*
    variable Names ${Name}(?:$Wsp$Name)*
    variable Nmtoken $NameChar+
    variable Nmtokens ${Nmtoken}(?:$Wsp$Nmtoken)*

    # Other
    variable ParseEventNum
    if {![info exists ParseEventNum]} {
	set ParseEventNum 0
    }
    variable ParseDTDnum
    if {![info exists ParseDTDNum]} {
	set ParseDTDNum 0
    }

    # table of predefined entities for XML

    variable EntityPredef
    array set EntityPredef {
	lt <   gt >   amp &   quot \"   apos '
    }

}

# sgml::tokenise --
#
#	Transform the given HTML/XML text into a Tcl list.
#
# Arguments:
#	sgml		text to tokenize
#	elemExpr	RE to recognise tags
#	elemSub		transform for matched tags
#	args		options
#
# Valid Options:
#	-final		boolean		True if no more data is to be supplied
#	-statevariable	varName		Name of a variable used to store info
#
# Results:
#	Returns a Tcl list representing the document.

proc sgml::tokenise {sgml elemExpr elemSub args} {
    array set options {-final 1}
    catch {array set options $args}
    set options(-final) [Boolean $options(-final)]

    # If the data is not final then there must be a variable to store
    # unused data.
    if {!$options(-final) && ![info exists options(-statevariable)]} {
	return -code error {option "-statevariable" required if not final}
    }

    # Pre-process stage
    #
    # Extract the internal DTD subset, if any

    catch {upvar #0 $options(-internaldtdvariable) dtd}
    if {[regexp {<!DOCTYPE[^[<]+\[([^]]+)\]} $sgml discard dtd]} {
	regsub {(<!DOCTYPE[^[<]+)(\[[^]]+\])} $sgml {\1\&xml:intdtd;} sgml
    }

    # Protect Tcl special characters
    regsub -all {([{}\\])} $sgml {\\\1} sgml

    # Do the translation

    if {[info exists options(-statevariable)]} {
	upvar #0 $opts(-statevariable) unused
	if {[info exists unused]} {
	    regsub -all $elemExpr $unused$sgml $elemSub sgml
	    unset unused
	} else {
	    regsub -all $elemExpr $sgml $elemSub sgml
	}
	set sgml "{} {} {} \{$sgml\}"

	# Performance note (Tcl 8.0):
	#	Use of lindex, lreplace will cause parsing to list object

	if {[regexp {^([^<]*)(<[^>]*$)} [lindex $sgml end] x text unused]} {
	    set sgml [lreplace $sgml end end $text]
	}

    } else {

	# Performance note (Tcl 8.0):
	#	In this case, no conversion to list object is performed

	regsub -all $elemExpr $sgml $elemSub sgml
	set sgml "{} {} {} \{$sgml\}"
    }

    return $sgml

}

# sgml::parseEvent --
#
#	Produces an event stream for a XML/HTML document,
#	given the Tcl list format returned by tokenise.
#
#	This procedure checks that the document is well-formed,
#	and throws an error if the document is found to be not
#	well formed.  Warnings are passed via the -warningcommand script.
#
#	The procedure only check for well-formedness,
#	no DTD is required.  However, facilities are provided for entity expansion.
#
# Arguments:
#	sgml		Instance data, as a Tcl list.
#	args		option/value pairs
#
# Valid Options:
#	-final			Indicates end of document data
#	-elementstartcommand	Called when an element starts
#	-elementendcommand	Called when an element ends
#	-characterdatacommand	Called when character data occurs
#	-entityreferencecommand	Called when an entity reference occurs
#	-processinginstructioncommand	Called when a PI occurs
#	-externalentityrefcommand	Called for an external entity reference
#
#	(Not compatible with expat)
#	-xmldeclcommand		Called when the XML declaration occurs
#	-doctypecommand		Called when the document type declaration occurs
#	-commentcommand		Called when a comment occurs
#
#	-errorcommand		Script to evaluate for a fatal error
#	-warningcommand		Script to evaluate for a reportable warning
#	-statevariable		global state variable
#	-normalize		whether to normalize names
#	-reportempty		whether to include an indication of empty elements
#
# Results:
#	The various callback scripts are invoked.
#	Returns empty string.
#
# BUGS:
#	If command options are set to empty string then they should not be invoked.

proc sgml::parseEvent {sgml args} {
    variable Wsp
    variable noWsp
    variable Nmtoken
    variable Name
    variable ParseEventNum

    array set options [list \
	-elementstartcommand		[namespace current]::noop	\
	-elementendcommand		[namespace current]::noop	\
	-characterdatacommand		[namespace current]::noop	\
	-processinginstructioncommand	[namespace current]::noop	\
	-externalentityrefcommand	[namespace current]::noop	\
	-xmldeclcommand			[namespace current]::noop	\
	-doctypecommand			[namespace current]::noop	\
	-commentcommand			[namespace current]::noop	\
	-entityreferencecommand		{}				\
	-warningcommand			[namespace current]::noop	\
	-errorcommand			[namespace current]::Error	\
	-final				1				\
	-emptyelement			[namespace current]::EmptyElement	\
	-parseattributelistcommand	[namespace current]::noop	\
	-normalize			1				\
	-internaldtd			{}				\
	-reportempty			0				\
	-entityvariable			[namespace current]::EntityPredef	\
    ]
    catch {array set options $args}

    if {![info exists options(-statevariable)]} {
	set options(-statevariable) [namespace current]::ParseEvent[incr ParseEventNum]
    }

    upvar #0 $options(-statevariable) state
    upvar #0 $options(-entityvariable) entities

    if {![info exists state]} {
	# Initialise the state variable
	array set state {
	    mode normal
	    haveXMLDecl 0
	    haveDocElement 0
	    context {}
	    stack {}
	    line 0
	}
    }

    foreach {tag close param text} $sgml {

	# Keep track of lines in the input
	incr state(line) [regsub -all \n $param {} discard]
	incr state(line) [regsub -all \n $text {} discard]

	# If the current mode is cdata or comment then we must undo what the
	# regsub has done to reconstitute the data

	set empty {}
	switch $state(mode) {
	    comment {
		# This had "[string length $param] && " as a guard -
		# can't remember why :-(
		if {[regexp ([cl ^-]*)--\$ $tag discard comm1]} {
		    # end of comment (in tag)
		    set tag {}
		    set close {}
		    set state(mode) normal
		    uplevel #0 $options(-commentcommand) [list $state(commentdata)<$comm1]
		    unset state(commentdata)
		} elseif {[regexp ([cl ^-]*)--\$ $param discard comm1]} {
		    # end of comment (in attributes)
		    uplevel #0 $options(-commentcommand) [list $state(commentdata)<$close$tag>$comm1]
		    unset state(commentdata)
		    set tag {}
		    set param {}
		    set close {}
		    set state(mode) normal
		} elseif {[regexp ([cl ^-]*)-->(.*) $text discard comm1 text]} {
		    # end of comment (in text)
		    uplevel #0 $options(-commentcommand) [list $state(commentdata)<$close$tag$param>$comm1]
		    unset state(commentdata)
		    set tag {}
		    set param {}
		    set close {}
		    set state(mode) normal
		} else {
		    # comment continues
		    append state(commentdata) <$close$tag$param>$text
		    continue
		}
	    }
	    cdata {
		if {[string length $param] && [regexp ([cl ^\]]*)\]\][cl $Wsp]*\$ $tag discard cdata1]} {
		    # end of CDATA (in tag)
		    uplevel #0 $options(-characterdatacommand) [list $state(cdata)<$close$cdata1$text]
		    set text {}
		    set tag {}
		    unset state(cdata)
		    set state(mode) normal
		} elseif {[regexp ([cl ^\]]*)\]\][cl $Wsp]*\$ $param discard cdata1]} {
		    # end of CDATA (in attributes)
		    uplevel #0 $options(-characterdatacommand) [list $state(cdata)<$close$tag$cdata1$text]
		    set text {}
		    set tag {}
		    set param {}
		    unset state(cdata)
		    set state(mode) normal
		} elseif {[regexp ([cl ^\]]*)\]\][cl $Wsp]*>(.*) $text discard cdata1 text]} {
		    # end of CDATA (in text)
		    uplevel #0 $options(-characterdatacommand) [list $state(cdata)<$close$tag$param>$cdata1$text]
		    set text {}
		    set tag {}
		    set param {}
		    set close {}
		    unset state(cdata)
		    set state(mode) normal
		} else {
		    # CDATA continues
		    append state(cdata) <$close$tag$param>$text
		    continue
		}
	    }
	    default {
		# The trailing slash on empty elements can't be automatically separated out
		# in the RE, so we must do it here.
		regexp (.*)(/)[cl $Wsp]*$ $param discard param empty
	    }
	}

	# default: normal mode

	# Bug: if the attribute list has a right angle bracket then the empty
	# element marker will not be seen

	set empty [uplevel #0 $options(-emptyelement) [list $tag $param $empty]]

	switch -glob -- [string length $tag],[regexp {^\?|!.*} $tag],$close,$empty {

	    0,0,, {
		# Ignore empty tag - dealt with non-normal mode above
	    }
	    *,0,, {

		# Start tag for an element.

		# Check if the internal DTD entity is in an attribute value
		regsub -all &xml:intdtd\; $param \[$options(-internaldtd)\] param

		ParseEvent:ElementOpen $tag $param options
		set state(haveDocElement) 1

	    }

	    *,0,/, {

		# End tag for an element.

		ParseEvent:ElementClose $tag options

	    }

	    *,0,,/ {

		# Empty element

		ParseEvent:ElementOpen $tag $param options -empty 1
		ParseEvent:ElementClose $tag options -empty 1

	    }

	    *,1,* {
		# Processing instructions or XML declaration
		switch -glob -- $tag {

		    {\?xml} {
			# XML Declaration
			if {$state(haveXMLDecl)} {
			    uplevel #0 $options(-errorcommand) "unexpected characters \"<$tag\" around line $state(line)"
			} elseif {![regexp {\?$} $param]} {
			    uplevel #0 $options(-errorcommand) "XML Declaration missing characters \"?>\" around line $state(line)"
			} else {

			    # Get the version number
			    if {[regexp {[ 	]*version="(-+|[a-zA-Z0-9_.:]+)"[ 	]*} $param discard version] || [regexp {[ 	]*version='(-+|[a-zA-Z0-9_.:]+)'[ 	]*} $param discard version]} {
				if {$version ne "1.0" } {
				    # Should we support future versions?
				    # At least 1.X?
				    uplevel #0 $options(-errorcommand) "document XML version \"$version\" is incompatible with XML version 1.0"
				}
			    } else {
				uplevel #0 $options(-errorcommand) "XML Declaration missing version information around line $state(line)"
			    }

			    # Get the encoding declaration
			    set encoding {}
			    regexp {[ 	]*encoding="([A-Za-z]([A-Za-z0-9._]|-)*)"[ 	]*} $param discard encoding
			    regexp {[ 	]*encoding='([A-Za-z]([A-Za-z0-9._]|-)*)'[ 	]*} $param discard encoding

			    # Get the standalone declaration
			    set standalone {}
			    regexp {[ 	]*standalone="(yes|no)"[ 	]*} $param discard standalone
			    regexp {[ 	]*standalone='(yes|no)'[ 	]*} $param discard standalone

			    # Invoke the callback
			    uplevel #0 $options(-xmldeclcommand) [list $version $encoding $standalone]

			}

		    }

		    {\?*} {
			# Processing instruction
			if {![regsub {\?$} $param {} param]} {
			    uplevel #0 $options(-errorcommand) "PI: expected '?' character around line $state(line)"
			} else {
			    uplevel #0 $options(-processinginstructioncommand) [list [string range $tag 1 end] [string trimleft $param]]
			}
		    }

		    !DOCTYPE {
			# External entity reference
			# This should move into xml.tcl
			# Parse the params supplied.  Looking for Name, ExternalID and MarkupDecl
			set matched [regexp ^[cl $Wsp]*($Name)[cl $Wsp]*(.*) $param x state(doc_name) param]
			set state(doc_name) [Normalize $state(doc_name) $options(-normalize)]
			set externalID {}
			set pubidlit {}
			set systemlit {}
			set externalID {}
			if {[regexp -nocase ^[cl $Wsp]*(SYSTEM|PUBLIC)(.*) $param x id param]} {
			    switch [string toupper $id] {
				SYSTEM {
				    if {[regexp ^[cl $Wsp]+"([cl ^"]*)"(.*) $param x systemlit param] || [regexp ^[cl $Wsp]+'([cl ^']*)'(.*) $param x systemlit param]} {
					set externalID [list SYSTEM $systemlit] ;# "
				    } else {
					uplevel #0 $options(-errorcommand) {{syntax error: SYSTEM identifier not followed by literal}}
				    }
				}
				PUBLIC {
				    if {[regexp ^[cl $Wsp]+"([cl ^"]*)"(.*) $param x pubidlit param] || [regexp ^[cl $Wsp]+'([cl ^']*)'(.*) $param x pubidlit param]} {
					if {[regexp ^[cl $Wsp]+"([cl ^"]*)"(.*) $param x systemlit param] || [regexp ^[cl $Wsp]+'([cl ^']*)'(.*) $param x systemlit param]} {
					    set externalID [list PUBLIC $pubidlit $systemlit]
					} else {
					    uplevel #0 $options(-errorcommand) "syntax error: PUBLIC identifier not followed by system literal around line $state(line)"
					}
				    } else {
					uplevel #0 $options(-errorcommand) "syntax error: PUBLIC identifier not followed by literal around line $state(line)"
				    }
				}
			    }
			    if {[regexp -nocase ^[cl $Wsp]+NDATA[cl $Wsp]+($Name)(.*) $param x notation param]} {
				lappend externalID $notation
			    }
			}

			uplevel #0 $options(-doctypecommand) [list $state(doc_name) $pubidlit $systemlit $options(-internaldtd)]

		    }

		    !--* {

			# Start of a comment
			# See if it ends in the same tag, otherwise change the
			# parsing mode

			regexp {!--(.*)} $tag discard comm1
			if {[regexp ([cl ^-]*)--[cl $Wsp]*\$ $comm1 discard comm1_1]} {
			    # processed comment (end in tag)
			    uplevel #0 $options(-commentcommand) [list $comm1_1]
			} elseif {[regexp ([cl ^-]*)--[cl $Wsp]*\$ $param discard comm2]} {
			    # processed comment (end in attributes)
			    uplevel #0 $options(-commentcommand) [list $comm1$comm2]
			} elseif {[regexp ([cl ^-]*)-->(.*) $text discard comm2 text]} {
			    # processed comment (end in text)
			    uplevel #0 $options(-commentcommand) [list $comm1$param$empty>$comm2]
			} else {
			    # start of comment
			    set state(mode) comment
			    set state(commentdata) "$comm1$param$empty>$text"
			    continue
			}
		    }

		    {!\[CDATA\[*} {

			regexp {!\[CDATA\[(.*)} $tag discard cdata1
			if {[regexp {(.*)]]$} $param discard cdata2]} {
			    # processed CDATA (end in attribute)
			    uplevel #0 $options(-characterdatacommand) [list $cdata1$cdata2$text]
			    set text {}
			} elseif {[regexp {(.*)]]>(.*)} $text discard cdata2 text]} {
			    # processed CDATA (end in text)
			    uplevel #0 $options(-characterdatacommand) [list $cdata1$param$empty>$cdata2$text]
			    set text {}
			} else {
			    # start CDATA
			    set state(cdata) "$cdata1$param>$text"
			    set state(mode) cdata
			    continue
			}

		    }

		    !ELEMENT {
			# Internal DTD declaration
		    }
		    !ATTLIST {
		    }
		    !ENTITY {
		    }
		    !NOTATION {
		    }

		    !* {
			uplevel #0 $options(-processinginstructioncommand) [list $tag $param]
		    }
		    default {
			uplevel #0 $options(-errorcommand) [list "unknown processing instruction \"<$tag>\" around line $state(line)"]
		    }
		}
	    }
	    *,1,* -
	    *,0,/,/ {
		# Syntax error
	    	uplevel #0 $options(-errorcommand) [list [list syntax error: closed/empty tag: tag $tag param $param empty $empty close $close around line $state(line)]]
	    }
	}

	# Process character data

	if {$state(haveDocElement) && [llength $state(stack)]} {

	    # Check if the internal DTD entity is in the text
	    regsub -all &xml:intdtd\; $text \[$options(-internaldtd)\] text

	    # Look for entity references
	    if {([array size entities] || [string length $options(-entityreferencecommand)]) 
                && [regexp {&[^;]+;} $text]
            } {

		# protect Tcl specials
		regsub -all {([][$\\])} $text {\\\1} text
		# Mark entity references
		regsub -all {&([^;]+);} $text [format {%s; %s {\1} ; %s %s} \}\} [namespace code [list Entity options $options(-entityreferencecommand) $options(-characterdatacommand) $options(-entityvariable)]] [list uplevel #0 $options(-characterdatacommand)] \{\{] text
		set text "uplevel #0 $options(-characterdatacommand) {{$text}}"
		eval $text
	    } else {
		# Restore protected special characters
		regsub -all {\\([{}\\])} $text {\1} text
		uplevel #0 $options(-characterdatacommand) [list $text]
	    }
	} elseif {[string length [string trim $text]]} {
	    uplevel #0 $options(-errorcommand) "unexpected text \"$text\" in document prolog around line $state(line)"
	}

    }

    # If this is the end of the document, close all open containers
    if {$options(-final) && [llength $state(stack)]} {
	eval $options(-errorcommand) [list [list element [lindex $state(stack) end] remains unclosed around line $state(line)]]
    }

    return {}
}

# sgml::ParseEvent:ElementOpen --
#
#	Start of an element.
#
# Arguments:
#	tag	Element name
#	attr	Attribute list
#	opts	Option variable in caller
#	args	further configuration options
#
# Options:
#	-empty boolean
#		indicates whether the element was an empty element
#
# Results:
#	Modify state and invoke callback

proc sgml::ParseEvent:ElementOpen {tag attr opts args} {
    variable Name
    variable Wsp

    upvar $opts options
    upvar #0 $options(-statevariable) state
    array set cfg {-empty 0}
    array set cfg $args

    if {$options(-normalize)} {
	set tag [string toupper $tag]
    }

    # Update state
    lappend state(stack) $tag

    # Parse attribute list into a key-value representation
    if {[string compare $options(-parseattributelistcommand) {}]} {
	if {[catch {uplevel #0 $options(-parseattributelistcommand) [list $attr]} attr]} {
	    if {[lindex $attr 0] ne "unterminated attribute value" } {
		uplevel #0 $options(-errorcommand) [list $attr around line $state(line)]
		set attr {}
	    } else {

		# It is most likely that a ">" character was in an attribute value.
		# This manifests itself by ">" appearing in the element's text.
		# In this case the callback should return a three element list;
		# the message "unterminated attribute value", the attribute list it
		# did manage to parse and the remainder of the attribute list.

		lassign $attr msg attlist brokenattr

		upvar text elemText
		if {[string first > $elemText] >= 0} {

		    # Now piece the attribute list back together
		    regexp ($Name)[cl $Wsp]*=[cl $Wsp]*("|')(.*) $brokenattr discard attname delimiter attvalue
		    regexp (.*)>([cl ^>]*)\$ $elemText discard remattlist elemText
		    regexp ([cl ^$delimiter]*)${delimiter}(.*) $remattlist discard remattvalue remattlist

		    append attvalue >$remattvalue
		    lappend attlist $attname $attvalue

		    # Complete parsing the attribute list
		    if {[catch {uplevel #0 $options(-parseattributelistcommand) [list $remattlist]} attr]} {
			uplevel #0 $options(-errorcommand) [list $attr around line $state(line)]
			set attr {}
			set attlist {}
		    } else {
			lappend attlist {*}$attr
		    }

		    set attr $attlist

		} else {
		    uplevel #0 $options(-errorcommand) [list $attr around line $state(line)]
		    set attr {}
		}
	    }
	}
    }

    set empty {}
    if {$cfg(-empty) && $options(-reportempty)} {
	set empty {-empty 1}
    }

    # Invoke callback
    uplevel #0 $options(-elementstartcommand) [list $tag $attr] $empty

    return {}
}

# sgml::ParseEvent:ElementClose --
#
#	End of an element.
#
# Arguments:
#	tag	Element name
#	opts	Option variable in caller
#	args	further configuration options
#
# Options:
#	-empty boolean
#		indicates whether the element as an empty element
#
# Results:
#	Modify state and invoke callback

proc sgml::ParseEvent:ElementClose {tag opts args} {
    upvar $opts options
    upvar #0 $options(-statevariable) state
    array set cfg {-empty 0}
    array set cfg $args

    # WF check
    if {$tag ne [lindex $state(stack) end] } {
	uplevel #0 $options(-errorcommand) [list "end tag \"$tag\" does not match open element \"[lindex $state(stack) end]\" around line $state(line)"]
	return
    }

    # Update state
    set state(stack) [lreplace $state(stack) end end]

    set empty {}
    if {$cfg(-empty) && $options(-reportempty)} {
	set empty {-empty 1}
    }

    # Invoke callback
    uplevel #0 $options(-elementendcommand) [list $tag] $empty

    return {}
}

# sgml::Normalize --
#
#	Perform name normalization if required
#
# Arguments:
#	name	name to normalize
#	req	normalization required
#
# Results:
#	Name returned as upper-case if normalization required

proc sgml::Normalize {name req} {
    if {$req} {
	return [string toupper $name]
    } else {
	return $name
    }
}

# sgml::Entity --
#
#	Resolve XML entity references (syntax: &xxx;).
#
# Arguments:
#	opts		options array variable in caller
#	entityrefcmd	application callback for entity references
#	pcdatacmd	application callback for character data
#	entities	name of array containing entity definitions.
#	ref		entity reference (the "xxx" bit)
#
# Results:
#	Returns substitution text for given entity.

proc sgml::Entity {opts entityrefcmd pcdatacmd entities ref} {
    upvar 2 $opts options
    upvar #0 $options(-statevariable) state

    if {$entities eq ""} {
	set entities [namespace current]::EntityPredef
    }

    switch -glob -- $ref {
	%* {
	    # Parameter entity - not recognised outside of a DTD
	}
	#x* {
	    # Character entity - hex
	    if {[catch {format %c [scan [string range $ref 2 end] %x tmp; set tmp]} char]} {
		return -code error "malformed character entity \"$ref\""
	    }
	    uplevel #0 $pcdatacmd [list $char]

	    return {}

	}
	#* {
	    # Character entity - decimal
	    if {[catch {format %c [scan [string range $ref 1 end] %d tmp; set tmp]} char]} {
		return -code error "malformed character entity \"$ref\""
	    }
	    uplevel #0 $pcdatacmd [list $char]

	    return {}

	}
	default {
	    # General entity
	    upvar #0 $entities map
	    if {[info exists map($ref)]} {

		if {![regexp {<|&} $map($ref)]} {

		    # Simple text replacement - optimise

		    uplevel #0 $pcdatacmd [list $map($ref)]

		    return {}

		}

		# Otherwise an additional round of parsing is required.
		# This only applies to XML, since HTML doesn't have general entities

		# Must parse the replacement text for start & end tags, etc
		# This text must be self-contained: balanced closing tags, and so on

		set tokenised [tokenise $map($ref) $::xml::tokExpr $::xml::substExpr]
		set final $options(-final)
		unset options(-final)
		eval parseEvent [list $tokenised] [array get options] -final 0
		set options(-final) $final

		return {}

	    } elseif {[string length $entityrefcmd]} {

		uplevel #0 $entityrefcmd [list $ref]

		return {}

	    }
	}
    }

    # If all else fails leave the entity reference untouched
    uplevel #0 $pcdatacmd [list &$ref\;]

    return {}
}

####################################
#
# DTD parser for SGML (XML).
#
# This DTD actually only handles XML DTDs.  Other language's
# DTD's, such as HTML, must be written in terms of a XML DTD.
#
# A DTD is represented as a three element Tcl list.
# The first element contains the content models for elements,
# the second contains the attribute lists for elements and
# the last element contains the entities for the document.
#
####################################

# sgml::parseDTD --
#
#	Entry point to the SGML DTD parser.
#
# Arguments:
#	dtd	data defining the DTD to be parsed
#	args	configuration options
#
# Results:
#	Returns a three element list, first element is the content model
#	for each element, second element are the attribute lists of the
#	elements and the third element is the entity map.

proc sgml::parseDTD {dtd args} {
    variable Wsp
    variable ParseDTDnum

    array set opts [list \
	-errorcommand		[namespace current]::noop \
	state			[namespace current]::parseDTD[incr ParseDTDnum]
    ]
    array set opts $args

    set exp <!([cl ^$Wsp>]+)[cl $Wsp]*([cl ^$Wsp]+)[cl $Wsp]*([cl ^>]*)>
    set sub {{\1} {\2} {\3} }
    regsub -all $exp $dtd $sub dtd

    foreach {decl id value} $dtd {
	catch {DTD:[string toupper $decl] $id $value} err
    }

    return [list [array get contentmodel] [array get attributes] [array get entities]]
}

# Procedures for handling the various declarative elements in a DTD.
# New elements may be added by creating a procedure of the form
# parse:DTD:_element_

# For each of these procedures, the various regular expressions they use
# are created outside of the proc to avoid overhead at runtime

# sgml::DTD:ELEMENT --
#
#	<!ELEMENT ...> defines an element.
#
#	The content model for the element is stored in the contentmodel array,
#	indexed by the element name.  The content model is parsed into the
#	following list form:
#
#		{}	Content model is EMPTY.
#			Indicated by an empty list.
#		*	Content model is ANY.
#			Indicated by an asterix.
#		{ELEMENT ...}
#			Content model is element-only.
#		{MIXED {element1 element2 ...}}
#			Content model is mixed (PCDATA and elements).
#			The second element of the list contains the 
#			elements that may occur.  #PCDATA is assumed 
#			(ie. the list is normalised).
#
# Arguments:
#	id	identifier for the element.
#	value	other information in the PI

proc sgml::DTD:ELEMENT {id value} {
    dbgputs DTD_parse [list DTD:ELEMENT $id $value]
    variable Wsp
    upvar opts state
    upvar contentmodel cm

    if {[info exists cm($id)]} {
	eval $state(-errorcommand) element [list "element \"$id\" already declared"]
    } else {
	switch -- $value {
	    EMPTY {
	    	set cm($id) {}
	    }
	    ANY {
	    	set cm($id) *
	    }
	    default {
		if {[regexp [format {^\([%s]*#PCDATA[%s]*(\|([^)]+))?[%s]*\)*[%s]*$} $Wsp $Wsp $Wsp $Wsp] discard discard mtoks]} {
		    set cm($id) [list MIXED [split $mtoks |]]
		} else {
		    if {[catch {CModelParse $state(state) $value} result]} {
			eval $state(-errorcommand) element [list $result]
		    } else {
			set cm($id) [list ELEMENT $result]
		    }
		}
	    }
	}
    }
}

# sgml::CModelParse --
#
#	Parse an element content model (non-mixed).
#	A syntax tree is constructed.
#	A transition table is built next.
#
#	This is going to need a lot of work!
#
# Arguments:
#	state	state array variable
#	value	the content model data
#
# Results:
#	A Tcl list representing the content model.

proc sgml::CModelParse {state value} {
    upvar #0 $state var

    # First build syntax tree
    set syntaxTree [CModelMakeSyntaxTree $state $value]

    # Build transition table
    set transitionTable [CModelMakeTransitionTable $state $syntaxTree]

    return [list $syntaxTree $transitionTable]
}

# sgml::CModelMakeSyntaxTree --
#
#	Construct a syntax tree for the regular expression.
#
#	Syntax tree is represented as a Tcl list:
#	rep {:choice|:seq {{rep list1} {rep list2} ...}}
#	where:	rep is repetition character, *, + or ?. {} for no repetition
#		listN is nested expression or Name
#
# Arguments:
#	spec	Element specification
#
# Results:
#	Syntax tree for element spec as nested Tcl list.
#
#	Examples:
#	(memo)
#		{} {:seq {{} memo}}
#	(front, body, back?)
#		{} {:seq {{} front} {{} body} {? back}}
#	(head, (p | list | note)*, div2*)
#		{} {:seq {{} head} {* {:choice {{} p} {{} list} {{} note}}} {* div2}}
#	(p | a | ul)+
#		+ {:choice {{} p} {{} a} {{} ul}}

proc sgml::CModelMakeSyntaxTree {state spec} {
    upvar #0 $state var
    variable Wsp
    variable name

    # Translate the spec into a Tcl list.

    # None of the Tcl special characters are allowed in a content model spec.
    if {[regexp {\$|\[|\]|\{|\}} $spec]} {
	return -code error "illegal characters in specification"
    }

    regsub -all [format {(%s)[%s]*(\?|\*|\+)?[%s]*(,|\|)?} $name $Wsp $Wsp] $spec [format {%sCModelSTname %s {\1} {\2} {\3}} \n $state] spec
    regsub -all {\(} $spec "\nCModelSTopenParen $state " spec
    regsub -all [format {\)[%s]*(\?|\*|\+)?[%s]*(,|\|)?} $Wsp $Wsp] $spec [format {%sCModelSTcloseParen %s {\1} {\2}} \n $state] spec

    array set var {stack {} state start}
    eval $spec

    # Peel off the outer seq, its redundant
    return [lindex $var(stack) 1 0]
}

# sgml::CModelSTname --
#
#	Processes a name in a content model spec.
#
# Arguments:
#	state	state array variable
#	name	name specified
#	rep	repetition operator
#	cs	choice or sequence delimiter
#
# Results:
#	See CModelSTcp.

proc sgml::CModelSTname {state name rep cs args} {
    if {[llength $args]} {
	return -code error "syntax error in specification: \"$args\""
    }

    CModelSTcp $state $name $rep $cs
}

# sgml::CModelSTcp --
#
#	Process a content particle.
#
# Arguments:
#	state	state array variable
#	name	name specified
#	rep	repetition operator
#	cs	choice or sequence delimiter
#
# Results:
#	The content particle is added to the current group.

proc sgml::CModelSTcp {state cp rep cs} {
    upvar #0 $state var

    switch -glob -- [lindex $var(state) end]=$cs {
	start= {
	    set var(state) [lreplace $var(state) end end end]
	    # Add (dummy) grouping, either choice or sequence will do
	    CModelSTcsSet $state ,
	    CModelSTcpAdd $state $cp $rep
	}
	:choice= -
	:seq= {
	    set var(state) [lreplace $var(state) end end end]
	    CModelSTcpAdd $state $cp $rep
	}
	start=| -
	start=, {
	    set var(state) [lreplace $var(state) end end [expr {$cs eq "," ? ":seq" : ":choice"}]]
	    CModelSTcsSet $state $cs
	    CModelSTcpAdd $state $cp $rep
	}
	:choice=| -
	:seq=, {
	    CModelSTcpAdd $state $cp $rep
	}
	:choice=, -
	:seq=| {
	    return -code error "syntax error in specification: incorrect delimiter after \"$cp\", should be \"[expr {$cs eq "," ? "|" : ","}]\""
	}
	end=* {
	    return -code error "syntax error in specification: no delimiter before \"$cp\""
	}
	default {
	    return -code error "syntax error"
	}
    }
    
}

# sgml::CModelSTcsSet --
#
#	Start a choice or sequence on the stack.
#
# Arguments:
#	state	state array
#	cs	choice oir sequence
#
# Results:
#	state is modified: end element of state is appended.

proc sgml::CModelSTcsSet {state cs} {
    upvar #0 $state var

    set cs [expr {$cs eq "," ? ":seq" : ":choice"}]

    if {[llength $var(stack)]} {
	set var(stack) [lreplace $var(stack) end end $cs]
    } else {
	set var(stack) [list $cs {}]
    }
}

# sgml::CModelSTcpAdd --
#
#	Append a content particle to the top of the stack.
#
# Arguments:
#	state	state array
#	cp	content particle
#	rep	repetition
#
# Results:
#	state is modified: end element of state is appended.

proc sgml::CModelSTcpAdd {state cp rep} {
    upvar #0 $state var

    if {[llength $var(stack)]} {
	set top [lindex $var(stack) end]
    	lappend top [list $rep $cp]
	set var(stack) [lreplace $var(stack) end end $top]
    } else {
	set var(stack) [list $rep $cp]
    }
}

# sgml::CModelSTopenParen --
#
#	Processes a '(' in a content model spec.
#
# Arguments:
#	state	state array
#
# Results:
#	Pushes stack in state array.

proc sgml::CModelSTopenParen {state args} {
    upvar #0 $state var

    if {[llength $args]} {
	return -code error "syntax error in specification: \"$args\""
    }

    lappend var(state) start
    lappend var(stack) [list {} {}]
}

# sgml::CModelSTcloseParen --
#
#	Processes a ')' in a content model spec.
#
# Arguments:
#	state	state array
#	rep	repetition
#	cs	choice or sequence delimiter
#
# Results:
#	Stack is popped, and former top of stack is appended to previous element.

proc sgml::CModelSTcloseParen {state rep cs args} {
    upvar #0 $state var

    if {[llength $args]} {
	return -code error "syntax error in specification: \"$args\""
    }

    set cp [lindex $var(stack) end]
    set var(stack) [lreplace $var(stack) end end]
    set var(state) [lreplace $var(state) end end]
    CModelSTcp $state $cp $rep $cs
}

# sgml::CModelMakeTransitionTable --
#
#	Given a content model's syntax tree, constructs
#	the transition table for the regular expression.
#
#	See "Compilers, Principles, Techniques, and Tools",
#	Aho, Sethi and Ullman.  Section 3.9, algorithm 3.5.
#
# Arguments:
#	state	state array variable
#	st	syntax tree
#
# Results:
#	The transition table is returned, as a key/value Tcl list.

proc sgml::CModelMakeTransitionTable {state st} {
    upvar #0 $state var

    # Construct nullable, firstpos and lastpos functions
    array set var {number 0}
    foreach {nullable firstpos lastpos} [	\
	TraverseDepth1st $state $st {
	    # Evaluated for leaf nodes
	    # Compute nullable(n)
	    # Compute firstpos(n)
	    # Compute lastpos(n)
	    set nullable [nullable leaf $rep $name]
	    set firstpos [list {} $var(number)]
	    set lastpos [list {} $var(number)]
	    set var(pos:$var(number)) $name
	} {
	    # Evaluated for nonterminal nodes
	    # Compute nullable, firstpos, lastpos
	    set firstpos [firstpos $cs $firstpos $nullable]
	    set lastpos  [lastpos  $cs $lastpos  $nullable]
	    set nullable [nullable nonterm $rep $cs $nullable]
	}	\
    ] break

    set accepting [incr var(number)]
    set var(pos:$accepting) #

    # var(pos:N) maps from position to symbol.
    # Construct reverse map for convenience.
    # NB. A symbol may appear in more than one position.
    # var is about to be reset, so use different arrays.

    foreach {pos symbol} [array get var pos:*] {
	set pos [lindex [split $pos :] 1]
	set pos2symbol($pos) $symbol
	lappend sym2pos($symbol) $pos
    }

    # Construct the followpos functions
    catch {unset var}
    followpos $state $st $firstpos $lastpos

    # Construct transition table
    # Dstates is [union $marked $unmarked]
    set unmarked [list [lindex $firstpos 1]]
    while {[llength $unmarked]} {
	set T [lindex $unmarked 0]
	lappend marked $T
	set unmarked [lrange $unmarked 1 end]

	# Find which input symbols occur in T
	set symbols {}
	foreach pos $T {
	    if {$pos != $accepting && [lsearch $symbols $pos2symbol($pos)] < 0} {
		lappend symbols $pos2symbol($pos)
	    }
	}
	foreach a $symbols {
	    set U {}
	    foreach pos $sym2pos($a) {
		if {[lsearch $T $pos] >= 0} {
		    # add followpos($pos)
	    	    if {$var($pos) == {}} {
	    	    	lappend U $accepting
	    	    } else {
	    	    	lappend U {*}$var($pos)
	    	    }
		}
	    }
	    set U [makeSet $U]
	    if {[llength $U] && [lsearch $marked $U] < 0 && [lsearch $unmarked $U] < 0} {
		lappend unmarked $U
	    }
	    set Dtran($T,$a) $U
	}
	
    }

    return [list [array get Dtran] [array get sym2pos] $accepting]
}

# sgml::followpos --
#
#	Compute the followpos function, using the already computed
#	firstpos and lastpos.
#
# Arguments:
#	state		array variable to store followpos functions
#	st		syntax tree
#	firstpos	firstpos functions for the syntax tree
#	lastpos		lastpos functions
#
# Results:
#	followpos functions for each leaf node, in name/value format

proc sgml::followpos {state st firstpos lastpos} {
    upvar #0 $state var

    switch -- [lindex $st 1 0] {
	:seq {
	    for {set i 1} {$i < [llength [lindex $st 1]]} {incr i} {
	    	followpos $state [lindex $st 1 $i]	\
			[lindex $firstpos 0 $i-1]	\
			[lindex $lastpos 0 $i-1]
	    	foreach pos [lindex $lastpos 0 $i-1 1] {
		    lappend var($pos) {*}[lindex $firstpos 0 $i 1]
		    set var($pos) [makeSet $var($pos)]
	    	}
	    }
	}
	:choice {
	    for {set i 1} {$i < [llength [lindex $st 1]]} {incr i} {
		followpos $state [lindex $st 1 $i]	\
			[lindex $firstpos 0 $i-1]	\
			[lindex $lastpos 0 $i-1]
	    }
	}
	default {
	    # No action at leaf nodes
	}
    }

    switch -- [lindex $st 0] {
	? {
	    # We having nothing to do here ! Doing the same as
	    # for * effectively converts this qualifier into the other.
	}
	* {
	    foreach pos [lindex $lastpos 1] {
		lappend var($pos) {*}[lindex $firstpos 1]
		set var($pos) [makeSet $var($pos)]
	    }
	}
    }

}

# sgml::TraverseDepth1st --
#
#	Perform depth-first traversal of a tree.
#	A new tree is constructed, with each node computed by f.
#
# Arguments:
#	state	state array variable
#	t	The tree to traverse, a Tcl list
#	leaf	Evaluated at a leaf node
#	nonTerm	Evaluated at a nonterminal node
#
# Results:
#	A new tree is returned.

proc sgml::TraverseDepth1st {state t leaf nonTerm} {
    upvar #0 $state var

    set nullable {}
    set firstpos {}
    set lastpos {}

    switch -- [lindex $t 1 0] {
	:seq -
	:choice {
	    set rep [lindex $t 0]
	    set cs [lindex $t 1 0]

	    foreach child [lrange [lindex $t 1] 1 end] {
		foreach {childNullable childFirstpos childLastpos} \
			[TraverseDepth1st $state $child $leaf $nonTerm] break
		lappend nullable $childNullable
		lappend firstpos $childFirstpos
		lappend lastpos  $childLastpos
	    }

	    eval $nonTerm
	}
	default {
	    incr var(number)
	    set rep [lindex $t 0 0]
	    set name [lindex $t 1 0]
	    eval $leaf
	}
    }

    return [list $nullable $firstpos $lastpos]
}

# sgml::firstpos --
#
#	Computes the firstpos function for a nonterminal node.
#
# Arguments:
#	cs		node type, choice or sequence
#	firstpos	firstpos functions for the subtree
#	nullable	nullable functions for the subtree
#
# Results:
#	firstpos function for this node is returned.

proc sgml::firstpos {cs firstpos nullable} {
    switch -- $cs {
	:seq {
	    set result [lindex $firstpos 0 1]
	    for {set i 0} {$i < [llength $nullable]} {incr i} {
	    	if {[lindex $nullable $i 1]} {
	    	    lappend result {*}[lindex $firstpos $i+1 1]
		} else {
		    break
		}
	    }
	}
	:choice {
	    foreach child $firstpos {
		lappend result {*}$child
	    }
	}
    }

    return [list $firstpos [makeSet $result]]
}

# sgml::lastpos --
#
#	Computes the lastpos function for a nonterminal node.
#	Same as firstpos, only logic is reversed
#
# Arguments:
#	cs		node type, choice or sequence
#	lastpos		lastpos functions for the subtree
#	nullable	nullable functions forthe subtree
#
# Results:
#	lastpos function for this node is returned.

proc sgml::lastpos {cs lastpos nullable} {
    switch -- $cs {
	:seq {
	    set result [lindex $lastpos end 1]
	    for {set i [expr {[llength $nullable] - 1}]} {$i >= 0} {incr i -1} {
		if {[lindex $nullable $i 1]} {
		    lappend result {*}[lindex $lastpos $i 1]
		} else {
		    break
		}
	    }
	}
	:choice {
	    foreach child $lastpos {
		lappend result {*}$child
	    }
	}
    }

    return [list $lastpos [makeSet $result]]
}

# sgml::makeSet --
#
#	Turn a list into a set, ie. remove duplicates.
#
# Arguments:
#	s	a list
#
# Results:
#	A set is returned, which is a list with duplicates removed.

proc sgml::makeSet s {
    foreach r $s {
	if {[llength $r]} {
	    set unique($r) {}
	}
    }
    return [array names unique]
}

# sgml::nullable --
#
#	Compute the nullable function for a node.
#
# Arguments:
#	nodeType	leaf or nonterminal
#	rep		repetition applying to this node
#	name		leaf node: symbol for this node, nonterm node: choice or seq node
#	subtree		nonterm node: nullable functions for the subtree
#
# Results:
#	Returns nullable function for this branch of the tree.

proc sgml::nullable {nodeType rep name {subtree {}}} {
    switch -glob -- $rep:$nodeType {
	:leaf -
	+:leaf {
	    return [list {} 0]
	}
	\\*:leaf -
	\\?:leaf {
	    return [list {} 1]
	}
	\\*:nonterm -
	\\?:nonterm {
	    return [list $subtree 1]
	}
	:nonterm -
	+:nonterm {
	    switch -- $name {
		:choice {
		    set result 0
		    foreach child $subtree {
			set result [expr {$result || [lindex $child 1]}]
		    }
		}
		:seq {
		    set result 1
		    foreach child $subtree {
			set result [expr {$result && [lindex $child 1]}]
		    }
		}
	    }
	    return [list $subtree $result]
	}
    }
}

# These regular expressions are defined here once for better performance

namespace eval sgml {
    variable Wsp

    # Watch out for case-sensitivity

    set attlist_exp [cl $Wsp]*([cl ^$Wsp]+)[cl $Wsp]*([cl ^$Wsp]+)[cl $Wsp]*(#REQUIRED|#IMPLIED)
    set attlist_enum_exp [cl $Wsp]*([cl ^$Wsp]+)[cl $Wsp]*\\(([cl ^)]*)\\)[cl $Wsp]*("([cl ^")])")? ;# "
    set attlist_fixed_exp [cl $Wsp]*([cl ^$Wsp]+)[cl $Wsp]*([cl ^$Wsp]+)[cl $Wsp]*(#FIXED)[cl $Wsp]*([cl ^$Wsp]+)

    set param_entity_exp [cl $Wsp]*([cl ^$Wsp]+)[cl $Wsp]*([cl ^"$Wsp]*)[cl $Wsp]*"([cl ^"]*)"

    set notation_exp [cl $Wsp]*([cl ^$Wsp]+)[cl $Wsp]*(.*)

}

# sgml::DTD:ATTLIST --
#
#	<!ATTLIST ...> defines an attribute list.
#
# Arguments:
#	id	Element an attribute list is being defined for.
#	value	data from the PI.
#
# Results:
#	Attribute list variables are modified.

proc sgml::DTD:ATTLIST {id value} {
    variable attlist_exp
    variable attlist_enum_exp
    variable attlist_fixed_exp
    dbgputs DTD_parse [list DTD:ATTLIST $id $value]
    upvar opts state
    upvar attributes am

    if {[info exists am($id)]} {
	eval $state(-errorcommand) attlist [list "attribute list for element \"$id\" already declared"]
    } else {
	# Parse the attribute list.  If it were regular, could just use foreach,
	# but some attributes may have values.
	regsub -all {([][$\\])} $value {\\\1} value
	regsub -all $attlist_exp $value {[DTDAttribute {\1} {\2} {\3}]} value
	regsub -all $attlist_enum_exp $value {[DTDAttribute {\1} {\2} {\3}]} value
	regsub -all $attlist_fixed_exp $value {[DTDAttribute {\1} {\2} {\3} {\4}]} value
	subst $value
	set am($id) [array get attlist]
    }
}

# sgml::DTDAttribute --
#
#	Parse definition of a single attribute.
#
# Arguments:
#	name	attribute name
#	type	type of this attribute
#	default	default value of the attribute
#	value	other information

proc sgml::DTDAttribute {name type default {value {}}} {
    upvar attlist al
    # This needs further work
    set al($name) [list $default $value]
}

# sgml::DTD:ENTITY --
#
#	<!ENTITY ...> PI
#
# Arguments:
#	id	identifier for the entity
#	value	data
#
# Results:
#	Modifies the caller's entities array variable

proc sgml::DTD:ENTITY {id value} {
    variable param_entity_exp
    dbgputs DTD_parse [list DTD:ENTITY $id $value]
    upvar opts state
    upvar entities ents

    if {"%" ne $id } {
	# Entity declaration
	if {[info exists ents($id)]} {
	    eval $state(-errorcommand) entity [list "entity \"$id\" already declared"]
	} else {
	    if {![regexp {"([^"]*)"} $value x entvalue] && ![regexp {'([^']*)'} $value x entvalue]} {
		eval $state(-errorcommand) entityvalue [list "entity value \"$value\" not correctly specified"]
	    } ;# "
	    set ents($id) $entvalue
	}
    } else {
	# Parameter entity declaration
	switch -glob [regexp $param_entity_exp $value x name scheme data],[string compare {} $scheme] {
	    0,* {
		eval $state(-errorcommand) entityvalue [list "parameter entity \"$value\" not correctly specified"]
	    }
	    *,0 {
	    	# SYSTEM or PUBLIC declaration
	    }
	    default {
	    	set ents($id) $data
	    }
	}
    }
}

# sgml::DTD:NOTATION --

proc sgml::DTD:NOTATION {id value} {
    variable notation_exp
    upvar opts state

    if {[regexp $notation_exp $value x scheme data] == 2} {
    } else {
	eval $state(-errorcommand) notationvalue [list "notation value \"$value\" incorrectly specified"]
    }
}

### Utility procedures

# sgml::noop --
#
#	A do-nothing proc
#
# Arguments:
#	args	arguments
#
# Results:
#	Nothing.

proc sgml::noop args {
    return 0
}

# sgml::identity --
#
#	Identity function.
#
# Arguments:
#	a	arbitrary argument
#
# Results:
#	$a

proc sgml::identity a {
    return $a
}

# sgml::Error --
#
#	Throw an error
#
# Arguments:
#	args	arguments
#
# Results:
#	Error return condition.

proc sgml::Error args {
    uplevel return -code error [list $args]
}

### Following procedures are based on html_library

# sgml::zapWhite --
#
#	Convert multiple white space into a single space.
#
# Arguments:
#	data	plain text
#
# Results:
#	As above

proc sgml::zapWhite data {
    regsub -all "\[ \t\r\n\]+" $data { } data
    return $data
}

proc sgml::Boolean value {
    regsub {1|true|yes|on} $value 1 value
    regsub {0|false|no|off} $value 0 value
    return $value
}

proc sgml::dbgputs {where text} {
    variable dbg

    catch {if {$dbg} {puts stdout "DBG: $where ($text)"}}
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
