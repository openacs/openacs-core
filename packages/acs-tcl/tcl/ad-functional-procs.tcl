# ad-functional-procs.tcl

ad_library {

    Functional Programming in Tcl? - Absolutely!

    This library adds the expressive power of functional languages
    like LISP, Gofer or Haskell to the Tcl language!

    If you don't know what functional programming is,
    here's a good place to start:
    <ul>
    <li>
    <a href="https://www.haskell.org/get-started/">https://www.haskell.org/get-started/</a>
    </li>
    <li>
    <a href="https://www.cse.chalmers.se/~rjmh/Papers/whyfp.pdf">https://www.cse.chalmers.se/~rjmh/Papers/whyfp.pdf</a>
    </li>
    </ul>

    A general naming convention in this file is:
    f  = a function
    x  = an element
    xs = a list of elements

    This library was completely rewritten on July 18, 2000.  The
    design is now much cleaner. Constructed functions are no longer
    represented by strings, but by real (callable) function
    objects. The auxiliary functions eval_unary and eval_binary are
    gone.

    Special thanks go to Sarah Arnold and Carsten Clasohm for
    extensive testing of this library and using it in the Sharenet
    project.  Also many thanks to Branimir Dolicki for inventing the
    lambda function and to Archit Shah for finding a simple way to
    eliminate its memory leak.

    This was part of ACS 3.

    Added to OpenACS by bdolicki on 11 Feb 2004: I just converted
    proc_doc to ad_proc, added ad_library, fixed an unmatched brace in
    a doc string and wrapped everything in a namespace.

    @author Mark Dettinger (mdettinger@arsdigita.com)
    @creation-date March 29, 2000

    @cvs-id $Id$
}

