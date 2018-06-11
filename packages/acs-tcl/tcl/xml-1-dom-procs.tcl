ad_library {

# dom.tcl --
#
#	This file implements the Tcl language binding for the DOM -
#	the Document Object Model.  Support for the core specification
#	is given here.  Layered support for specific languages, 
#	such as HTML and XML, will be in separate modules.
#
# Copyright (c) 1998 Zveno Pty Ltd
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
    @cvs-id $Id$
}

package provide dom 1.6

namespace eval dom {
    namespace export DOMImplementation
    namespace export document documentFragment node
    namespace export element textNode attribute
    namespace export processingInstruction
}

# Data structure
#
# Documents are stored in an array within the dom namespace.
# Each element of the array is indexed by a unique identifier.
# Each element of the array is a key-value list with at least
# the following fields:
#	id docArray
#	node:parentNode node:childNodes node:nodeType
# Nodes of a particular type may have additional fields defined.
# Note that these fields in many circumstances are configuration options
# for a node type.
#
# "Live" data objects are stored as a separate Tcl variable.
# Lists, such as child node lists, are Tcl list variables (ie scalar)
# and keyed-value lists, such as attribute lists, are Tcl array
# variables.  The accessor function returns the variable name,
# which the application should treat as a read-only object.
#
# A token is a FQ array element reference for a node.

# dom::GetHandle --
#
#	Checks that a token is valid and sets an array variable
#	in the caller to contain the node's fields.
#
#	This is expensive, so it is only used when called by
#	the application.
#
# Arguments:
#	type	node type (for future use)
#	token	token passed in
#	varName	variable name in caller to associate with node
#
# Results:
#	Variable gets node's fields, otherwise returns error.
#	Returns empty string.

proc dom::GetHandle {type token varName} {

    if {![info exists $token]} {
	return -code error "invalid token \"$token\""
    }

    upvar 1 $varName data
    array set data [set $token]

# Type checking not implemented
#    if {$data(node:nodeType) ne "document" } {
#	return -code error "node is not of type document"
#    }

    return {}
}

# dom::PutHandle --
#
#	Writes the values from the working copy of the node's data
#	into the document's global array.
#
#	NB. Token checks are performed in GetHandle
#	NB(2). This is still expensive, so is not used.
#
# Arguments:
#	token	token passed in
#	varName	variable name in caller to associate with node
#
# Results:
#	Sets array element for this node to have new values.
#	Returns empty string.

proc dom::PutHandle {token varName} {

    upvar 1 $varName data
    set $token [array get data]

    return {}
}

# dom::DOMImplementation --
#
#	Implementation-dependent functions.
#	Most importantly, this command provides a function to
#	create a document instance.
#
# Arguments:
#	method	method to invoke
#	token	token for node
#	args	arguments for method
#
# Results:
#	Depends on method used.

namespace eval dom {
    variable DOMImplementationOptions {}
    variable DOMImplementationCounter 0
}

proc dom::DOMImplementation {method args} {
    variable DOMImplementationOptions
    variable DOMImplementationCounter

    switch -- $method {

	hasFeature {

	    if {[llength $args] != 2} {
		return -code error "wrong number of arguments"
	    }

	    # Later on, could use Tcl package facility
	    if {[regexp {create|destroy|parse|serialize|trim} [lindex $args 0]]} {
		if {[lindex $args 1] eq "1.0" } {
		    return 1
		} else {
		    return 0
		}
	    } else {
		return 0
	    }

	}

	create {

	    # Bootstrap a document instance

	    switch [llength $args] {
		0 {
		    # Allocate unique document array name
	    	    set name [namespace current]::document[incr DOMImplementationCounter]
		}
		1 {
		    # Use array name provided.  Should check that it is safe.
		    set name [lindex $args 0]
		    unset -nocomplain $name
		}
		default {
		    return -code error "wrong number of arguments"
		}
	    }

	    set varPrefix ${name}var
	    set arrayPrefix ${name}arr

	    array set $name [list counter 1 \
		node1 [list id node1 docArray $name		\
			node:nodeType documentFragment		\
			node:parentNode {}			\
			node:childNodes ${varPrefix}1		\
			documentFragment:masterDoc node1	\
			document:implementation {}		\
			document:xmldecl {version 1.0}		\
			document:documentElement {}		\
			document:doctype {}			\
		]]

	    # Initialise child node list
	    set ${varPrefix}1 {}

	    # Return the new toplevel node
	    return ${name}(node1)

	}

	destroy {

	    # Cleanup a document

	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }
	    array set node [set [lindex $args 0]]

	    # Patch from Gerald Lester

	    ##
	    ## First release all the associated variables
	    ##
	    upvar #0 $node(docArray) docArray
	    for {set i 0} {$i < $docArray(counter)} {incr i} {
		unset -nocomplain ${docArrayName}var$i
		unset -nocomplain ${docArrayName}arr$i
	    }
             
	    ##
	    ## Then release the main document array
	    ##
	    if {![info exists $node(docArray)]} {
		return -code error "unable to destroy document"
	    }
            unset -nocomplain $node(docArray)

	    return {}

	}

	parse {

	    # This implementation allows use of either of two event-based,
	    # non-validating XML parsers:
	    # . TclXML Tcl-only parser (version 1.3 or higher)
	    # . TclExpat parser

	    array set opts {-parser {} -progresscommand {} -chunksize 8196}
	    if {[catch {array set opts [lrange $args 1 end]}]} {
		return -code error "bad configuration options"
	    }

	    # Create a state array for this parse session
	    set state [namespace current]::parse[incr DOMImplementationCounter]
	    array set $state [array get opts -*]
	    array set $state [list progCounter 0]
	    set errorCleanup {}

	    switch -- $opts(-parser) {
		expat {
		    if {[catch {package require expat} version]} {
			eval $errorCleanup
			return -code error "expat extension is not available"
		    }
		    set parser [expat [namespace current]::xmlparser]
		}
		tcl {
		    if {[catch {package require xml 1.3} version]} {
			eval $errorCleanup
			return -code error "XML parser package is not available"
		    }
		    set parser [::xml::parser xmlparser]
		}
		default {
		    # Automatically determine which parser to use
		    if {[catch {package require expat} version]} {
			if {[catch {package require xml 1.3} version]} {
			    eval $errorCleanup
			    return -code error "unable to load XML parser"
			} else {
			    set parser [::xml::parser xmlparser]
			}
		    } else {
			set parser [expat [namespace current]::xmlparser]
		    }
		}
	    }

	    $parser configure \
		-elementstartcommand [namespace code [list ParseElementStart $state]]	\
		-elementendcommand [namespace code [list ParseElementEnd $state]]	\
		-characterdatacommand [namespace code [list ParseCharacterData $state]] \
		-processinginstructioncommand [namespace code [list ParseProcessingInstruction $state]] \
		-final true

	    # TclXML has features missing from expat
	    catch {
		$parser configure \
		    -xmldeclcommand [namespace code [list ParseXMLDeclaration $state]] \
		    -doctypecommand [namespace code [list ParseDocType $state]]
	    }

	    # Create top-level document
	    array set $state [list docNode [DOMImplementation create]]
	    array set $state [list current [lindex [array get $state docNode] 1]]

	    # Parse data
	    # Bug in TclExpat - doesn't handle non-final inputs
	    if {0 && [string length $opts(-progresscommand)]} {
		$parser configure -final false
		while {[string length [lindex $args 0]]} {
		    $parser parse [string range [lindex $args 0] 0 $opts(-chunksize)]
		    #set args [lreplace $args 0 0 \
                    #              [string range [lindex $args 0] $opts(-chunksize) end]]
                    lset args 0 [string range [lindex $args 0] $opts(-chunksize) end]
		    uplevel #0 $opts(-progresscommand)
		}
		$parser configure -final true
	    } elseif {[catch {$parser parse [lindex $args 0]} err]} {
		catch {rename $parser {}}
		unset -nocomplain $state
		return -code error $err
	    }

	    # Free data structures which are no longer required
	    catch {rename $parser {}}

	    set doc [lindex [array get $state docNode] 1]
	    unset $state
	    return $doc

	}

	serialize {

	    if {[llength $args] < 1} {
		return -code error "wrong number of arguments"
	    }

	    GetHandle documentFragment [lindex $args 0] node
	    return [eval [list Serialize:$node(node:nodeType)] $args]

	}

	trim {

	    # Removes textNodes that only contain white space

	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }

	    Trim [lindex $args 0]

	    return {}

	}

	default {
	    return -code error "unknown method \"$method\""
	}

    }

    return {}
}

