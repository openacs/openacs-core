ad_library {

    Utility ad_procs for Tcl <-> JSON conversion.

    This is based on the tcllib json package written by Andreas Kupries, and
    later rewritten to parse via regular expressions by Thomas Maeder.

    The tcllib version suffers from generating Tcl structures from JSON strings
    with no type (JSON array or object) information.  The resulting structures can't
    be converted back to JSON strings, you have to munge them with type information
    first.  And the code making use the Tcl structure also needs to know whether each
    field is an object or array.

    It also depends on the DICT package or Tcl 8.5.

    This rewrite doesn't depend on DICT, declares procs using ad_proc (so the API
    will be picked up by our API browser), and is symmetrical (you can convert from
    JSON to the Tcl representation and back again).

    I've not renamed internal variables in the typical OpenACS style.

    I've placed these in the global util namespace for two reasons:

    1. Don't want to clash with the tcllib json package in case someone else
       decides to use it.

    2. Might put it in acs-tcl as part of the utility stuff someday.

    More information ...

    See http://www.json.org/ && http://www.ietf.org/rfc/rfc4627.txt

    Total rework of the code published with version number 1.0 by
    Thomas Maeder, Glue Software Engineering AG

    @creation-date 2010/04/09
    @author Don Baccus
    @cvs-id $Id$
}

namespace eval util {
    namespace eval json {
        namespace eval array {}
        namespace eval object {}

        # Regular expression for tokenizing a JSON text (cf. http://json.org/)

        # tokens consisting of a single character
        variable singleCharTokens { "{" "}" ":" "\\[" "\\]" "," }
        variable singleCharTokenRE "\[[join $singleCharTokens {}]\]"