namespace eval ::f {

# --------------------------------------------------------------------------------
# Lambda
# --------------------------------------------------------------------------------

ad_proc -public lambda {args body} {

    The lambda function - one of the foundations of functional
    programming - defines an anonymous proc and returns it. This is
    useful if you quickly need an auxiliary function for a small task.

    I know, I know - it looks sooo harmless. But it unleashes the real
    power of Tcl.  It defines a proc with name "args.body" (weird, but
    unique name) that takes "args" as arguments and has the body
    "body". Then, this proc is returned.

    Examples:
    [f::lambda {x} {expr $x*$x}] 5 = 25

    f::map [f::lambda {x} {expr $x*$x}] {1 2 3 4 5} = {1 4 9 16 25}

    f::zip_with [f::lambda {x y} {return "$x and $y"}] {1 2 3} {4 5 6}
    = "1 and 4" "2 and 5" "3 and 6"

    Note:
    Although lambda defines a proc and therefore consumes memory,
    executing the same lambda expression twice will just re-define
    this proc.  Thus, there is no memory leak, if you have a lambda
    inside a loop.

    @return a proc name
} {
    #
    # To make the lambda proc universally accessible, we need to
    # create a fully-qualified name in the global namespace.
    #
    set name $args.$body
    regsub -all :: $name __ name
    set name ::__acs_lambda_$name

    proc $name $args $body
    return $name
}

# --------------------------------------------------------------------------------
# binding values to arguments of a function
# --------------------------------------------------------------------------------

ad_proc -public bind {f args} {
    Binds args to the first k arguments of the n-ary function f and
    returns the resulting (n-k)-ary function.
} {
    set i 0
    foreach arg $args {
        append code "set [lindex [info args $f] $i] {$arg}\n"
        incr i
    }
    append code [info body $f]
    set proc_args [info args $f]
    set num_proc_args [llength $proc_args]
    lambda [lrange $proc_args [llength $args] $num_proc_args] $code
}

ad_proc -public bind2nd {f arg} {
    Binds arg to the 2nd argument of f.
} {
    set code "set [lindex [info args $f] 1] {$arg}\n"
    append code [info body $f]
    set proc_args [info args $f]
    set num_proc_args [llength $proc_args]
    lambda [cons [head $proc_args] [lrange $proc_args 2 $num_proc_args]] $code
}

# --------------------------------------------------------------------------------
# We now define several binary operators as procs, so we can pass them
# as arguments to other functions.
# --------------------------------------------------------------------------------

proc +  {a b} {expr {$a +  $b}}
proc -  {a b} {expr {$a -  $b}}
proc *  {a b} {expr {$a *  $b}}
proc /  {a b} {expr {$a /  $b}}
proc && {a b} {expr {$a && $b}}
proc || {a b} {expr {$a || $b}}
proc >  {a b} {expr {$a >  $b}}
proc <  {a b} {expr {$a <  $b}}

# Example:
# + 5 6 = 11

# --------------------------------------------------------------------------------
# map
# --------------------------------------------------------------------------------

ad_proc -public map {f xs} {

    Takes a function f and a list { x1 x2 x3 ...}, applies the
    function on each element of the list and returns the result,
    i.e. { f x1, f x2, f x3, ...}.

    Examples:
    (fib = fibonacci function, sqr = square function)

    Applying a function to each element of a list:
    f::map fib [list 0 1 2 3 4 5 6 7 8] = {0 1 1 2 3 5 8 13 21}

    Applying a function to each element of a matrix (a list of lists)
    can be done with a nested call:
    f::map [f::lambda {row} {f::map sqr $row}] [list [list 1 2 3] [list 4 5 6]] = {{1 4 9} {16 25 36}}

} {
    lmap x $xs {$f $x}
}

# --------------------------------------------------------------------------------
# fold
# --------------------------------------------------------------------------------

ad_proc -public fold {f e xs} {
    Takes a binary function f, a start element e and a list {x1 x2
    ...}  and returns f (...(f (f (f e x1) x2) x3)...).

    Examples:
    f::fold + 0 [list 1 2 3 4] = 10
    f::fold * 1 [list 1 2 3 4] = 24
} {
    set result $e
    foreach x $xs {
        set result [$f $result $x]
    }
    return $result
}

ad_proc -public fold1 {f xs} {
    Takes a binary function f and a list {x1 x2 x3 ...}  and returns
    (...(f (f (f x1 x2) x3) x4)...).

    "fold1" behaves like "fold", but does not take a start element and
    does not work for empty lists.

    Examples:
    f::fold1 min [list 3 1 4 1 5 9 2 6] = 1

    f::fold1 max [list 3 1 4 1 5 9 2 6] = 9

    @see fold1
} {
    if { [null_p $xs] } {
        error "ERROR: fold1 is undefined for empty lists."
    } else {
        fold $f [head $xs] [tail $xs]
    }
}

# --------------------------------------------------------------------------------
# scanl
# --------------------------------------------------------------------------------

ad_proc -public scanl {f e xs} {
    Takes a binary function f, a start element e and a list {x1 x2
    ...}  and returns {e (f e x1) (f (f e x1) x2) ...}.

    Example:
    scanl + 0 [list 1 2 3 4] = {0 1 3 6 10}
    scanl * 1 [list 1 2 3 4] = {1 1 2 6 24}
} {
    set current_element $e
    set result [list $e]
    foreach x $xs {
        set current_element [$f $current_element $x]
        lappend result $current_element
    }
    return $result
}

ad_proc -public scanl1 {f xs} {
    Takes a binary function f and a list {x1 x2 x3 ...}  and returns
    {x1 (f x1 x2) (f (f x1 x2) x3) ...}.

    "scanl1" behaves like "scanl", but does not take a start element
    and does not work for empty lists.

    Examples:
    scanl1 min [list 3 1 4 1 5 9 2 6] = {3 1 1 1 1 1 1 1}

    scanl1 max [list 3 1 4 1 5 9 2 6] = {3 3 4 4 5 9 9 9}

    @see scanl
} {
    if { [null_p $xs] } {
        error "ERROR: scanl1 is undefined for empty lists."
    } else {
        scanl $f [head $xs] [tail $xs]
    }
}

# --------------------------------------------------------------------------------
# Standard combinators
# --------------------------------------------------------------------------------

ad_proc -public id {x} {
    Identity function: just returns its argument.

    I'm not kidding! An identity function can be useful sometimes,
    e.g.  as a default initializer for optional arguments of
    functional kind.
} {
    return $x
}

# Example application of id function:

ad_proc -public qsort {
    xs
    {value id}
} {
    Sorts a sequence with the quicksort algorithm.

    Examples:
    f::qsort {5 2 9 4} = 2 4 5 9

    f::qsort {Oracle ArsDigita SAP Vignette} [lambda {s} {string
    length $s}] = {SAP Oracle Vignette ArsDigita}
} {
    if { [llength $xs]<2 } { return $xs }
    set pivot [head $xs]
    set big_elmts {}
    set small_elmts {}
    foreach x [tail $xs] {
        if { [$value $x] > [$value $pivot] } {
            lappend big_elmts $x
        } else {
            lappend small_elmts $x
        }
    }
    concat [qsort $small_elmts $value] [list $pivot] [qsort $big_elmts $value]
}

ad_proc -public const {k} {

    Returns a unary function that ignores its argument and constantly
    returns k.

    Example:
    f::map [f::const 7] [list 1 2 3 4 5] = {7 7 7 7 7}

} {
    lambda {x} [list return $k]
}

ad_proc -public curry {f args} {
    Converts a function that takes one tuple as an argument
    into a function that takes a series of single arguments.
} {
    uplevel [list $f $args]
}

ad_proc -public uncurry {f tuple} {
    Converts a function that takes a series of single arguments into a
    function that takes one tuple as an argument.

    Example:
    f::min 3 5 = 3
    f::min {3 5} = error (because min expects two arguments)
    f::uncurry min {3 5} = 3
} {
    uplevel [list eval "$f $tuple"]
}

# Exercise 1
# ----------
# Using "map" and "uncurry", convert the tuple list
# {{3 1} {4 1} {5 9} {2 6}} into {1 1 5 2} (each tuple is replaced
# by the minimum of its two components).

ad_proc -private fst {xs} {
    @return the first element of a list
} {
    lindex $xs 0
}

ad_proc -private snd {xs} {
    @return the second element of a list
} {
    lindex $xs 1
}

ad_proc -private thd {xs} {
    @return the third element of a list
} {
    lindex $xs 2
}

# Example:
# set people [db_list_of_lists get "select first_name, last_name, email ..."]
# set first_names [map fst $people]
# set last_names  [map snd $people]
# set emails      [map thd $people]

ad_proc -public flip {f a b} {
    Takes a binary function 'f' and two arguments 'a' and 'b' and
    returns f b a (arguments are flipped).

    Example:
    flip lindex 0 {42 37 59 14} = 42
} {
    $f $b $a
}

# Exercise 2
# ----------
# Using "fold", "map", "flip" and "lindex",
# compute the sum of the 4th column of the matrix
# [list [list 3 1 4 1 5]
#       [list 9 2 6 5 3]
#       [list 5 8 9 7 9]
#       [list 3 2 3 8 4]]
# Hint:
# First try to extract the list {1 5 7 8} using "map", "flip" and "lindex",
# then reduce it to 21 using "fold".

ad_proc -public compose {f g x} {
    function composition: evaluates f (g x)

    Example:
    f::map [f::bind compose sqr [f::bind + 7]] {1 2 3 4 5} = {64 81 100 121 144}

    Algebraic Property:
    f::map [f::bind f::compose f g] $xs = f::map f [f::map g $xs]

} {
    $f [$g $x]
}

# --------------------------------------------------------------------------------
# Standard numerical functions
# --------------------------------------------------------------------------------

ad_proc -public abs {x} {
    @return the absolute value of x
} {
    expr {$x<0 ? -$x : $x}
}

ad_proc -public gcd {x y} {
    @return the greatest common divisor of x and y
} {
    gcd' [abs $x] [abs $y]
}

proc gcd' {x y} {
    if { $y==0 } { return $x }
    gcd' $y [expr {$x%$y}]
}