# dom::document --
#
#	Functions for a document node.
#
# Arguments:
#	method	method to invoke
#	token	token for node
#	args	arguments for method
#
# Results:
#	Depends on method used.

namespace eval dom {
    variable documentOptionsRO doctype|implementation|documentElement
    variable documentOptionsRW {}
}

proc dom::document {method token args} {
    variable documentOptionsRO
    variable documentOptionsRW

    # GetHandle also checks token
    GetHandle document $token node

    set result {}

    switch -- $method {
	cget {
	    if {[llength $args] != 1} {
		return -code error "too many arguments"
	    }
	    if {[regexp [format {^-(%s)$} $documentOptionsRO] [lindex $args 0] discard option]} {
		return $node(document:$option)
	    } elseif {[regexp [format {^-(%s)$} $documentOptionsRW] [lindex $args 0] discard option]} {
		return $node(document:$option)
	    } else {
		return -code error "unknown option \"[lindex $args 0]\""
	    }
	}
	configure {
	    if {[llength $args] == 1} {
		return [document cget $token [lindex $args 0]]
	    } elseif {[llength $args] % 2} {
		return -code error "no value specified for option \"[lindex $args end]\""
	    } else {
		foreach {option value} $args {
		    if {[regexp [format {^-(%s)$} $documentOptionsRW] $option discard opt]} {
			set node(document:$opt) $value
		    } elseif {[regexp [format {^-(%s)$} $documentOptionsRO] $option discard opt]} {
			return -code error "attribute \"$option\" is read-only"
		    } else {
			return -code error "unknown option \"$option\""
		    }
		}
	    }

	    PutHandle $token node

	}

	createElement {
	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }

	    # Check that the element name is kosher
	    # BUG: The definition of 'Letter' here as ASCII letters
	    # is not sufficient.  Also, CombiningChar and Extenders
	    # must be added.
	    if {![regexp {^[A-Za-z_:][-A-Za-z0-9._:]*$} [lindex $args 0]]} {
		return -code error "invalid element name \"[lindex $args 0]\""
	    }

	    # Invoke internal factory function
	    set result [CreateElement $token [lindex $args 0] {}]

	}
	createDocumentFragment {
	    if {[llength $args]} {
		return -code error "wrong number of arguments"
	    }

	    set result [CreateGeneric $token node:nodeType documentFragment]
	}
	createTextNode {
	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }

	    set result [CreateTextNode $token [lindex $args 0]]
	}
	createComment {
	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }

	    set result [CreateGeneric $token node:nodeType comment node:nodeValue [lindex $args 0]]
	}
	createCDATASection {
	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }

	    set result [CreateGeneric $token node:nodeType CDATASection node:nodeValue [lindex $args 0]]
	}
	createProcessingInstruction {
	    if {[llength $args] != 2} {
		return -code error "wrong number of arguments"
	    }

	    set result [CreateGeneric $token node:nodeType processingInstruction \
		    node:nodeName [lindex $args 0] node:nodeValue [lindex $args 1]]
	}
	createAttribute {
	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }

	    set result [CreateGeneric $token node:nodeType attribute node:nodeName [lindex $args 0]]
	}
	createEntity {
	    set result [CreateGeneric $token node:nodeType entity]
	}
	createEntityReference {
	    set result [CreateGeneric $token node:nodeType entityReference]
	}

	createDocTypeDecl {
	    # This is not a standard DOM 1.0 method
	    if {[llength $args] < 1 || [llength $args] > 5} {
		return -code error "wrong number of arguments"
	    }

	    lassign $args name extid dtd entities notations
	    set result [CreateDocType $token $name $extid $dtd $entities $notations]
	}

	getElementsByTagName {
	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }

	    return [Element:GetByTagName $token [lindex $args 0]]
	}

	default {
	    return -code error "unknown method \"$method\""
	}

    }

    return $result
}

