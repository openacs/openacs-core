ad_page_contract {
    @author Mark Dettinger (mdettinger@arsdigita.com)
    @creation-date 2000-10-24
    @cvs-id $Id$
} {
    host
    root:integer
}

# Flush the cache
util_memoize_flush_regexp "rp_lookup_node_from_host"

db_dml host_node_insert {
    insert into host_node_map 
    (host, node_id)
    values 
    (:host, :root)
}

ad_returnredirect index