ad_proc -public lcm {x y} {
    @return the least common multiple of x and y
} {
    if { $x==0 || $y == 0 } { return 0 }
    abs [expr {$x/[gcd $x $y]*$y}]
}

ad_proc -public odd_p {n} {
    @return 1 if n is odd and 0 otherwise
} {
    expr {$n%2}
}

ad_proc -public even_p {n} {
    @return 1 if n is even and 0 otherwise
} {
    expr {1-$n%2}
}

ad_proc -public min {x y} {
    @return the minimum of x and y
} {
    expr {$x<$y ? $x : $y}
}

ad_proc -public max {x y} {
    @return the maximum of x and y
} {
    expr {$x>$y ? $x : $y}
}

# --------------------------------------------------------------------------------
# List Aggregate Functions
# --------------------------------------------------------------------------------

ad_proc -public and {xs} {
    Reduces a list of boolean values using &&

    Examples:
    f::and {1 1 0 1} = 0

    f::and {1 1 1 1} = 1

    @return boolean
} {
    fold && 1 $xs
}

ad_proc -public or {xs} {
    Reduces a list of boolean values using ||

    Example:
    f::or {1 1 0 1} = 1
    f::or {0 0 0 0} = 0

    @return boolean
} {
    fold || 0 $xs
}

ad_proc -public all {pred xs} {

    Takes a predicate pred and a list xs and returns 1 if all elements
    of xs fulfill pred.

    Examples:
    f::all f::even_p {2 44 64 80 10} = 1

    f::all f::even_p {2 44 65 80 10} = 0

    @return boolean
} {
    and [map $pred $xs]
}