###	Factory methods
###
### These are lean-and-mean for fastest possible tree building

# dom::CreateElement --
#
#	Append an element to the given (parent) node (if any)
#
# Arguments:
#	token	parent node
#	name	element name (no checking performed here)
#	aList	attribute list
#	args	configuration options
#
# Results:
#	New node created, parent optionally modified

proc dom::CreateElement {token name aList args} {
    if {[string length $token]} {
	array set parent [set $token]
	upvar #0 $parent(docArray) docArray
	set docArrayName $parent(docArray)
    } else {
	array set opts $args
	upvar #0 $opts(-docarray) docArray
	set docArrayName $opts(-docarray)
    }

    set id node[incr docArray(counter)]
    set child ${docArrayName}($id)

    # Create the new node
    # NB. normally we'd use Node:create here,
    # but inline it instead for performance
    set docArray($id) [list id $id docArray $docArrayName \
	    node:parentNode $token		\
	    node:childNodes ${docArrayName}var$docArray(counter)	\
	    node:nodeType element		\
	    node:nodeName $name			\
	    node:nodeValue {}			\
	    element:attributeList ${docArrayName}arr$docArray(counter) \
    ]

    # Initialise associated variables
    set ${docArrayName}var$docArray(counter) {}
    array set ${docArrayName}arr$docArray(counter) $aList

    # Update parent record

    # Does this element qualify as the document element?
    # If so, then has a document element already been set?

    if {[string length $token]} {

	if {$parent(node:nodeType) eq "documentFragment" } {
	    if {$parent(id) == $parent(documentFragment:masterDoc)} {
		if {[info exists parent(document:documentElement)] 
		    && [string length $parent(document:documentElement)]
		} {
		    unset docArray($id)
		    return -code error "document element already exists"
		} else {

		    # Check against document type decl
		    if {[string length $parent(document:doctype)]} {
			array set doctypedecl [set $parent(document:doctype)]
			if {$name ne $doctypedecl(doctype:name) } {
			    return -code error "mismatch between root element type in document type declaration \"$doctypedecl(doctype:name)\" and root element \"$name\""
			}

		    } else {
			# Synthesize document type declaration
			CreateDocType $token $name {} {}
			# Resynchronise parent record
			array set parent [set $token]
		    }

		    set parent(document:documentElement) $child
		    set $token [array get parent]
		}
	    }
	}

	lappend $parent(node:childNodes) $child

    }

    return $child
}

# dom::CreateTextNode --
#
#	Append a textNode node to the given (parent) node (if any).
#
#	This factory function can also be performed by
#	CreateGeneric, but text nodes are created so often
#	that this specific factory procedure speeds things up.
#
# Arguments:
#	token	parent node
#	text	initial text
#	args	additional configuration options
#
# Results:
#	New node created, parent optionally modified

proc dom::CreateTextNode {token text args} {
    if {[string length $token]} {
	array set parent [set $token]
	upvar #0 $parent(docArray) docArray
	set docArrayName $parent(docArray)
    } else {
	array set opts $args
	upvar #0 $opts(-docarray) docArray
	set docArrayName $opts(-docarray)
    }

    set id node[incr docArray(counter)]
    set child ${docArrayName}($id)

    # Create the new node
    # NB. normally we'd use Node:create here,
    # but inline it instead for performance

    # Text nodes never have children, so don't create a variable

    set docArray($id) [list id $id docArray $docArrayName \
	    node:parentNode $token		\
	    node:childNodes {}			\
	    node:nodeType textNode		\
	    node:nodeValue $text		\
    ]

    if {[string length $token]} {
	# Update parent record
	lappend $parent(node:childNodes) $child
	set $token [array get parent]
    }

    return $child
}

# dom::CreateGeneric --
#
#	This is a template used for type-specific factory procedures
#
# Arguments:
#	token	parent node
#	args	optional values
#
# Results:
#	New node created, parent modified

proc dom::CreateGeneric {token args} {
    if {[string length $token]} {
	array set parent [set $token]
	upvar #0 $parent(docArray) docArray
	set docArrayName $parent(docArray)
    } else {
	array set opts $args
	upvar #0 $opts(-docarray) docArray
	set docArrayName $opts(-docarray)
	array set tmp [array get opts]
	foreach opt [array names tmp -*] {
	    unset tmp($opt)
	}
	set args [array get tmp]
    }

    set id node[incr docArray(counter)]
    set child ${docArrayName}($id)

    # Create the new node
    # NB. normally we'd use Node:create here,
    # but inline it instead for performance
    set docArray($id) [eval list [list id $id docArray $docArrayName \
	    node:parentNode $token		\
	    node:childNodes ${docArrayName}var$docArray(counter)]	\
	    $args
    ]
    set ${docArrayName}var$docArray(counter) {}

    if {[string length $token]} {
	# Update parent record
	lappend $parent(node:childNodes) $child
	set $token [array get parent]
    }

    return $child
}

### Specials

# dom::CreateDocType --
#
#	Create a Document Type Declaration node.
#
# Arguments:
#	token	node id for the document node
#	name	root element type
#	extid	external entity id
#	dtd	internal DTD subset
#
# Results:
#	Returns node id of the newly created node.

