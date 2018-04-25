
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating an Existing Tcl Page}</property>
<property name="doc(title)">Templating an Existing Tcl Page</property>
<master>
<h2>Templating an Existing Tcl Page</h2>
<a href="">Templating System</a>
 : Migration
<h3>In a Nutshell</h3>

When templatizing a legacy Tcl page, your task is to
<strong>separate</strong>
 code and graphical presentation. The
latter goes into an ADP file; it contains essentially HTML,
augmented by a few special tags and the
<code>\@<em>variable</em>\@</code>
 construct. The code goes into a
Tcl script. In other words, a templated page consists of two files,
a Tcl part that puts its results in data sources, and an ADP page
(the template), into which these data sources will be interpolated
to yield a complete HTML page.
<h3>General</h3>
<p>As usual, the Tcl page should start with a call to
<code>ad_page_contract</code>. In its <code>-properties</code>
block you promise the data sources that your script will provide;
they were earlier called <em>page properties</em>, hence the name
of the option. Then your script performs all the computations and
queries needed to define these data sources. There are special
mechanisms for handling multirow data sources; see below.</p>
<p>At the end of the Tcl script, you should call
<code>ad_return_template</code>. The template runs after the Tcl
script, and can use these data sources.</p>
<p>Make sure that the fancy adp parser is enabled in your AOL ini
file.</p>
<pre>
      [ns/server/myserver/adp]
      DefaultParser=fancy</pre>