ad_proc -public any {pred xs} {

    Takes a predicate pred and a list xs and returns 1 if there exists
    an element of xs that fulfills pred.

    Examples:
    f::any f::odd_p {2 44 64 80 10} = 0

    f::any odd_p {2 44 65 80 10} = 1

    @return boolean
} {
    or [map $pred $xs]
}

ad_proc -public lmin {xs} {
    @return the minimum element of the list xs
} {
    fold1 min $xs
}

ad_proc -public lmax {xs} {
    @return the maximum element of the list xs
} {
    fold1 max $xs
}

ad_proc -public sum {xs} {
    @return the sum of the elements of the list xs
} {
    fold + 0 $xs
}

ad_proc -public product {xs} {
    @return the product of the elements of the list xs
} {
    fold * 1 $xs
}

ad_proc -public sums {xs} {
    @return the list of partial sums of the list xs
} {
    scanl + 0 $xs
}

ad_proc -public products {xs} {
    @return the list of partial products of the list xs
} {
    scanl * 1 $xs
}

# --------------------------------------------------------------------------------
# Standard list processing functions
# --------------------------------------------------------------------------------

ad_proc -public head {xs} {
    @return first element of a list
} {
    lindex $xs 0
}

ad_proc -public last {xs} {
    @return last element of a list
} {
    lindex $xs [expr {[llength $xs]-1}]
}

ad_proc -public init {xs} {
    @return all elements of a list but the last
} {
    lrange $xs 0 end-1
}

ad_proc -public tail {xs} {
    @return all elements of a list but the first
} {
    lrange $xs 1 end
}

ad_proc -public take {n xs} {
    @return the first n elements of xs
} {
    lrange $xs 0 ${n}-1
}

ad_proc -public drop {n xs} {
    @return the remaining elements of xs (without the first n)
} {
    lrange $xs $n end
}

ad_proc -public filter {pred xs} {

    Examples:
    f::filter f::even_p {3 1 4 1 5 9 2 6} = {4 2 6}

    f::filter [f::lambda {x} {expr $x>500}] {317 826 912 318} = {826 912}

    @return all elements of the list 'xs' that fulfill the predicate
            'pred'.
} {
    lmap x $xs {
        if { ![$pred $x] } {
            continue
        }
        set x
    }
}

ad_proc -public copy {n x} {
    Example:
    f::copy 10 7 = {7 7 7 7 7 7 7 7 7 7}

    @return list of n copies of x
} {
    set result {}
    for {set i 0} {$i<$n} {incr i} {
        lappend result $x
    }
    return $result
}

ad_proc -public cycle {n xs} {
    Example:
    f::cycle 4 {1 2 3} = {1 2 3 1 2 3 1 2 3 1 2 3}

    @return concatenated list of n copies of xs
} {
    set result {}
    for {set i 0} {$i<$n} {incr i} {
        lappend result {*}$xs
    }
    return $result
}