proc dom::CreateDocType {token name {extid {}} {dtd {}} {entities {}} {notations {}}} {
    array set doc [set $token]
    upvar #0 $doc(docArray) docArray

    set id node[incr docArray(counter)]
    set child $doc(docArray)($id)

    set docArray($id) [list \
	    id $id docArray $doc(docArray) \
	    node:parentNode $token \
	    node:childNodes {} \
	    node:nodeType docType \
	    node:nodeName {} \
	    node:nodeValue {} \
	    doctype:name $name \
	    doctype:entities {} \
	    doctype:notations {} \
	    doctype:externalid $extid \
	    doctype:internaldtd $dtd \
    ]
    # NB. externalid and internaldtd are not standard DOM 1.0 attributes

    # Update parent

    set doc(document:doctype) $child

    # Add this node to the parent's child list
    # This must come before the document element,
    # so this implementation may be buggy
    lappend $doc(node:childNodes) $child

    set $token [array get doc]

    return $child
}

# dom::node --
#
#	Functions for a general node.
#
# Arguments:
#	method	method to invoke
#	token	token for node
#	args	arguments for method
#
# Results:
#	Depends on method used.

namespace eval dom {
    variable nodeOptionsRO nodeName|nodeType|parentNode|childNodes|firstChild|lastChild|previousSibling|nextSibling|attributes
    variable nodeOptionsRW nodeValue
}

proc dom::node {method token args} {
    variable nodeOptionsRO
    variable nodeOptionsRW

    GetHandle node $token node

    set result {}

    switch -glob -- $method {
	cg* {
	    # cget

	    # Some read-only configuration options are computed
	    if {[llength $args] != 1} {
		return -code error "too many arguments"
	    }
	    if {[regexp [format {^-(%s)$} $nodeOptionsRO] [lindex $args 0] discard option]} {
		switch -- $option {
		    childNodes {
			# How are we going to handle documentElement?
			set result $node(node:childNodes)
		    }
		    firstChild {
			upvar #0 $node(node:childNodes) children
			switch -- $node(node:nodeType) {
			    documentFragment {
				set result [lindex $children 0]
				catch {set result $node(document:documentElement)}
			    }
			    default {
				set result [lindex $children 0]
			    }
			}
		    }
		    lastChild {
			upvar #0 $node(node:childNodes) children
			switch -- $node(node:nodeType) {
			    documentFragment {
				set result [lindex $children end]
				catch {set result $node(document:documentElement)}
			    }
			    default {
				set result [lindex $children end]
			    }
			}
		    }
		    previousSibling {
			# BUG: must take documentElement into account
			# Find the parent node
			GetHandle node $node(node:parentNode) parent
			upvar #0 $parent(node:childNodes) children
			set idx [lsearch $children $token]
			if {$idx >= 0} {
			    set sib [lindex $children [incr idx -1]]
			    if {[llength $sib]} {
				set result $sib
			    } else {
				set result {}
			    }
			} else {
			    set result {}
			}
		    }
		    nextSibling {
			# BUG: must take documentElement into account
			# Find the parent node
			GetHandle node $node(node:parentNode) parent
			upvar #0 $parent(node:childNodes) children
			set idx [lsearch $children $token]
			if {$idx >= 0} {
			    set sib [lindex $children [incr idx]]
			    if {[llength $sib]} {
				set result $sib
			    } else {
				set result {}
			    }
			} else {
			    set result {}
			}
		    }
		    attributes {
			if {$node(node:nodeType) ne "element" } {
			    set result {}
			} else {
			    set result $node(element:attributeList)
			}
		    }
		    default {
			return [GetField node(node:$option)]
		    }
		}
	    } elseif {[regexp [format {^-(%s)$} $nodeOptionsRW] [lindex $args 0] discard option]} {
		return [GetField node(node:$option)]
	    } else {
		return -code error "unknown option \"[lindex $args 0]\""
	    }
	}
	co* {
	    # configure

	    if {[llength $args] == 1} {
		return [document cget $token [lindex $args 0]]
	    } elseif {[llength $args] % 2} {
		return -code error "no value specified for option \"[lindex $args end]\""
	    } else {
		foreach {option value} $args {
		    if {[regexp [format {^-(%s)$} $nodeOptionsRW] $option discard opt]} {
			set node(node:$opt) $value
		    } elseif {[regexp [format {^-(%s)$} $nodeOptionsRO] $option discard opt]} {
			return -code error "attribute \"$option\" is read-only"
		    } else {
			return -code error "unknown option \"$option\""
		    }
		}
	    }
	}

	in* {

	    # insertBefore

	    # Previous and next sibling relationships are OK, 
	    # because they are dynamically determined

	    if {[llength $args] < 1 || [llength $args] > 2} {
		return -code error "wrong number of arguments"
	    }

	    GetHandle node [lindex $args 0] newChild
	    if {$newChild(docArray) ne $node(docArray) } {
		return -code error "new node must be in the same document"
	    }

	    switch [llength $args] {
		1 {
		    # Append as the last node
		    if {[string length $newChild(node:parentNode)]} {
			node removeChild $newChild(node:parentNode) [lindex $args 0]
		    }
		    lappend $node(node:childNodes) [lindex $args 0]
		    set newChild(node:parentNode) $token
		}
		2 {

		    GetHandle node [lindex $args 1] refChild
		    if {$refChild(docArray) ne $newChild(docArray) } {
			return -code error "nodes must be in the same document"
		    }
		    set idx [lsearch [set $node(node:childNodes)] [lindex $args 1]]
		    if {$idx < 0} {
			return -code error "no such reference child"
		    } else {

			# Remove from previous parent
			if {[string length $newChild(node:parentNode)]} {
			    node removeChild $newChild(node:parentNode) [lindex $args 0]
			}

			# Insert into new node
			set $node(node:childNodes) \
				[linsert [set $node(node:childNodes)] $idx [lindex $args 0]]
			set newChild(node:parentNode) $token
		    }
		}
	    }
	    PutHandle [lindex $args 0] newChild
	}

	rep* {

	    # replaceChild

	    if {[llength $args] != 2} {
		return -code error "wrong number of arguments"
	    }

	    GetHandle node [lindex $args 0] newChild
	    GetHandle node [lindex $args 1] oldChild

	    # Find where to insert new child
	    set idx [lsearch [set $node(node:childNodes)] [lindex $args 1]]
	    if {$idx < 0} {
		return -code error "no such old child"
	    }

	    # Remove new child from current parent
	    if {[string length $newChild(node:parentNode)]} {
		node removeChild $newChild(node:parentNode) [lindex $args 0]
	    }

	    #set $node(node:childNodes) \
		#[lreplace [set $node(node:childNodes)] $idx $idx [lindex $args 0]]
            lset $node(node:childNodes) $idx [lindex $args 0]
	    set newChild(node:parentNode) $token

	    # Update old child to reflect lack of parentage
	    set oldChild(node:parentNode) {}

	    PutHandle [lindex $args 1] oldChild
	    PutHandle [lindex $args 0] newChild

	    set result [lindex $args 0]

	}

	rem* {

	    # removeChild

	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }
	    array set oldChild [set [lindex $args 0]]
	    if {$oldChild(docArray) != $node(docArray)} {
		return -code error "node \"[lindex $args 0]\" is not a child"
	    }

	    # Remove the child from the parent
	    upvar #0 $node(node:childNodes) myChildren
	    if {[set idx [lsearch $myChildren [lindex $args 0]]] < 0} {
		return -code error "node \"[lindex $args 0]\" is not a child"
	    }
	    set myChildren [lreplace $myChildren $idx $idx]

	    # Update the child to reflect lack of parentage
	    set oldChild(node:parentNode) {}
	    set [lindex $args 0] [array get oldChild]

	    set result [lindex $args 0]
	}

	ap* {

	    # appendChild

	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }

	    # Add to new parent
	    node insertBefore $token [lindex $args 0]

	}

	hasChildNodes {
	    set result [Min 1 [llength [set $node(node:childNodes)]]]
	}

	cl* {
	    # cloneNode

	    set deep 0
	    switch [llength $args] {
		0 {
		}
		1 {
		    set deep [Boolean [lindex $args 0]]
		}
		default {
		    return -code error "too many arguments"
		}
	    }

	    switch -- $node(node:nodeType) {
		element {
		    set result [CreateElement {} $node(node:nodeName) [array get $node(element:attributeList)] -docarray $node(docArray)]
		    if {$deep} {
			foreach child [set $node(node:childNodes)] {
			    node appendChild $result [node cloneNode $child]
			}
		    }
		}
		textNode {
		    set result [CreateTextNode {} $node(node:nodeValue) -docarray $node(docArray)]
		}
		document -
		documentFragment -
		default {
		    set result [CreateGeneric {} node:nodeType $node(node:nodeType) -docarray $node(docArray)]
		    if {$deep} {
			foreach child [set $node(node:childNodes)] {
			    node appendChild $result [node cloneNode $child]
			}
		    }
		}
	    }

	}

	ch* {
	    # children -- non-standard method

	    # If this is a textNode, then catch the error
	    set result {}
	    catch {set result [set $node(node:childNodes)]}

	}

	pa* {
	    # parent -- non-standard method

	    return $node(node:parentNode)

	}

	default {
	    return -code error "unknown method \"$method\""
	}

    }

    PutHandle $token node

    return $result
}

