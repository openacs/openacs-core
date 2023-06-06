ad_library {
    Tests for api in tcl/ad-functional-procs.tcl
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        f::abs
        f::cons
        f::lambda
        f::map
        f::fib
        f::fold
        f::fold1
        f::scanl
        f::scanl1
        f::null_p
        f::head
        f::tail
        f::id
        f::qsort
        f::const
        f::curry
        f::uncurry
        f::flip
        f::min
        f::compose
        f::bind
        f::bind2nd
        f::and
        f::or
        f::even_p
        f::odd_p
        f::all
        f::any
        f::filter
        f::copy
        f::cycle
        f::zip
        f::unzip
        f::transpose
        f::zip_with
        f::iterate
        f::prime_p
        f::enum_from_to
        f::take
        f::take_while
        f::take_until
        f::drop
        f::drop_while
        f::elem_p
        f::not_elem_p
        f::factorial
        f::product
        f::products
        f::gcd
        f::init
        f::last
        f::lcm
        f::lmax
        f::lmin
        f::max
        f::min
        f::mul
        f::nub
        f::span
        f::split_at
        f::sum
        f::sums
    } \
    functional_api {
        Test the functional api
    } {
        #
        # These tests cover the API where tests were not provided.
        #
        aa_equals "abs returns expected" \
            [f::abs 1] 1
        aa_equals "abs returns expected" \
            [f::abs -1] 1
        aa_equals "abs returns expected" \
            [f::abs a] a
        aa_equals "cons returns expected" \
            [f::fold [f::bind f::flip f::cons] {} {1 2 3 4}] \
            [lreverse {1 2 3 4}]
        aa_equals "drop returns expected" \
            [f::drop 3 {1 2 3 4}] \
            4
        aa_equals "drop_while returns expected" \
            [f::drop_while f::odd_p {1 3 5 7 2 3 4}] \
            {2 3 4}
        aa_true "elem_p returns expected" \
            [f::elem_p 7 {1 3 5 7 2 3 4}]
        aa_false "not_elem_p returns expected" \
            [f::not_elem_p 7 {1 3 5 7 2 3 4}]
        package require math
        aa_true "factorial returns expected" {
            [f::factorial 10] == [::math::factorial 10]
        }
        aa_equals "gcd returns expected" \
            [f::gcd 15 30] 15
        aa_equals "gcd returns expected" \
            [f::gcd 15 25] 5
        aa_equals "lcm returns expected" \
            [f::lcm 15 30] 30
        aa_equals "lcm returns expected" \
            [f::lcm 15 25] 75
        aa_equals "init returns expected" \
            [f::init {1 2 3 4}] {1 2 3}
        aa_equals "last returns expected" \
            [f::last {1 2 3 4}] 4
        aa_equals "last returns expected" \
            [f::last {1 2 3 4}] 4
        aa_equals "lmax returns expected" \
            [f::lmax {1 2 3 4}] 4
        aa_equals "lmin returns expected" \
            [f::lmin {1 2 3 4}] 1
        aa_equals "max returns expected" \
            [f::max 2 4] 4
        aa_equals "min returns expected" \
            [f::min 2 4] 2
        aa_true "mul returns expected" {
            [f::mul 2 {1 4}] == [expr {2 / 4}]
        }
        aa_equals "nub returns expected" \
            [f::nub {1 2 3 5 3 2 4 5 1 2 3 4 5}] \
            {1 2 3 5 4}
        aa_equals "span returns expected" \
            [f::span f::odd_p {1 2 3 4 5 6 7 8 9 0}] \
            {1 {2 3 4 5 6 7 8 9 0}}
        aa_equals "split_at returns expected" \
            [f::split_at 3 {1 2 3 4 5 6 7 8 9 0}] \
            {{1 2 3} {4 5 6 7 8 9 0}}
        aa_equals "sum returns expected" \
            [f::sum {1 2 3 4 5 6 7 8 9 0}] \
            45
        aa_equals "sums returns expected" \
            [f::sums {1 2 3 4 5 6 7 8 9 0}] \
            {0 1 3 6 10 15 21 28 36 45 45}
        aa_equals "take_until returns expected" \
            [f::take_until f::odd_p {2 4 6 7 8 9 0}] \
            {2 4 6 7}
        proc __test_bind2nd {a b} {
            expr {$a + $b}
        }
        aa_equals "bind2nd returns expected" \
            [[f::bind2nd __test_bind2nd 3] 5] 8
        proc __test_curry {l} {
            llength $l
        }
        aa_equals "curry returns expected" \
            [f::curry __test_curry 1 2 3 4 5] 5
        aa_equals "products returns expected" \
            [f::products {1 2 3 4 5}] \
            {1 1 2 6 24 120}
        aa_equals "unzip returns expected" \
            [f::unzip {{"x1" "y1"} {"x2" "y2"} {"x3" "y3"}}] \
            {{x1 x2 x3} {y1 y2 y3}}

        #
        # These tests were ported from the comments in the source
        # code.
        #

        aa_equals "lambda returns expected" \
            [[f::lambda {x} {expr $x*$x}] 5] \
            25
        proc fib {n} {
            if {$n <= 0} {
                return 0
            }
            if {$n == 1} {
                return 1
            }
            return [expr {[fib [expr {$n - 1}]] + [fib [expr {$n - 2}]]}]
        }
        aa_equals "map of fib returns expected" \
            [f::map fib [list 0 1 2 3 4 5 6 7 8]] \
            {0 1 1 2 3 5 8 13 21}
        proc sqr {n} {
            return [expr {int(pow($n,2))}]
        }
        aa_equals "map of lambda returns expected" \
            [f::map [f::lambda {row} {f::map ::sqr $row}] [list [list 1 2 3] [list 4 5 6]]] \
            {{1 4 9} {16 25 36}}
        aa_equals "map of lambda returns expected" \
            [f::map [f::lambda {x} {expr $x*$x}] {1 2 3 4 5}] \
            {1 4 9 16 25}
        aa_equals "fold returns expected" \
            [f::fold + 0 [list 1 2 3 4]] \
            10
        aa_equals "fold returns expected" \
            [f::fold * 1 [list 1 2 3 4]] \
            24
        aa_equals "fold1 returns expected" \
            [f::fold1 min [list 3 1 4 1 5 9 2 6]] \
            1
        aa_true "fold1 fails on empty list" [catch {
            f::fold1 min {}
        }]
        aa_equals "fold1 returns expected" \
            [f::fold1 max [list 3 1 4 1 5 9 2 6]] \
            9
        aa_equals "scanl returns expected" \
            [f::scanl + 0 [list 1 2 3 4]] \
            {0 1 3 6 10}
        aa_equals "scanl returns expected" \
            [f::scanl * 1 [list 1 2 3 4]] \
            {1 1 2 6 24}
        aa_equals "scanl1 returns expected" \
            [f::scanl1 min [list 3 1 4 1 5 9 2 6]] \
            {3 1 1 1 1 1 1 1}
        aa_equals "scanl1 returns expected" \
            [f::scanl1 max [list 3 1 4 1 5 9 2 6]] \
            {3 3 4 4 5 9 9 9}
        aa_true "scanl1 fails on empty list" [catch {
            f::scanl1 min {}
        }]
        aa_equals "id returns itself" \
            [f::id 2] 2
        aa_equals "qsort returns expected" \
            [f::qsort {5 2 9 4}] {2 4 5 9}
        aa_equals "qsort returns expected" \
            [f::qsort {Oracle ArsDigita SAP Vignette} [f::lambda {s} {string length $s}]] \
            {SAP Oracle Vignette ArsDigita}
        aa_equals "const returns expected" \
            [f::map [f::const 7] [list 1 2 3 4 5]] \
            {7 7 7 7 7}
        aa_equals "uncurry returns expected" \
            [f::uncurry f::min {3 5}] \
            3
        aa_equals "flip returns expected" \
            [f::flip lindex 0 {42 37 59 14}] \
            42
        aa_equals "compose returns expected" \
            [f::map [f::bind f::compose sqr [f::bind + 7]] {1 2 3 4 5}] \
            {64 81 100 121 144}
        aa_equals "and returns expected" \
            [f::and {1 1 0 1}] \
            0
        aa_equals "and returns expected" \
            [f::and {1 1 1 1}] \
            1
        aa_equals "or returns expected" \
            [f::or {1 1 0 1}] \
            1
        aa_equals "or returns expected" \
            [f::or {0 0 0 0}] \
            0
        aa_equals "all returns expected" \
            [f::all f::even_p {2 44 64 80 10}] \
            1
        aa_equals "all returns expected" \
            [f::all f::even_p {2 44 65 80 10}] \
            0
        aa_equals "any returns expected" \
            [f::any f::odd_p {2 44 64 80 10}] \
            0
        aa_equals "any returns expected" \
            [f::any f::odd_p {2 44 65 80 10}] \
            1
        aa_equals "filter returns expected" \
            [f::filter f::even_p {3 1 4 1 5 9 2 6}] \
            {4 2 6}
        aa_equals "filter returns expected" \
            [f::filter [f::lambda {x} {expr $x>500}] {317 826 912 318}] \
            {826 912}
        aa_equals "copy returns expected" \
            [f::copy 10 7] \
            {7 7 7 7 7 7 7 7 7 7}
        aa_equals "cycle returns expected" \
            [f::cycle 4 {1 2 3}] \
            {1 2 3 1 2 3 1 2 3 1 2 3}
        set first_names {Nicole Tom}
        set last_names  {Kidman Cruise}
        aa_equals "zip returns expected" \
            [f::zip $first_names $last_names] \
            {{Nicole Kidman} {Tom Cruise}}
        aa_equals "zip returns expected" \
            [f::map [f::bind f::flip join _] [f::zip $first_names $last_names]] \
            {Nicole_Kidman Tom_Cruise}
        set first_names {Sandra Catherine Nicole}
        set last_names  {Bullock Zeta-Jones Kidman}
        aa_equals "zip_with returns expected" \
            [f::zip_with [f::lambda {f l} {return "$f $l"}] $first_names $last_names] \
            {{Sandra Bullock} {Catherine Zeta-Jones} {Nicole Kidman}}
        aa_equals "iterate returns expected" \
            [f::iterate 10 [f::lambda {x} {expr $x+1}] 5] \
            {5 6 7 8 9 10 11 12 13 14}
        aa_equals "iterate returns expected" \
            [f::iterate 10 [f::lambda {x} {expr $x*2}] 1] \
            {1 2 4 8 16 32 64 128 256 512}
        aa_equals "iterate returns expected" \
            [f::iterate 4 f::tail {1 2 3 4 5}] \
            {{1 2 3 4 5} {2 3 4 5} {3 4 5} {4 5}}
        aa_equals "prime_p returns expected" \
            [f::filter f::prime_p [f::enum_from_to 1 100]] \
            {2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97}
}
