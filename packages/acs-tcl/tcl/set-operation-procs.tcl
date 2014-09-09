ad_library {

    Simple set-manipulation procedures.

    @creation-date 19 January 2001
    @author Eric Lorenzo (elorenzo@arsdigita.com)
    @cvs-id $Id$
}







ad_proc -deprecated set_member? { s v } {
    <p>Tests whether or not $v is a member of set $s.</p>
} {
    if {$v ni $s} {
	return 0
    } else {
	return 1
    }
}



ad_proc -deprecated set_append! { s-name v } {
    <p>Adds the element v to the set named s-name in the calling
    environment, if it isn't already there.</p>
} {
    upvar $s-name s
    
    if { ![set_member? $s $v] } {
	lappend s $v
    }
}



ad_proc -deprecated set_union { u v } {
    <p>Returns the union of sets $u and $v.</p>
} {
    set result $u

    foreach ve $v {
	if { ![set_member? $result $ve] } {
	    lappend result $ve
	}
    }

  return $result
}

ad_proc -deprecated set_union! { u-name v } {
    <p>Computes the union of the set stored in the variable
    named $u-name in the calling environment and the set v,
    sets the variable named $u-name in the calling environment
    to that union, and also returns that union.</p>
} {
    upvar $u-name u

    foreach ve $v {
	if { ![set_member? $u $ve] } {
	    lappend u $ve
	}
    }

    return $u
}




ad_proc -deprecated set_intersection { u v } {
    <p>Returns the intersection of sets $u and $v.</p>
} {
    set result [list]
    
    foreach ue $u {
	if { [set_member? $v $ue] } {
	    lappend result $ue
	}
    }

    return $result
}

ad_proc -deprecated set_intersection! { u-name v } {
    <p>Computes the intersection of the set stored in the variable
    named $u-name in the calling environment and the set v,
    sets the variable named $u-name in the calling environment
    to that intersection, and also returns that intersection.</p>
} {
    upvar $u-name u
    set result [list]
    
    foreach ue $u {
	if { [set_member? $v $ue] } {
	    lappend result $ue
	}
    }

    set u $result
    return $result
}





ad_proc -deprecated set_difference { u v } {
    <p>Returns the difference of sets $u and $v.  (i.e. The set of all
    members of u that aren't also members of $v.)</p>
} {
    set result [list]

    foreach ue $u {
	if { ![set_member? $v $ue] } {
	    lappend result $ue
	}
    }

    return $result    
}

ad_proc -deprecated set_difference! { u-name v } {
    <p>Computes the difference of the set stored in the variable
    named $u-name in the calling environment and the set v,
    sets the variable named $u-name in the calling environment
    to that difference, and also returns that difference.</p>
} {
    upvar $u-name u
    set result [list]

    foreach ue $u {
	if { ![set_member? $v $ue] } {
	    lappend result $ue
	}
    }

    set u $result
    return $result
}