# dom::Node:create --
#
#	Generic node creation.
#	See also CreateElement, CreateTextNode, CreateGeneric.
#
# Arguments:
#	pVar	array in caller which contains parent details
#	args	configuration options
#
# Results:
#	New child node created.

proc dom::Node:create {pVar args} {
    upvar $pVar parent

    array set opts {-name {} -value {}}
    array set opts $args

    upvar #0 $parent(docArray) docArray

    # Create new node
    if {![info exists opts(-id)]} {
	set opts(-id) node[incr docArray(counter)]
    }
    set docArray($opts(-id)) [list id $opts(-id) \
	    docArray $parent(docArray)		\
	    node:parentNode $opts(-parent)	\
	    node:childNodes $parent(docArray)var$docArray(counter)	\
	    node:nodeType $opts(-type)		\
	    node:nodeName $opts(-name)		\
	    node:nodeValue $opts(-value)	\
	    element:attributeList $parent(docArray)arr$docArray(counter) \
    ]
    set $parent(docArray)var$docArray(counter) {}
    array set $parent(docArray)arr$docArray(counter) {}

    # Update parent node
    if {![info exists parent(document:documentElement)]} {
	lappend parent(node:childNodes) [list [lindex $opts(-parent) 0] $opts(-id)]
    }

    return $parent(docArray)($opts(-id))

}

# dom::Node:set --
#
#	Generic node update
#
# Arguments:
#	token	node token
#	args	configuration options
#
# Results:
#	Node modified.

proc dom::Node:set {token args} {
    upvar $token node

    foreach {key value} $args {
	set node($key) $value
    }

    set $token [array get node]

    return {}
}

# dom::element --
#
#	Functions for an element.
#
# Arguments:
#	method	method to invoke
#	token	token for node
#	args	arguments for method
#
# Results:
#	Depends on method used.

namespace eval dom {
    variable elementOptionsRO {tagName empty}
    variable elementOptionsRW {}
}

