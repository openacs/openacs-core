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
    if {![parameter::get -boolean -package_id [apm_package_id_from_key search] -parameter Syndicate -default 0]} {
        return
    }
    if {[string equal $action DELETE]} {
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

        set rss_xml_frag " <item>
  <title>$d(title)</title>
  <link>$url</link>
  <guid isPermaLink=\"true\">$syn(guid)</guid>
  <description>$syn(description)</description>
  <author>$syn(author)</author>
  <content:encoded><!\[CDATA\[$body]]></content:encoded>
  <category>$syn(category)</category>
  <pubDate>$published</pubDate>
 </item>"

        db_dml nuke {delete from syndication where object_id = :object_id}
        db_dml insert {insert into syndication(object_id, rss_xml_frag, body, url) values (:object_id, :rss_xml_frag, :body, :url)}
    }
}