        # quoted string tokens
        variable escapableREs { "[\\\"\\\\/bfnrt]" "u[[:xdigit:]]{4}" }
        variable escapedCharRE "\\\\(?:[join $escapableREs |])"
        variable unescapedCharRE {[^\\\"]}
        variable stringRE "\"(?:$escapedCharRE|$unescapedCharRE)*\""

        # (unquoted) words
        variable wordTokens { "true" "false" "null" }
        variable wordTokenRE [join $wordTokens "|"]

        # number tokens
        # negative lookahead (?!0)[[:digit:]]+ might be more elegant, but
        # would slow down tokenizing by a factor of up to 3!
        variable positiveRE {[1-9][[:digit:]]*}
        variable cardinalRE "-?(?:$positiveRE|0)"
        variable fractionRE {[.][[:digit:]]+}
        variable exponentialRE {[eE][+-]?[[:digit:]]+}
        variable numberRE "${cardinalRE}(?:$fractionRE)?(?:$exponentialRE)?"

        # JSON token
        variable tokenRE "$singleCharTokenRE|$stringRE|$wordTokenRE|$numberRE"


        # 0..n white space characters
        set whiteSpaceRE {[[:space:]]*}

        # Regular expression for validating a JSON text
        variable validJsonRE "^(?:${whiteSpaceRE}(?:$tokenRE))*${whiteSpaceRE}$"
    }
}

ad_proc -private util::json::validate {jsonText} {

    Validate JSON text

    @param jsonText JSON text
    @return 1 iff $jsonText conforms to the JSON grammar
            (@see http://json.org/)
} {

    variable validJsonRE

    return [regexp -- $validJsonRE $jsonText]
}

ad_proc util::json::parse {jsonText} {

    Parse JSON text into a Tcl list.

    @param jsonText JSON text
    @return List containing the object represented by jsonText

} {
    variable tokenRE

    set tokens [regexp -all -inline -- $tokenRE $jsonText]
    set nrTokens [llength $tokens]
    set tokenCursor 0
    return [parseValue $tokens $nrTokens tokenCursor]
}

ad_proc -private util::json::unexpected {tokenCursor token expected} {
    Throw an exception signaling an unexpected token
} {
    return -code error "unexpected token \"$token\" at position $tokenCursor; expecting $expected"
}

ad_proc -private util::json::unquoteUnescapeString {token} {
    Get rid of the quotes surrounding a string token and substitute the
    real characters for escape sequences within it

    @param token
    @return Unquoted, unescaped value of the string contained in token
} {
    set unquoted [string range $token 1 end-1]
    return [subst -nocommands -novariables $unquoted]
}

ad_proc -private util::json::parseObjectMember {tokens nrTokens tokenCursorName objectDictName} {

     Parse an object member

     @param tokens list of tokens
     @param nrTokens length of $tokens
     @param tokenCursorName name (in caller's context) of variable
            holding current position in $tokens
     @param objectDictName name (in caller's context) of dict
            representing the JSON object of which to
            parse the next member
} {

    upvar $tokenCursorName tokenCursor
    upvar $objectDictName objectDict

    set token [lindex $tokens $tokenCursor]
    incr tokenCursor

    set leadingChar [string index $token 0]
    if {$leadingChar eq "\""} {
        set memberName [unquoteUnescapeString $token]

        if {$tokenCursor == $nrTokens} {
            unexpected $tokenCursor "END" "\":\""
        } else {
            set token [lindex $tokens $tokenCursor]
            incr tokenCursor

            if {$token eq ":"} {
                set memberValue [parseValue $tokens $nrTokens tokenCursor]
                lappend objectDict $memberName $memberValue
            } else {
                unexpected $tokenCursor $token "\":\""
            }
        }
    } else {
        unexpected $tokenCursor $token "STRING"
    }
}

ad_proc -private util::json::parseObjectMembers {tokens nrTokens tokenCursorName objectDictName} {

    Parse the members of an object

    @param tokens list of tokens
    @param nrTokens length of $tokens
    @param tokenCursorName name (in caller's context) of variable
           holding current position in $tokens
    @param objectDictName name (in caller's context) of dict
           representing the JSON object of which to
           parse the next member
} {
    upvar $tokenCursorName tokenCursor
    upvar $objectDictName objectDict

    while true {
        parseObjectMember $tokens $nrTokens tokenCursor objectDict

        set token [lindex $tokens $tokenCursor]
        incr tokenCursor

        switch -exact $token {
            "," {
                # continue
            }
            "\}" {
                break
            }
            default {
                unexpected $tokenCursor $token "\",\"|\"\}\""
            }
        }
    }
}

ad_proc -private util::json::parseObject {tokens nrTokens tokenCursorName} {

    Parse an object

    @param tokens list of tokens
    @param nrTokens length of $tokens
    @param tokenCursorName name (in caller's context) of variable
           holding current position in $tokens
    @return parsed object (Tcl dict)
} {
    upvar $tokenCursorName tokenCursor

    if {$tokenCursor == $nrTokens} {
        unexpected $tokenCursor "END" "OBJECT"
    } else {
        set result {}

        set token [lindex $tokens $tokenCursor]

        if {$token eq "\}"} {
            # empty object
            incr tokenCursor
        } else {
            parseObjectMembers $tokens $nrTokens tokenCursor result
        }

        return [list _object_ $result]
    }
}

ad_proc -private util::json::parseArrayElements {tokens nrTokens tokenCursorName resultName} {

    Parse the elements of an array

    @param tokens list of tokens
    @param nrTokens length of $tokens
    @param tokenCursorName name (in caller's context) of variable
           holding current position in $tokens
    @param resultName name (in caller's context) of the list
           representing the JSON array
} {
    upvar $tokenCursorName tokenCursor
    upvar $resultName result

    while true {
        lappend result [parseValue $tokens $nrTokens tokenCursor]

        if {$tokenCursor == $nrTokens} {
            unexpected $tokenCursor "END" "\",\"|\"\]\""
        } else {
            set token [lindex $tokens $tokenCursor]
            incr tokenCursor

            switch -exact $token {
                "," {
                    # continue
                }
                "\]" {
                    break
                }
                default {
                    unexpected $tokenCursor $token "\",\"|\"\]\""
                }
            }
        }
    }
}

ad_proc -private util::json::parseArray {tokens nrTokens tokenCursorName} {

    Parse an array

    @param tokens list of tokens
    @param nrTokens length of $tokens
    @param tokenCursorName name (in caller's context) of variable
           holding current position in $tokens
    @return parsed array (Tcl list)
} {
    upvar $tokenCursorName tokenCursor

    if {$tokenCursor == $nrTokens} {
        unexpected $tokenCursor "END" "ARRAY"
    } else {
        set result {}

        set token [lindex $tokens $tokenCursor]

        set leadingChar [string index $token 0]
        if {$leadingChar eq "\]"} {
            # empty array
            incr tokenCursor
        } else {
            parseArrayElements $tokens $nrTokens tokenCursor result
        }

        return [list _array_ $result]
    }
}

ad_proc -private util::json::parseValue {tokens nrTokens tokenCursorName} {

    Parse a value

    @param tokens list of tokens
    @param nrTokens length of $tokens
    @param tokenCursorName name (in caller's context) of variable
           holding current position in $tokens
    @return parsed value (dict, list, string, number)
} {
    upvar $tokenCursorName tokenCursor

    if {$tokenCursor == $nrTokens} {
        unexpected $tokenCursor "END" "VALUE"
    } else {
        set token [lindex $tokens $tokenCursor]
        incr tokenCursor

        set leadingChar [string index $token 0]
        switch -exact -- $leadingChar {
            "\{" {
                return [parseObject $tokens $nrTokens tokenCursor]
            }
            "\[" {
                return [parseArray $tokens $nrTokens tokenCursor]
            }
            "\"" {
                # quoted string
                return [unquoteUnescapeString $token]
            }
            "t" -
            "f" -
            "n" {
                # bare word: true, false or null
                return $token
            }
            default {
                # number?
                if {[string is double -strict $token]} {
                    return $token
                } else {
                    unexpected $tokenCursor $token "VALUE"
                }
            }
        }
    }
}

ad_proc -private util::json::gen_inner {value} {
    Generate a JSON string for a sub-list of a Tcl JSON "object".

    @param value A list representing a JSON object/array or value
    @return Valid JSON object, array, or value string.

} {
    foreach { type arg } $value {
        switch -- $type {
            _object_ {
                return [util::json::object2json $arg]
            }
            _array_ {
                return [util::json::array2json $arg]
            }
            default {
                if { ![string is double -strict $value] 
                    && ![regexp {^(?:true|false|null)$} $value]} {
                    set value "\"$value\""
                }
                # Cleanup linebreaks
                regsub -all {\r\n} $value "\n" value
                regsub -all {\r} $value "\n" value
                # JSON requires new line characters be escaped
                regsub -all {\n} $value "\\n" value
                return $value
            }
         }
    }
}

ad_proc -private util::json::object2json {objectVal} {

    Generate a JSON string for a two-element Tcl JSON object list.

    @param objectVal [list object values]
    @return Valid JSON object string.
} {
    set values {}
    foreach {key val} $objectVal {
        if { $val eq "" } {
            lappend values "\"$key\":\"\""
        } else {
            lappend values "\"$key\":[util::json::gen_inner $val]"
        }
    }
    return "\{[join $values ,]\}"
}

ad_proc -private util::json::array2json {arrayVal} {

    Generate a JSON string for a two-element Tcl JSON array list.

    @param arrayVal [list array values]
    @return Valid JSON array string.
} {
    set values {}
    foreach val $arrayVal {
        if { $val eq "" } {
            lappend values "\"\""
        } else {
            lappend values [util::json::gen_inner $val]
        }
    }
    return "\[[join $values ,]\]"
}

ad_proc util::json::gen {value} {

    Top-level procedure to generate a JSON string from its Tcl list representation.

    @param value A two-element object/array Tcl list.
    @return A valid JSON string.

} {
    if { [llength $value] != 2 } {
        return -code error "Ill-formed JSON object: length in gen is [llength $value]"
    }
    return [util::json::gen_inner $value]
}

ad_proc util::json::json_value_to_sql_value {value} {

    While mysql happily treats false as 0, real SQL does not.  And we need to protect
    against apostrophes in strings.  And handle null.  You get the idea.

    @param value A value from a parsed JSON string
    @return Something that works in Real SQL, not to be confused with MySQL. This
            includes not trying to insert '' into columns of type real, when
            "null" is meant (we mimic Oracle bindvar/PG bindvar emulation semantics).
            The Ilias RTE JavaScript returns '' rather than null for JS null variables.

} {
    switch -- $value {
        false { return 0 }
        true { return 1 }
        null -
        "" { return null }
        default { return "[::ns_dbquotevalue $value]" }
    }
}

ad_proc util::json::sql_values_to_json_values {row} {

    Converts empty values to "null", consistent with how oracle, mysql, and
    the nspostgres bindvar hack treats them.

    @param row A row (list) returned by a sql SELECT.

    @return A new list with empty strings converted to null.

} {
    set new_row {}
    foreach value $row {
        if { $value eq "" } {
            lappend new_row null
        } else {
            lappend new_row $value
        }
    }
    return $new_row
}

ad_proc util::json::array::create {values} {

    Construct a JSON object with the given values list

} {
    return [list _array_ $values]
}

ad_proc util::json::array::get_values {item} {

    Verify that the given Tcl structure is an object, and return its
    values list.

} {
    if { [lindex $item 0] ne "_array_" } {
        return -code error "Expected \"_array_\", got \"[lindex $item 0]\""
    } else {
        return [lindex $item 1]
    }
}

ad_proc util::json::object::create {values} {

    Construct a JSON object with the given values list

} {
    return [list _object_ $values]
}

ad_proc util::json::object::get_values {item} {

    Verify that the given Tcl structure is an object, and return its
    values list.

} {
    if { [lindex $item 0] ne "_object_" } {
        return -code error "Expected \"_object_\", got \"[lindex $item 0]\""
    } else {
        return [lindex $item 1]
    }
}

ad_proc util::json::type_of {item} {

    Return the type of the item, "object" or "array"

} {
    switch [lindex $item 0] {
        _object_ { return object }
        _array_  { return array }
        default {
            return -code error "Expected \"_array_\" or \"_object_\", got \"[lindex $item 0]\""
        }
    }
}

ad_proc util::json::object::get_value {
    -object:required
    -attribute:required
} {
    Returns the value of an attribute in an object.  If the attribute doesn't exist,
    an error will result.

    @param object The JSON object which contains the attribute.
    @param attribute The attribute name.
    @return The attribute value or an error, if the attribute doesn't exist.
} {
    array set values [util::json::object::get_values $object]
    return $values($attribute)
}

ad_proc util::json::object::set_value {
    -object:required
    -attribute:required
    -value:required
} {
   Set an attribute value in an object structure.  If the attribute doesn't
   exist in the object, it's created.

   @param object The object we want to set the value in.
   @param attribute The name of the attribute.
   @param value The value to set attribute to.
   @return A new object with the attribute/value pair.
} {
    array set values [util::json::object::get_values $object]
    set values($attribute) $value
    return [util::json::object::create [array get values]]
}

ad_proc util::json::object::set_by_path {
    -object:required
    -path:required
    -value:required
} {
    This is an odd utility that mimics some odd code in the Ilias SCORM module, included
    here because it might be of more general use.  Essentially we walk down an object
    tree structure using the "path" parameter.  If we encounter a leaf on the way, we
    replace it with a new object node and continue.  The last element of the path is
    interpreted as a leaf of the tree and is set to "value".

    Example:

    util::json::gen [util::json::object::set_by_path -object "" -path {a b c} -value 3]

    Result:

    {"a":{"b":{"c":3}}}

    Example:

    util::json::gen \
        [util::json::object::set_by_path \
            -object [util::json::object::create \
                        [list a [util::json::object::create [list d null]]]] \
            -path {a b c} \
            -value 3]  
 
    Result:

    {"a":{"b":{"c":3},"d":null}}

    "a" is the top level object with two subnodes "b" and "d", with "b" having a subnode
    "c" of value 3, and "d" being a leaf of "a" with value "null".

    @param object The object to add subnodes to.
    @param path The path through the tree with the last value being the name of a new or
                existing leaf.
    @param value  The value to set the final leaf to.
    @return A new object with the new tree structure interwoven into it.
} {
    if { [llength $object] < 2 } {
        array set values ""
    } else {
        array set values [util::json::object::get_values $object]
    }
    if { [llength $path] == 0 } {
        return $value
    } else {
        if { ![info exists values([lindex $path 0])] } {
            set values([lindex $path 0]) ""
        }
        set values([lindex $path 0]) \
            [util::json::object::set_by_path \
                -object $values([lindex $path 0]) \
                -path [lrange $path 1 end] \
                -value $value]
        return [util::json::object::create [array get values]]
    }
}

ad_proc util::json::indent {
    -simplify:boolean
    json
} {
    Indent a JSON string to make it more easily digestable by the human mind.  This
    works best (by far) if the JSON string doesn't already contain newlines (as will
    be true of JSON strings generated by util::json::gen).

    @param simplify If true, remove all fields that don't contribute to the structure
                    of the object/array combination being described by the string.
    @param json The string to indent
    @return The beautifully indented, and optionally simplified, string
} {
    set indent -1
    set output ""
    set json [string map {, ,\n :\{ :\n\{ :\[ :\[\n} $json]
    foreach jsonette [split $json \n] {
        if { $simplify_p && ![regexp {[\{\[\}\]]} $jsonette] } {
            continue
        }
        set incr_indent [regexp "^\{" $jsonette]
        incr indent $incr_indent
        lappend output \
            [string repeat "    " $indent][expr { $incr_indent ? "" : " " }]${jsonette}
        incr indent \
            [expr {[regexp -all "\{" $jsonette]-$incr_indent-[regexp -all "\}" $jsonette]}]
    }
    return [join $output \n]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