proc dom::element {method token args} {
    variable elementOptionsRO
    variable elementOptionsRW

    GetHandle node $token node

    set result {}

    switch -- $method {

	cget {
	    # Some read-only configuration options are computed
	    if {[llength $args] != 1} {
		return -code error "too many arguments"
	    }
	    if {[regexp [format {^-(%s)$} $elementOptionsRO] [lindex $args 0] discard option]} {
		switch -- $option {
		    tagName {
			set result [lindex $node(node:nodeName) 0]
		    }
		    empty {
			if {![info exists node(element:empty)]} {
			    return 0
			} else {
			    return $node(element:empty)
			}
		    }
		    default {
			return $node(node:$option)
		    }
		}
	    } elseif {[regexp [format {^-(%s)$} $elementOptionsRW] [lindex $args 0] discard option]} {
		return $node(node:$option)
	    } else {
		return -code error "unknown option \"[lindex $args 0]\""
	    }
	}
	configure {
	    if {[llength $args] == 1} {
		return [document cget $token [lindex $args 0]]
	    } elseif {[llength $args] % 2} {
		return -code error "no value specified for option \"[lindex $args end]\""
	    } else {
		foreach {option value} $args {
		    if {[regexp [format {^-(%s)$} $elementOptionsRO] $option discard opt]} {
			return -code error "attribute \"$option\" is read-only"
		    } elseif {[regexp [format {^-(%s)$} $elementOptionsRW] $option discard opt]} {
			return -code error "not implemented"
		    } else {
			return -code error "unknown option \"$option\""
		    }
		}
	    }
	}

	getAttribute {
	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }

	    upvar #0 $node(element:attributeList) attrList
	    catch {set result $attrList([lindex $args 0])}

	}

	setAttribute {
	    if {[llength $args] == 0 || [llength $args] > 2} {
		return -code error "wrong number of arguments"
	    }

	    # TODO: Check that the attribute name is legal

	    upvar #0 $node(element:attributeList) attrList
	    set attrList([lindex $args 0]) [lindex $args 1]

	}

	removeAttribute {
	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }

	    upvar #0 $node(element:attributeList) attrList
	    unset -nocomplain attrList([lindex $args 0])

	}

	getAttributeNode {
	}

	setAttributeNode {
	}

	removeAttributeNode {
	}

	getElementsByTagName {
	    if {[llength $args] != 1} {
		return -code error "wrong number of arguments"
	    }

	    return [Element:GetByTagName $token [lindex $args 0]]
	}

	normalize {
	    if {[llength $args]} {
		return -code error "wrong number of arguments"
	    }

	    Element:Normalize node [set $node(node:childNodes)]
	}

	default {
	    return -code error "unknown method \"$method\""
	}

    }

    PutHandle $token node

    return $result
}

# Element:GetByTagName --
#
#	Search for (child) elements
#	NB. This does not descend the hierarchy.  Check the DOM spec.
#
# Arguments:
#	token	parent node
#	name	(child) elements to search for
#
# Results:
#	List of matching node tokens

proc dom::Element:GetByTagName {token name} {
    array set node [set $token]

    set result {}

    if {$node(node:nodeType) ne "documentFragment" } {
	foreach child [set $node(node:childNodes)] {
	    unset -nocomplain childNode
	    array set childNode [set $child]
	    if {$childNode(node:nodeType) eq "element" 
		&& [GetField childNode(node:nodeName)] eq $name 
	    } {
		lappend result $child
	    }
	}
    } elseif {[llength $node(document:documentElement)]} {
	# Document Element must exist and must be an element type node
	unset -nocomplain childNode
	array set childNode [set $node(document:documentElement)]
	if {$childNode(node:nodeName) eq $name } {
	    set result $node(document:documentElement)
	}
    }

    return $result
}

# Element:Normalize --
#
#	Normalize the text nodes
#
# Arguments:
#	pVar	parent array variable in caller
#	nodes	list of node tokens
#
# Results:
#	Adjacent text nodes are coalesced

proc dom::Element:Normalize {pVar nodes} {
    upvar $pVar parent

    set textNode {}

    foreach n $nodes {
	GetHandle node $n child
	set cleanup {}

	switch -- $child(node:nodeType) {
	    textNode {
		if {[llength $textNode]} {
		    # Coalesce into previous node
		    append text(node:nodeValue) $child(node:nodeValue)
		    # Remove this child
		    upvar #0 $parent(node:childNodes) childNodes
		    set idx [lsearch $childNodes $n]
		    set childNodes [lreplace $childNodes $idx $idx]
		    unset $n
		    set cleanup {}

		    PutHandle $textNode text
		} else {
		    set textNode $n
		    unset -nocomplain text
		    array set text [array get child]
		}
	    }
	    element -
	    document -
	    documentFragment {
		set textNode {}
		Element:Normalize child [set $child(node:childNodes)]
	    }
	    default {
		set textNode {}
	    }
	}

	eval $cleanup
    }

    return {}
}

# dom::processinginstruction --
#
#	Functions for a processing instruction.
#
# Arguments:
#	method	method to invoke
#	token	token for node
#	args	arguments for method
#
# Results:
#	Depends on method used.

namespace eval dom {
    variable piOptionsRO target
    variable piOptionsRW data
}

proc dom::processinginstruction {method token args} {
    variable piOptionsRO
    variable piOptionsRW

    GetHandle node $token node

    set result {}

    switch -- $method {

	cget {
	    # Some read-only configuration options are computed
	    if {[llength $args] != 1} {
		return -code error "too many arguments"
	    }
	    if {[regexp [format {^-(%s)$} $elementOptionsRO] [lindex $args 0] discard option]} {
		switch -- $option {
		    target {
			set result [lindex $node(node:nodeName) 0]
		    }
		    default {
			return $node(node:$option)
		    }
		}
	    } elseif {[regexp [format {^-(%s)$} $elementOptionsRW] [lindex $args 0] discard option]} {
		switch -- $option {
		    data {
			return $node(node:nodeValue)
		    }
		    default {
			return $node(node:$option)
		    }
		}
	    } else {
		return -code error "unknown option \"[lindex $args 0]\""
	    }
	}
	configure {
	    if {[llength $args] == 1} {
		return [document cget $token [lindex $args 0]]
	    } elseif {[llength $args] % 2} {
		return -code error "no value specified for option \"[lindex $args end]\""
	    } else {
		foreach {option value} $args {
		    if {[regexp [format {^-(%s)$} $elementOptionsRO] $option discard opt]} {
			return -code error "attribute \"$option\" is read-only"
		    } elseif {[regexp [format {^-(%s)$} $elementOptionsRW] $option discard opt]} {
			switch -- $opt {
			    data {
				set node(node:nodeValue) $value
			    }
			    default {
				set node(node:$opt) $value
			    }
			}
		    } else {
			return -code error "unknown option \"$option\""
		    }
		}
	    }
	}

	default {
	    return -code error "unknown method \"$method\""
	}

    }

    PutHandle $token node

    return $result
}