ad_proc -public cons {x xs} {
    Inserts x at the front of the list xs.

    @return list
} {
    list $x {*}$xs
}

ad_proc -deprecated reverse {xs} {
    Reverses the list xs.

    Tcl has a built-in support for reversing lists: "lreverse".
    Use this instead.

    @see lreverse
} {
    f::fold [f::bind f::flip f::cons] {} $xs
}

ad_proc -public elem_p {x xs} {
    Checks if x is contained in s.

    @return boolean
} {
    expr {$x in $xs}
}

ad_proc -public not_elem_p {x xs} {
    Checks if x is not contained in s.

    @return boolean
} {
    expr {$x ni $xs}
}

ad_proc -public nub {xs} {
    Removes duplicates from xs.
} {
    set result [list]
    lmap x $xs {
        if { $x in $result } {
            continue
        }
        lappend result $x
        set x
    }
}

ad_proc -public null_p {xs} {
    Checks if xs is the empty list.

    @return boolean
} {
    expr {[llength $xs]==0}
}

ad_proc -public enum_from_to {lo hi} {
    Generates {lo lo+1 ... hi-1 hi}

    @return list
} {
    set result {}
    for {set i $lo} {$i<=$hi} {incr i} {
        lappend result $i
    }
    return $result
}

# --------------------------------------------------------------------------------
# zip and zip_with functions
# --------------------------------------------------------------------------------

ad_proc -public zip {args} {
    Takes two lists {x1 x2 x3 ...} and {y1 y2 y3 ...} and returns a
    list of tuples {x1 y1} {x2 y2} {x3 y3} ...

    Works analogously with 3 or more lists.

    Example:
    % set first_names {Nicole Tom}
    % set last_names  {Kidman Cruise}

    f::zip $first_names $last_names = {{Nicole Kidman} {Tom Cruise}}

    f::map [f::bind f::flip join _] [f::zip $first_names $last_names]
    = Nicole_Kidman Tom_Cruise
} {
    transpose $args
}

ad_proc -public zip_with {f xs ys} {
    Takes two lists {x1 x2 x3 ...} and {y1 y2 y3 ...} and returns the
    list {(f x1 y1) (f x2 y2) (f x3 y3) ...}

    Example:
    % set first_names {Sandra Catherine Nicole}
    % set last_names  {Bullock Zeta-Jones Kidman}

    f::zip_with [f::lambda {f l} {return "$f $l"}] $first_names
    $last_names = {{Sandra Bullock} {Catherine Zeta-Jones} {Nicole Kidman}}

} {
    lmap x $xs y $ys {
        if {[llength $x] == 0 || [llength $y] == 0} {
            continue
        }
        $f $x $y
    }
}

ad_proc -public transpose {lists} {
    Transposes a matrix (a list of lists)
} {
    set num_lists [llength $lists]
    if {!$num_lists} { return "" }
    for {set i 0} {$i<$num_lists} {incr i} {
        set l($i) [lindex $lists $i]
    }
    set result {}
    while {1} {
        set element {}
        for {set i 0} {$i<$num_lists} {incr i} {
            if {[null_p $l($i)]} { return $result }
            lappend element [head $l($i)]
            set l($i) [tail $l($i)]
        }
        lappend result $element
    }

    # Note: This function takes about n*n seconds
    #       to transpose a (100*n) x (100*n) matrix.
    #       Pretty fast, don't you think? :)
}

# --------------------------------------------------------------------------------
# Other Functions (that maybe are too weird for the ACS)
# --------------------------------------------------------------------------------

ad_proc -public iterate {n f x} {

    Examples:
    f::iterate 10 [f::lambda {x} {expr $x+1}] 5 = {5 6 7 8 9 10 11 12 13 14}

    f::iterate 10 [f::lambda {x} {expr $x*2}] 1 = {1 2 4 8 16 32 64 128 256 512}

    f::iterate 4 f::tail {1 2 3 4 5} = {{1 2 3 4 5} {2 3 4 5} {3 4 5} {4 5}}

    @return \{x (f x) (f (f x) (f (f (f x))) ...\}\}.
} {
    set result {}
    for {set i 0} {$i<$n} {incr i} {
        lappend result $x
        set x [$f $x]
    }
    return $result
}

