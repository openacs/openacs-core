
<property name="context">{/doc/tsearch2-driver/ {Tsearch2 Driver}} {Tsearch2 Full-text Search Engine Driver for OpenACS
5.x}</property>
<property name="doc(title)">Tsearch2 Full-text Search Engine Driver for OpenACS
5.x</property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<h1>Tsearch2 Full-text Search Engine Driver for OpenACS 5.x</h1>
<p>Tsearch2 Driver provides full-text searching of a PostgreSQL
database by using PostgreSQL&#39;s tsearch2 FtsEngineDriver</p>
<h2>Requirements for this search implementation</h2>
<ul>
<li>OpenACS 5.x</li><li>PostgreSQL 7.3 or newer</li><li>PostgreSQL&#39;s <a href="http://openacs.org/xowiki/pages/en/postgresql-tsearch2">tsearch2
module installed</a>. (Pg versions 7.3 and 7.4 require a patch and
tsearch2.sql to be loaded into the database)</li><li>This package installed</li><li>search package to be mounted somewhere.</li><li>FtsEngineDriver parameter of search package set to
"tsearch2-driver".</li><li>indexing some data</li>
</ul>
<h2>
<a name="install-fts-engine" id="install-fts-engine"></a>Install OpenACS' Tsearch2 Full-Text
Search Package</h2>
<ol type="1">
<li><p>If you have not yet, install <a href="http://openacs.org/xowiki/pages/en/postgresql-tsearch2">PostgreSQL&#39;s
tsearch2 module</a>.</p></li><li><p>Click <code class="computeroutput"><span class="guilabel"><span class="guilabel">Admin</span></span></code> on the
top of the default home page. If prompted, log in with the account
and password you entered during install.</p></li><li><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install
software</span></span></code> link.</p></li><li><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install new
service</span></span></code> link.</p></li><li><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install</span></span></code> link
next to Tsearch2 Driver. If you have installed tsearch2 into your
PostgreSQL database, the installer will automatically enable
tsearch in your OpenACS database instance.</p></li><li><p>Restart AOLserver. Wait a minute, then browse back to the home
page.</p></li><li><p>Click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Admin</span></span></code> on the
top of the screen.</p></li><li><p>Click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Main Site
Administration</span></span></code> in the "Subsite
Administration" section.</p></li><li><p>Click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Site Map</span></span></code> in
the "Advanced Features" section.</p></li><li>
<p>Mount the Search interface in the site-map.</p><ol type="a">
<li><p>Click the <code class="computeroutput"><span class="guilabel"><span class="guilabel">new sub
folder</span></span></code> link on the Main Site line.</p></li><li><p>Type <strong class="userinput"><code>search</code></strong> and
click <code class="computeroutput"><span class="guibutton"><span class="guibutton">New</span></span></code>.</p></li><li><p>Click the <code class="computeroutput"><span class="guilabel"><span class="guilabel">new
application</span></span></code> link on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">search</span></span></code> line.</p></li><li><p>Type <strong class="userinput"><code>search</code></strong>
where it says <code class="computeroutput"><span class="guilabel"><span class="guilabel">untitled</span></span></code>,
choose <code class="computeroutput"><span class="guilabel"><span class="guilabel">search</span></span></code> from
the drop-down list, and click <code class="computeroutput"><span class="guibutton"><span class="guibutton">New</span></span></code>.</p></li><li><p>Click the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Parameters</span></span></code>
link next to the Search package instance.</p></li><li><p>Type <strong class="userinput"><code>tsearch2-driver</code></strong> where it says
<code class="computeroutput"><span class="guilabel"><span class="guilabel">openfts-driver</span></span></code> in the <code class="computeroutput"><span class="guilabel"><span class="guilabel">FtsEngineDriver</span></span></code> parameter.</p></li>
</ol>
</li><li><p>Restart AOLserver. Wait a minute, then click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Main
Site</span></span></code> at the top of the page.</p></li>
</ol>
<h3 class="title">
<a name="install-fts-content-provider" id="install-fts-content-provider"></a>Enable Full Text Search in
packages</h3>
<p>Weblogger (lars-blogger), ETP (edit-this-page), and a few other
packages have code to generate indexed content. We are using
lars-blogger to illustrate how to enable Full Text Search in
packages.</p>
<ol type="1">
<li>
<p>Install the lars-blogger package, if it is not yet
installed.</p><ol type="a">
<li><p>Click <code class="computeroutput"><span class="guilabel"><span class="guilabel">Admin</span></span></code> on the
top of the default home page. If prompted, log in with the account
and password you entered during install.</p></li><li><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install
software</span></span></code> link.</p></li><li><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install new
application</span></span></code> link.</p></li><li><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install</span></span></code> link
next to Weblogger.</p></li><li><p>Install all required packages as well (always say okay until you
shall restart the server)</p></li>
</ol>
</li><li>
<p>Loading the service contracts datamodel and enabling the service
contract usually happens when the package is installed. However,
Lars-blogger may require manually loading
lars-blogger-sc-create.sql to get it to register the service
contract implementation that indexes the content:</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd packages/lars-blogger/sql/postgresql</code></strong>
[$OPENACS_SERVICE_NAME postgresql]$ <strong class="userinput"><code>psql $OPENACS_SERVICE_NAME -f lars-blogger-sc-create.sql</code></strong>
</pre>
</li><li><p>Restart AOLserver.</p></li>
</ol>
<p>Full Text Search should be enabled now, if not consult <a href="http://openacs.org/forums/message-view?message_id=154759">http://openacs.org/forums/message-view?message_id=154759</a>.
This link also contains some hints on how to make sure it is
enabled.</p>
<h2>Indexing data</h2>
<p>Once tsearch2-driver is installed, add some content to be
indexed.</p>
<h3>Adding search indexing to packages</h3>
<p>Standard coding practice is to put indexing code in
package-key/sql/postgresql/package-key-sc-create.sql. View these
examples for how to implement:</p>
<ul>
<li><a href="https://github.com/openacs/edit-this-page/blob/master/sql/postgresql/edit-this-page-create.sql">
packages/edit-this-page/sql/postgresql/edit-this-page-sc-create.sql</a></li><li><a href="https://github.com/openacs/lars-blogger/blob/master/sql/postgresql/lars-blogger-sc-create.sql">
packages/lars-blogger/sql/postgresql/lars-blogger-sc-create.sql</a></li>
</ul>
<h2>Indexing pre-existing content that has been indexed before</h2>
<p>If your pre-existing content has been indexed before (e.g.
because the search package was mounted before as part of a previous
search service), you have to tell the search package to
reindex:</p>
<pre>
    insert into search_observer_queue (
            select <em>my_id</em>, now(),'INSERT' from <em>my_table</em>
            );
  </pre>
<p>For forums and ETP this looks like:</p>
<pre>
    insert into search_observer_queue (
            select message_id, now(), 'INSERT' from forums_messages
            );
    insert into search_observer_queue (
            select live_revision, now(), 'INSERT' from (
                    select live_revision from cr_items where content_type = 'etp_page_revision'
                    ) 
            etp );
</pre>
<h2>Implementation notes</h2>
<p>This version includes only the most basic features. Many options
are possible by adding admin configurable parameters. The current
service contract definitions are not flexible enough to work well
with every possible search driver, so some features may require
making some improvements to the search package also.</p>
<h2>Release Notes</h2>
<p>Please file bugs in the <a href="http://openacs.org/bugtracker/openacs/">Bug Tracker</a>.</p>
<p>Dave Bauer dave\@thedesignexperience.org 2004-06-05</p>