#################################################
#
# Serialisation
#
#################################################

# dom::Serialize:documentFragment --
#
#	Produce text for documentFragment.
#
# Arguments:
#	token	node token
#	args	configuration options
#
# Results:
#	XML format text.

proc dom::Serialize:documentFragment {token args} {
    array set node [set $token]

    if {"node1" ne $node(documentFragment:masterDoc) } {
	return [eval [list Serialize:node $token] $args]
    } else {
	if {{} ne [GetField node(document:documentElement)] } {
	    return [eval Serialize:document [list $token] $args]
	} else {
	    return -code error "document has no document element"
	}
    }

}

# dom::Serialize:document --
#
#	Produce text for document.
#
# Arguments:
#	token	node token
#	args	configuration options
#
# Results:
#	XML format text.

proc dom::Serialize:document {token args} {
    array set node [set $token]

    if {![info exists node(document:documentElement)]} {
	return -code error "document has no document element"
    } elseif {$node(document:doctype) eq ""} {
	return -code error "no document type declaration given"
    } else {

	array set doctype [set $node(document:doctype)]

	# BUG: Want to serialize all children except for the 
	# document element, and then do the document element.

	# Bug fix: can't use Serialize:attributeList for XML declaration,
	# since attributes must occur in a given order (XML 2.8 [23])

	return "<?xml[Serialize:XMLDecl version $node(document:xmldecl)][Serialize:XMLDecl encoding $node(document:xmldecl)][Serialize:XMLDecl standalone $node(document:xmldecl)]?>\n<!DOCTYPE $doctype(doctype:name)[expr {[string length $doctype(doctype:externalid)] ? " PUBLIC[Serialize:ExternalID $doctype(doctype:externalid)]" : {}}][expr {[string length $doctype(doctype:internaldtd)] ? " \[$doctype(doctype:internaldtd)\]" : {}}]>\n[eval Serialize:element [list $node(document:documentElement)] $args]"
    }

}

# dom::Serialize:ExternalID --
#
#	Returned appropriately quoted external identifiers
#
# Arguments:
#	id	external indentifiers
#
# Results:
#	text

proc dom::Serialize:ExternalID id {
    set result {}

    foreach ident $id {
	append result { } \"$ident\"
    }

    return $result
}

# dom::Serialize:XMLDecl --
#
#	Produce text for an arbitrary node.
#	This simply serializes the child nodes of the node.
#
# Arguments:
#	attr	required attribute
#	attList	attribute list
#
# Results:
#	XML format text.

proc dom::Serialize:XMLDecl {attr attrList} {
    array set data $attrList
    if {![info exists data($attr)]} {
	return {}
    } elseif {[string length $data($attr)]} {
	return " $attr='$data($attr)'"
    } else {
	return {}
    }
}

# dom::Serialize:node --
#
#	Produce text for an arbitrary node.
#	This simply serializes the child nodes of the node.
#
# Arguments:
#	token	node token
#	args	configuration options
#
# Results:
#	XML format text.

proc dom::Serialize:node {token args} {
    array set node [set $token]

    set result {}
    foreach childToken [set $node(node:childNodes)] {
	unset -nocomplain child
	array set child [set $childToken]
	append result [eval [list Serialize:$child(node:nodeType) $childToken] $args]
    }

    return $result
}

# dom::Serialize:element --
#
#	Produce text for an element.
#
# Arguments:
#	token	node token
#	args	configuration options
#
# Results:
#	XML format text.

proc dom::Serialize:element {token args} {
    array set node [set $token]
    array set opts {-newline {}}
    array set opts $args

    set result {}
    set newline {}
    if {[lsearch $opts(-newline) $node(node:nodeName)] >= 0} {
	append result \n
	set newline \n
    }
    append result "<$node(node:nodeName)"
    append result [Serialize:attributeList [array get $node(element:attributeList)]]

    if {![llength [set $node(node:childNodes)]]} {

	append result />$newline

    } else {

	append result >$newline

	# Do the children
	append result [eval Serialize:node [list $token] $args]

	append result "$newline</$node(node:nodeName)>$newline"

    }

    return $result
}

# dom::Serialize:textNode --
#
#	Produce text for a text node.
#
# Arguments:
#	token	node token
#	args	configuration options
#
# Results:
#	XML format text.

proc dom::Serialize:textNode {token args} {
    array set node [set $token]

    return [Encode $node(node:nodeValue)]
}

# dom::Serialize:processingInstruction --
#
#	Produce text for a PI node.
#
# Arguments:
#	token	node token
#	args	configuration options
#
# Results:
#	XML format text.

proc dom::Serialize:processingInstruction {token args} {
    array set node [set $token]

    return "<$node(node:nodeName) $node(node:nodeValue)>"
}

# dom::Serialize:comment --
#
#	Produce text for a comment node.
#
# Arguments:
#	token	node token
#	args	configuration options
#
# Results:
#	XML format text.

proc dom::Serialize:comment {token args} {
    array set node [set $token]

    return <!--$node(node:nodeValue)-->
}

# dom::Encode --
#
#	Encode special characters
#
# Arguments:
#	value	text value
#
# Results:
#	XML format text.

