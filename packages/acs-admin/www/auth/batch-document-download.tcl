ad_page_contract {
    Download a whole batch xml document.

    @author Peter Marklund
} {
    job_id:integer
}

set document [db_string select_document {
    select document
    from auth_batch_jobs
    where job_id = :job_id
}]

ns_return 200 text/plain $document