<p>A few more hints</p>
<ul>
<li>Do not write to the connection directly. Avoid
<code>ns_puts</code>, <code>ns_write</code> etc., which don&#39;t
wait till the headers are written or the page is completed; they
may act differently than you expect.</li><li>If you can, put code in the Tcl file, not between <code>&lt;%
%&gt;</code> in the adp page.</li><li>Put HTML in the adp page, not int the Tcl program. Put reusable
HTML fragments in a separate adp file (think of it as a widget)
that will be <code>&lt;include&gt;</code>d from several pages.
Prefer this to writing a Tcl proc that returns HTML.</li><li>Remember to remove backslashes where you had to escape special
characters, as in
<blockquote><pre>Nuts  <font color="red">\</font>$2.70 <font color="red">\</font>[&lt;a href="<font color="red">\</font>"shoppe<font color="red">\</font>"&gt;buy&lt;/a&gt;<font color="red">\</font>]
          </pre></blockquote>
</li>
</ul>
<h3>Forms</h3>

There is nothing special about building forms; just use the
<code>&lt;form&gt;</code>
 tag as always. All HTML tags can be used
in the ADP file (template).
<h3>A simple page</h3>
<p>First I take a page from the news package as an example. For
simplicity, I pick <code>item-view</code>, which does not use a
<code>&lt;form&gt;</code>. I reformatted it a bit to make three
panes fit next to each other and to line up corresponding code.</p>
<table cellspacing="5" bgcolor="#CCDDFF">
<tr bgcolor="#CCCCCC">
<th rowspan="2">old Tcl code</th><th colspan="2">new</th>
</tr><tr bgcolor="#CCCCCC">
<th><code>packages/news/www/item-view.tcl</code></th><th><code>packages/news/www/item-view.adp</code></th>
</tr><tr>
<td valign="top"><pre>
# /packages/news/admin/index.tcl
ad_page_contract {

    View a news item.

    \@author Jon Salz (jsalz\@arsdigita.com)
    \@creation-date 11 Aug 2000
    \@cvs-id $&zwnj;Id$

} {
    news_item_id:integer,notnull
}








db_1row news_item_select {
    select *
    from news_items
    where news_item_id = :news_item_id
}

set body "
[ad_header $title]
&lt;h2&gt;$title&lt;/h2&gt;
[ad_context_bar [list "" "News"] $title]

&lt;hr&gt;

&lt;p&gt;Released $release_date:

&lt;blockquote&gt;
$body
&lt;/blockquote&gt;

[ad_footer]
"

<font color="red">doc_return 200 text/html $body
return</font>
</pre></td><td valign="top"><pre>

ad_page_contract {

    View a news item.

    \@author Jon Salz (jsalz\@arsdigita.com)
    \@creation-date 11 Aug 2000
    \@cvs-id $&zwnj;Id$

} {
    news_item_id:integer,notnull
} <font color="green">-properties {
  body:onevalue
  release_date:onevalue
  title:onevalue
  header:onevalue
  context_bar:onevalue
  footer:onevalue
}</font>

db_1row news_item_select {
    select *
    from news_items
    where news_item_id = :news_item_id
}




set context_bar [ad_context_bar \
    [list "" "News"] $title]











ad_return_template
          </pre></td><td valign="top"><pre>


























&lt;master&gt;
&lt;property name="doc(title)"&gt;\@title\@&lt;/property&gt;
&lt;property name="context"&gt;\@context;noquote\@&lt;/property&gt;

&lt;hr&gt;

&lt;p&gt;Released \@release_date\@:

&lt;blockquote&gt;
\@body\@
&lt;/blockquote&gt;

          </pre></td>
</tr>
</table>
<h3>Multi-Row Data Sources</h3>

Technically, the result of a query that may return multiple rows is
stored in several arrays. This datasource is filled by a call to
<code>db_multirow</code>
, and the repeating part of the HTML output
is produced by the <code>&lt;multiple&gt;</code>
 tag. The following
example shows the part of the <code>index</code>
 page of the News
module that uses the mechanism, not a whole page.
<table cellspacing="5" bgcolor="#CCDDFF">
<tr bgcolor="#CCCCCC">
<th rowspan="2">old Tcl code</th><th colspan="2">new</th>
</tr><tr bgcolor="#CCCCCC">
<th><code>packages/news/www/index.tcl</code></th><th><code>packages/news/www/index.adp</code></th>
</tr><tr>
<td valign="top"><pre><font color="#999999">ad_page_contract {

    Displays a list of 
    available news items.

    \@param archive_p show archived
                      news items?
    \@author Jon Salz (jsalz\@mit.edu)
    \@creation-date 11 Aug 2000
    \@cvs-id $&zwnj;Id$
} {
}</font></pre></td><td valign="top"><pre>
<font color="#999999">ad_page_contract {

    Displays a list of available
    news items.

    \@param archive_p show archived
                      news items?
    \@author Jon Salz (jsalz\@mit.edu)
    \@creation-date 11 Aug 2000
    \@cvs-id $&zwnj;Id$
} {
} -properties {
  header:onevalue
  context_bar:onevalue
  subsite_id:onevalue
  subsite:multirow
</font><strong>item</strong>:multirow<font color="#999999">
  footer:onevalue
}</font>
</pre></td><td> </td>
</tr><tr bgcolor="#CCCCCC">
<td align="center"><strong>...</strong></td><td align="center"><strong>...</strong></td><td align="center"><strong>...</strong></td>
</tr><tr>
<td valign="top"><pre>
append body "
&lt;ul&gt;
"

<font color="red">db_foreach</font> news_items_select {
    select news_item_id, title
    from news_items_obj
    where context_id = :subsite_id
    and sysdate &gt;= release_date
    and (   expiration_date is null
         or expiration_date &gt; sysdate)
} {
    append body "&lt;li&gt;&lt;a href="
        \"item-view?news_item_id=<font color="b" lue="">"\
        "</font>$news_item_id\"
        &gt;$title&lt;/a&gt;\n"


} if_no_rows {
    append body "&lt;li&gt;There are 
        currently no news items
        available.\n"
}

append body "
&lt;p&gt;&lt;li&gt;You can use the &lt;a href=
    \"admin/\"&gt;administration
    interface&lt;/a&gt; to post a new
    item (there&#39;s currently no
    security in place).

&lt;/ul&gt;
"</pre></td><td valign="top"><pre>
<font color="green">db_multirow <strong>item</strong>
</font> news_items_select {
    select news_item_id, title
    from news_items_obj
    where context_id = :subsite_id
    and sysdate &gt;= release_date
    and (   expiration_date is null
         or expiration_date &gt; sysdate)
}
          </pre></td><td valign="top"><pre>

&lt;ul&gt;


&lt;multiple name=<strong>item</strong>&gt;







  &lt;li&gt;&lt;a href=
      "item-view?news_item_id=<font color="b" lue="">&lt;%
      %&gt;</font>\@<strong>item</strong>.news_item_id\@"
      &gt;\@<strong>item</strong>.title\@&lt;/a&gt;
&lt;/multiple&gt;

&lt;if \@<strong>item</strong>:rowcount\@ eq 0&gt;
  &lt;li&gt;There are
  currently no news items
  available.
&lt;/if&gt;


&lt;p&gt;&lt;li&gt;You can use the &lt;a href=
  "admin/"&gt;administration
  interface&lt;/a&gt; to post a new
  item (there&#39;s currently no
  security in place).

&lt;/ul&gt;
          </pre></td>
</tr>
</table>

Notes:
<ul>
<li>I use the general <code>&lt;if&gt;</code> construct to handle
the case when no lines are returned. (The
<code>&lt;multiple&gt;</code> loop just executes zero times.)</li><li>For a list of the available tags, refer to <a href="http://bob.sf.arsdigita.com:8089/ats/doc">the templating
documentation</a>.</li><li>Blue color marks additional syntax necessary to wrap lines
short.</li><li>The proc <code>db_multirow</code> does have a code block and an
optional <code>if_no_rows</code> block, just like
<code>db_foreach</code>. They aren&#39;t used in the example,
though.</li>
</ul>
<p>If you have a more complicated db_foreach, where logic is
performed inside the body, then it might be helpful to build your
own multirow variable. In the excert below, taken from
/pvt/alerts.tcl and /pvt/alerts.adp, the foreach logic made it hard
to use the db_multirow because it needed a combination of the
output from sql and also the output of Tcl procedures using that
value.</p>
<table cellspacing="5" bgcolor="#CCDDFF">
<tr bgcolor="#CCCCCC">
<th rowspan="2">old Tcl code</th><th colspan="2">new</th>
</tr><tr bgcolor="#CCCCCC">
<th><code>packages/acs-core-ui/www/pvt/alerts.tcl</code></th><th><code>packages/acs-core-ui/www/pvt/alerts.adp</code></th>
</tr><tr>
<td valign="top"><pre><font color="#999999">ad_page_contract {
    \@cvs-id $&zwnj;Id: migration.html,v 1.4 2017/08/07 23:48:02 gustafn Exp $
} {
}</font></pre></td><td valign="top"><pre>
<font color="#999999">ad_page_contract {
    \@cvs-id $&zwnj;Id: migration.html,v 1.4 2017/08/07 23:48:02 gustafn Exp $
} {
} -properties {
    header:onevalue
    decorate_top:onevalue
    ad_footer:onevalue</font>
    discussion_forum_alert_p:onevalue
    bboard_keyword_p:onevalue
    bboard_rows:multirow<font color="#999999">
    classified_email_alert_p:onevalue
    classified_rows:multirow
    gc_system_name:onevalue
}</font>
</pre></td><td> </td>
</tr><tr bgcolor="#CCCCCC">
<td align="center"><strong>...</strong></td><td align="center"><strong>...</strong></td><td align="center"><strong>...</strong></td>
</tr><tr>
<td valign="top"><pre>


if { [db_table_exists "bboard_email_alerts"] } {
 
 set counter 0








 db_foreach alerts_list "
 <font color="#999999">select bea.valid_p, bea.frequency,
        bea.keywords, bt.topic, bea.rowid
 from bboard_email_alerts bea, bboard_topics bt
 where bea.user_id = :user_id
 and bea.topic_id = bt.topic_id
 order by bea.frequency</font>" {
   incr counter

   if { $valid_p == "f" } {
     <font color="#999999"># alert has been disabled </font>
     set status "<font color="#999999">Disabled</font>"
     set action "
     <font color="#999999">&lt;a href="\"/bboard/alert-reenable\"&gt;
"     Re-enable&lt;/a&gt;</font>"
   } else {
     <font color="#999999"># alert is enabled</font>
     set status "
     <font color="#999999">&lt;font color=red&gt;Enabled&lt;/font&gt;</font>"
     set action "
     <font color="#999999">&lt;a href="\"/bboard/alert-disable\"&gt;
"     Disable&lt;/a&gt;</font>"
   }

   append existing_alert_rows "<font color="#999999">&lt;tr&gt;
   &lt;td&gt;$status&lt;/td&gt;
   &lt;td&gt;$action&lt;/td&gt;
   &lt;td&gt;$topic&lt;/td&gt;
   &lt;td&gt;$frequency&lt;/td&gt;</font>"

   if { [bboard_pls_blade_installed_p] == 1 } {
     append existing_alert_rows "
     <font color="#999999">&lt;td&gt;\"$keywords\"&lt;/td&gt;</font>"
   }
   append existing_alert_rows "<font color="#999999">&lt;/tr&gt;\n</font>"

 }

 if  { $counter &gt; 0 } {
   set wrote_something_p 1
   set keyword_header ""
   if { [bboard_pls_blade_installed_p] == 1 } {
     set keyword_header "<font color="#999999">&lt;th&gt;Keywords&lt;/th&gt;</font>"
   }
   append page_content "
   <font color="#999999">&lt;h3&gt;Your discussion forum alerts&lt;/h3&gt;

   &lt;blockquote&gt;
   &lt;table&gt;
   &lt;tr&gt;
   &lt;th&gt;Status&lt;/th&gt;
   &lt;th&gt;Action&lt;/th&gt;
   &lt;th&gt;Topic&lt;/th&gt;
   &lt;th&gt;Frequency&lt;/th&gt;
   $keyword_header
   &lt;/tr&gt;

   $existing_alert_rows
   &lt;/table&gt;
   &lt;/blockquote&gt;</font>
   "
 }
}
          </pre></td><td valign="top"><pre>