proc dom::Encode value {
    array set Entity {
	$ $
	< &lt;
	> &gt;
	& &amp;
	\" &quot;
	' &apos;
    }

    regsub -all {([$<>&"'])} $value {$Entity(\1)} value

    return [subst -nocommand -nobackslash $value]
}

# dom::Serialize:attributeList --
#
#	Produce text for an attribute list.
#
# Arguments:
#	l	name/value paired list
#
# Results:
#	XML format text.

proc dom::Serialize:attributeList {l} {

    set result {}
    foreach {name value} $l {

	append result { } $name =

	# Handle special characters
	regsub -all < $value {\&lt;} value

	if {![string match "*\"*" $value]} {
	    append result \"$value\"
	} elseif {![string match "*'*" $value]} {
	    append result '$value'
	} else {
	    regsub -all \" $value {\&quot;} value
	    append result \"$value\"
	}

    }

    return $result
}

#################################################
#
# Parsing
#
#################################################

# ParseElementStart --
#
#	Push a new element onto the stack.
#
# Arguments:
#	stateVar	global state array variable
#	name		element name
#	attrList	attribute list
#	args		configuration options
#
# Results:
#	An element is created within the currently open element.

proc dom::ParseElementStart {stateVar name attrList args} {
    upvar #0 $stateVar state
    array set opts $args

    lappend state(current) \
	[CreateElement [lindex $state(current) end] $name $attrList]

    if {[info exists opts(-empty)] && $opts(-empty)} {
	# Flag this node as being an empty element
	array set node [set [lindex $state(current) end]]
	set node(element:empty) 1
	set [lindex $state(current) end] [array get node]
    }

    # Temporary: implement -progresscommand here, because of broken parser
    if {[string length $state(-progresscommand)]} {
	if {!([incr state(progCounter)] % $state(-chunksize))} {
	    uplevel #0 $state(-progresscommand)
	}
    }
}

# ParseElementEnd --
#
#	Pop an element from the stack.
#
# Arguments:
#	stateVar	global state array variable
#	name		element name
#	args		configuration options
#
# Results:
#	Currently open element is closed.

proc dom::ParseElementEnd {stateVar name args} {
    upvar #0 $stateVar state

    set state(current) [lreplace $state(current) end end]
}

# ParseCharacterData --
#
#	Add a textNode to the currently open element.
#
# Arguments:
#	stateVar	global state array variable
#	data		character data
#
# Results:
#	A textNode is created.

proc dom::ParseCharacterData {stateVar data} {
    upvar #0 $stateVar state

    CreateTextNode [lindex $state(current) end] $data
}

# ParseProcessingInstruction --
#
#	Add a PI to the currently open element.
#
# Arguments:
#	stateVar	global state array variable
#	name		PI name
#	target		PI target
#
# Results:
#	A processingInstruction node is created.

proc dom::ParseProcessingInstruction {stateVar name target} {
    upvar #0 $stateVar state

    CreateGeneric [lindex $state(current) end] node:nodeType processingInstruction node:nodeName $name node:nodeValue $target
}

# ParseXMLDeclaration --
#
#	Add information from the XML Declaration to the document.
#
# Arguments:
#	stateVar	global state array variable
#	version		version identifier
#	encoding	character encoding
#	standalone	standalone document declaration
#
# Results:
#	Document node modified.

proc dom::ParseXMLDeclaration {stateVar version encoding standalone} {
    upvar #0 $stateVar state

    array set node [set $state(docNode)]
    array set xmldecl $node(document:xmldecl)

    array set xmldecl [list version $version	\
	    standalone $standalone		\
	    encoding $encoding			\
    ]

    set node(document:xmldecl) [array get xmldecl]
    set $state(docNode) [array get node]

    return {}
}

# ParseDocType --
#
#	Add a Document Type Declaration node to the document.
#
# Arguments:
#	stateVar	global state array variable
#	root		root element type
#	publit		public identifier literal
#	systemlist	system identifier literal
#	dtd		internal DTD subset
#
# Results:
#	DocType node added

proc dom::ParseDocType {stateVar root {publit {}} {systemlit {}} {dtd {}}} {
    upvar #0 $stateVar state

    CreateDocType $state(docNode) $root [list $publit $systemlit] $dtd {} {}
    # Last two are entities and notaions (as namedNodeMap's)

    return {}
}

#################################################
#
# Trim white space
#
#################################################

# dom::Trim --
#
#	Remove textNodes that only contain white space
#
# Arguments:
#	nodeid	node to trim
#
# Results:
#	textNode nodes may be removed (from descendants)

proc dom::Trim nodeid {
    array set node [set $nodeid]

    switch -- $node(node:nodeType) {

	textNode {
	    if {[string trim $node(node:nodeValue)] eq ""} {
		node removeChild $node(node:parentNode) $nodeid
	    }
	}

	default {
	    foreach child [set $node(node:childNodes)] {
		Trim $child
	    }
	}

    }

    return {}
}

#################################################
#
# Miscellaneous
#
#################################################

# GetField --
#
#	Return a value, or empty string if not defined
#
# Arguments:
#	var	name of variable to return
#
# Results:
#	Returns the value, or empty string if variable is not defined.

proc GetField var {
    upvar $var v
    return [expr {[info exists v] ? $v : {}}]
}

# dom::Min --
#
#	Return the minimum of two numeric values
#
# Arguments:
#	a some value
#	b another value
#
# Results:
#	Returns the value which is lower than the other.

proc dom::Min {a b} {
    return [expr {$a < $b ? $a : $b}]
}

# dom::Max --
#
#	Return the maximum of two numeric values
#
# Arguments:
#	a some value
#	b another value
#
# Results:
#	Returns the value which is greater than the other.

proc dom::Max {a b} {
    return [expr {$a > $b ? $a : $b}]
}

# dom::Boolean --
#
#	Return a boolean value
#
# Arguments:
#	b	value
#
# Results:
#	Returns 0 or 1

proc dom::Boolean b {
    regsub -nocase {^(true|yes|1|on)$} $b 1 b
    regsub -nocase {^(false|no|0|off)$} $b 0 b
    return $b
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
