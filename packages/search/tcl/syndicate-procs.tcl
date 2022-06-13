ad_library {
    Syndication callback and support routines.

    @author Jeff Davis (davis@xarg.net)
    @cvs-id $Id$
}

ad_proc -public -callback search::action -impl syndicate {} {
    create or replace the record in the syndication table for
    the given object_id

    See photo-album-search-procs for an example of what
    you need to do in the FtsContentProvider datasource
    proc to make something syndicable.

    JCD: to fix: should not just glue together XML this way, also assumes rss 2.0, no provision for
    alternate formats, assumes content:encoded will be defined in the wrapper.
} {
    if {![parameter::get -boolean \
              -package_id [apm_package_id_from_key search] \
              -parameter Syndicate \
              -default 0]} {
        return
    }
    if {$action eq "DELETE"} {
        db_dml nuke {delete from syndication where object_id = :object_id}
    } else {
        upvar $datasource d

        if {![info exists d(syndication)]} {
            return
        }

        array set syn {
            category {}
            author {}
            guid {}
        }

        array set syn $d(syndication)

        set object_id $d(object_id)
        set url $syn(link)
        set body $d(content)

        set published [lc_time_fmt $syn(pubDate) "%a, %d %b %Y %H:%M:%S GMT"]

        set xmlMap [list & "&amp;" < "&lt;" > "&gt;" \" "&quot;" ' "&apos;"]
        set rss_xml_frag " <item>
  <title>[string map $xmlMap $d(title)]</title>
  <link>[string map $xmlMap $url]</link>
  <guid isPermaLink=\"true\">[string map $xmlMap $syn(guid)]</guid>
  <description>[string map $xmlMap $syn(description)]</description>
  <author>[string map $xmlMap $syn(author)]</author>
  <content:encoded><!\[CDATA\[$body]]></content:encoded>
  <category>[string map $xmlMap $syn(category)]</category>
  <pubDate>$published</pubDate>
 </item>"

        db_dml nuke {delete from syndication where object_id = :object_id}

        #
        # Null character is forbidden in a database bind variable. We
        # replace it with the empty string when found.
        #
        set sanitized 0
        incr sanitized [regsub -all \x00 $rss_xml_frag {} rss_xml_frag]
        incr sanitized [regsub -all \x00 $body {} body]
        #
        # If we had to sanitize the content, we complain in the server
        # log: probably one of the binary-to-text conversion is broken
        # or needs to be revised.
        #
        if {$sanitized > 0} {
            ad_log warning "Attempt to introduce forbidden characters in the syndication table by object ${object_id}"
        }

        db_dml insert {insert into syndication(object_id, rss_xml_frag, body, url)
            values (:object_id, :rss_xml_frag, :body, :url)
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
