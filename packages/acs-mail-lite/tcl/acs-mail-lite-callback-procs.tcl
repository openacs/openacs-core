# packages/acs-mail-lite/tcl/acs-mail-lite-callback-procs.tcl

ad_library {
    
    Callback procs for acs-mail-lite
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-15
    @arch-tag: d9aec4df-102d-4b0d-8d0e-3dc470dbe783
    @cvs-id $Id$
}

ad_proc -public -callback acs_mail_lite::complex_send {
    {-package_id:required}
    {-from_party_id:required}
    {-to_party_id:required}
    {-body}
    {-message_id:required}
    {-subject}
    {-object_id}
    {-file_ids}
} {
    Malte: please document this
} -

ad_proc -public -callback acs_mail_lite::send {
    {-package_id:required}
    {-from_party_id:required}
    {-to_party_id:required}
    {-body}
    {-message_id:required}
    {-subject}
} {
    Malte: please document this
} -
