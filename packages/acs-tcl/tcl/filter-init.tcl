#
# Register filters to block certain requests.
#
# Examples:

#----------------------------------------------------
# Block over-eager bots on slow pages
#----------------------------------------------------
#ns_register_filter postauth GET /bugtracker/* \
#    ::util::reject_anonymous_on_high_load_filter \
#    -what "bugtracker request" \
#    -pools [list ""] \
#    -max_running 3 \
#    -max_queued 10 \
#    -retry_after 60

#
#----------------------------------------------------
#  Reject vulnerability scan CVE-2026-35273 for Oracle
#  PeopleSoft. Avoid false positive in vunerability scans.
#----------------------------------------------------
#ns_register_filter -first preauth POST /PSEMHUB/* \
#    ::util::reject_request_filter "PeopleSoft probe"</pre>

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
