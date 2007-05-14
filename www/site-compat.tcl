ad_page_contract {
  Accepts and translates deprecated master template variables.
  Writes a warning message to the log in each case.

  @author Lee Denison (lee@xarg.co.uk)
  @creation-date: 2007-02-18

  $Id$
}

if {![array exists doc]} {
    array set doc [list]
}

set translations [list \
    doc_type doc(type) \
    header_stuff head \
    on_load body(onload) \
]

foreach {from to} $translations {
    if {[info exists $from]} {
        ns_log warning "site-compat: [ad_conn file] uses deprecated property $from instead of $to."
        set $to [set $from]
    }
}