set discussion_forum_alert_p 0

if { [db_table_exists "bboard_email_alerts"] } {
  set discussion_forum_alert_p 1

  set rownum 0

  if { [bboard_pls_blade_installed_p] == 1 } {
    set bboard_keyword_p 1
  } else {
    set bboard_keyword_p 0
  }
        
  db_foreach alerts_list "
  <font color="#999999">select bea.valid_p, bea.frequency,
         bea.keywords, bt.topic, bea.rowid
  from bboard_email_alerts bea, bboard_topics bt
  where bea.user_id = :user_id
  and bea.topic_id = bt.topic_id
  order by bea.frequency</font>" {
  incr rownum

  if { $valid_p == "<font color="#999999">f</font>" } {
    <font color="#999999"># alert has been disabled for some reason</font><font color="green">set bboard_rows:[set rownum](status) "<font color="#999999">disable</font>"
    set bboard_rows:[set rownum](action_url) "
    <font color="#999999">/bboard/alert-reenable</font>"</font>
  } else {
    <font color="#999999"># alert is enabled</font><font color="green">set bboard_rows:[set rownum](status) "<font color="#999999">enable</font>"
    set bboard_rows:[set rownum](action_url) "
    <font color="#999999">/bboard/alert-disable</font>"</font>
  }

  <font color="green">set bboard_rows:[set rownum](topic) $topic
  set bboard_rows:[set rownum](frequency) $frequency
  set bboard_rows:[set rownum](keywords) $keywords</font>
        
  } if_no_rows {
    set discussion_forum_alert_p 0
  }
  set bboard_rows:rowcount $rownum
  
}

          
          </pre></td><td valign="top"><pre>













