ad_page_contract {
    Rebuild server
} {
    server:notnull
}

exec sudo /usr/local/bin/rebuild-server.sh $server >& /web/master/www/rebuild-$server.log &

ad_returnredirect /rebuild-$server.log



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