ad_proc -public unzip {xs} {

    Unzip takes a list of tuples {x1 y1} {x2 y2} {x3 y3} ... and
    returns a tuple of lists {x1 x2 x3 ...} {y1 y2 y3 ...}.

    It is just a special case of the function "transpose" and is here
    just for completeness.

} {
    set left {}
    set right {}
    foreach x $xs {
        # assertion: x is a tuple
        lappend left [lindex $x 0]
        lappend right [lindex $x 1]
    }
    return [list $left $right]
}

# --------------------------------------------------------------------------------
# List breaking functions: To gain a real advantage from using these functions,
# you would actually need a language that has "lazy evaluation" (like Haskell).
# In Tcl they can be useful too, but they are not as powerful.
# --------------------------------------------------------------------------------

ad_proc -public split_at {n xs} {
    Splits a list using take and drop.

    Usage: split_at n xs = (take n xs, drop n xs)
} {
    list [take $n $xs] [drop $n $xs]
}

ad_proc -public take_while {p xs} {
    @return the longest initial segment of xs whose elements satisfy p
} {
    lmap x $xs {
        if { ![$p $x] } { break }
        set x
    }
}

ad_proc -public drop_while {p xs} {
    @return the remaining portion of the list
} {
    set index 0
    foreach x $xs {
        if { ![$p $x] } { break }
        incr index
    }
    drop $index $xs
}

ad_proc -public span {p xs} {
    Splits a list using take_while and drop_while.

    Usage span p xs = (takeWhile p xs, dropWhile p xs)
} {
    list [take_while $p $xs] [drop_while $p $xs]
}

ad_proc -public take_until {p xs} {
    @return the list of elements up to and including the first element
    of xs which satisfies p
} {
    set index 0
    foreach x $xs {
        incr index
        if { [$p $x] } { break }
    }
    take $index $xs
}

# --------------------------------------------------------------------------------
# Tests and Experiments
# --------------------------------------------------------------------------------

ad_proc -public factorial {n} {
    Compute n!
} {
    product [enum_from_to 1 $n]
}

ad_proc -public mul {n fraction} {
    Multiplies n with a fraction (given as a tuple)
} {
    set num [fst $fraction]
    set denom [snd $fraction]
    set g [gcd $n $denom]
    expr {($n/$g)*$num/($denom/$g)}
}

ad_proc -public choose {n k} {
    Here's how to compute 'n choose k' like a real nerd.
} {
    fold mul 1 [transpose [list [iterate $k [bind flip - 1] $n] [enum_from_to 1 $k]]]
}

ad_proc -public pascal {size} {
    Prints Pascal's triangle
} {
    for {set n 0} {$n<=$size} {incr n} {
        puts [map [bind choose $n] [enum_from_to 0 $n]]
    }
}

ad_proc -public prime_p {n} {

    Example:
    f::filter f::prime_p [f::enum_from_to 1 100] = {2 3 5 7 11 13 17
    19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97}

    @return boolean, 1 if n is prime
} {
    if { $n<2 } { return 0 }
    if { $n==2 } { return 1 }
    if { [even_p $n] } { return 0 }
    for {set i 3} {$i*$i<=$n} {incr i 2} {
        if { $n%$i==0 } { return 0 }
    }
    return 1
}

proc multiplication_table {x} {
    # This is an extreme example for test purposes only.
    # This way of programming is not recommended. Kids: do not try this at home.
    flip join \n [map [bind compose [bind flip join ""] [bind map [bind compose \
        [lambda {s} {format %4d $s}] product]]] \
        [map transpose [transpose [list [map [bind copy $x] [enum_from_to 1 $x]] \
        [copy $x [enum_from_to 1 $x]]]]]]
}

# --------------------------------------------------------------------------------
# Literature about functional programming on the web
# --------------------------------------------------------------------------------

# http://www.haskell.org/aboutHaskell.html
# https://www.cse.chalmers.se/~rjmh/Papers/whyfp.pdf

namespace export *

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