&lt;if \@discussion_forum_alert_p\@ eq 1&gt;

<font color="#999999">&lt;h3&gt;Your discussion forum alerts&lt;/h3&gt;

&lt;blockquote&gt;
   &lt;table&gt;
   &lt;tr&gt;&lt;th&gt;Status&lt;/th&gt;
       &lt;th&gt;Action&lt;/th&gt;
       &lt;th&gt;Topic&lt;/th&gt;
       &lt;th&gt;Frequency&lt;/th&gt;</font>
     &lt;if \@bboard_keyword_p\@ eq 1&gt;
       <font color="#999999">&lt;th&gt;Keyword&lt;/th&gt;</font>
     &lt;/if&gt;
   <font color="#999999">&lt;/tr&gt;</font>
 &lt;multiple name=bboard_rows&gt;

   <font color="#999999">&lt;tr&gt;</font>
      &lt;if \@bboard_rows.status\@ eq "enabled"&gt;
       <font color="#999999">&lt;td&gt;&lt;font color=red&gt;Enabled&lt;/font&gt;&lt;/td&gt;
       &lt;td&gt;&lt;a href="\@bboard_rows.action_url\@"&gt;
       Disable&lt;/a&gt;&lt;/td&gt;</font>
      &lt;/if&gt;
      &lt;else&gt;
       <font color="#999999">&lt;td&gt;Disabled&lt;/td&gt;
       &lt;td&gt;&lt;a href="\@bboard_rows.action_url\@"&gt;
       Re-enable&lt;/a&gt;&lt;/td&gt;</font>
      &lt;/else&gt;
       <font color="#999999">&lt;td&gt;\@bboard_rows.topic\@&lt;/td&gt;
       &lt;td&gt;\@bboard_rows.frequency\@&lt;/td&gt;</font>
     &lt;if \@bboard_rows.bboard_keyword_p\@ eq 1&gt;
       <font color="#999999">&lt;td&gt;\@keyword&lt;/td&gt;</font>
     &lt;/if&gt;
   <font color="#999999">&lt;/tr&gt;</font>
 
 &lt;/multiple&gt;
   <font color="#999999">&lt;/table&gt;
&lt;/blockquote&gt; </font>

&lt;/if&gt;
          </pre></td>
</tr>
</table>
<hr>
<address>
<a href="mailto:christian\@arsdigita.com">Christian
Brechbühler</a>, <a href="mailto:iwashima\@mit.edu">Hiro
Iwashima</a>
</address>

Last modified: $&zwnj;Id: migration.html,v 1.4 2017/08/07 23:48:02
gustafn Exp $
