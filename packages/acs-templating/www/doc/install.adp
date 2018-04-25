
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System: Installation}</property>
<property name="doc(title)">Templating System: Installation</property>
<master>
<h2>Installation</h2>
<strong><a href="index">Templating System</a></strong>
<p>The templating system may be used alone or in conjunction with
version 4.0 or greater of the ArsDigita Community System (ACS). The
following instructions apply to a standalone installation only.</p>
<h3>Requirements</h3>
<p>The templating system requires version 3.1 or greater of
AOLserver for Unix or Windows. Until version 3.1 is officially
released, you must use the <a href="http://www.arsdigita.com/download/">ArsDigita distribution of
AOLserver 3.0</a>, which includes some required patches to the ADP
parser. These patches have been integrated into AOLserver 3.1.</p>
<p>To use the database interface for merging dynamic data with your
templates, you will also need to have installed any
AOLserver-compatible RDBMS.</p>
<h3>Obtaining the distribution</h3>
<p>To install the templating system, download and unpack the tar
file under your page root:</p>
<pre>$ wget http://bob.sf.arsdigita.com:8089/ats/ats.tar.gz
$ cd /web/myserver/www
$ gunzip -c ats.tar.gz | tar xvf -</pre>
<p>The distribution consists of four subdirectories:</p>
<ol>
<li>
<strong><kbd>demo</kbd></strong>: A set of sample templates and
supporting files.</li><li>
<strong><kbd>doc</kbd></strong>: Documentation and
tutorials.</li><li>
<strong><kbd>tcl</kbd></strong>: The Tcl module.</li><li>
<strong><kbd>resources</kbd></strong>: Sitewide style templates
for forms and error messages and associated assets.</li>
</ol>
<p>You can also untar (or check out) the distribution somewhere
else and symlink it under your page root. (If you do not wish to
install the distribution under your page root, see the
configuration options below).</p>
<h3>Installing the Tcl module</h3>
<p>The templating system code is a Tcl-only module for AOLserver.
For AOLserver to load the module source code, you must move, copy
or symlink the <kbd>tcl</kbd> directory in the templating system
distribution to the private Tcl library of your AOLserver
installation (as indicated by the <kbd>Library</kbd> parameter in
the <kbd>ns/server/myserver/tcl</kbd> section of the AOLserver
configuration file):</p>
<pre>$ cd /web/myserver/tcl
$ ln -s &lt;path_to_distribution&gt;/ats/tcl/ ats</pre>
<h3>Configuring AOLserver</h3>
<p>The last step is to modify your AOLserver configuration file.
You will need to register the templating system as a Tcl-only
module:</p>
<pre>[ns/server/myserver/modules]
nssock=nssock.so
nslog=nslog.so
<strong>ats=Tcl</strong>
</pre>
<p>or if you are using the new configuration file format:</p>
<pre>ns_section "ns/server/${server}/modules"
ns_param   nssock          nssock.so
ns_param   nslog           nslog.so
<strong>ns_param   ats          Tcl</strong>
</pre>
<p>Note that you should replace <kbd>ats</kbd> with whatever you
named the directory or symlink for the templating code within your
private Tcl library.</p>
<p>You will also need to ensure that the "fancy" ADP
parser is the default:</p>
<pre>[ns/server/<em>yourserver</em>/adp]
Map=/*.adp
DefaultParser=fancy

[ns/server/<em>yourserver</em>/adp/parsers]
fancy=.adp</pre>
<h3>Optional Configuration</h3>
<p>The templating system recognizes two optional parameters in the
AOLserver configuration file in the
<kbd>ns/server/<em>yourserver</em>/ats</kbd> section:</p>
<table cellspacing="0" cellpadding="4" border="1">
<tr>
<td><kbd>DatabaseInterface</kbd></td><td>Specifies the set of procedures to use for accessing a
relational database from the templating system. Two interfaces are
supplied with the system: <kbd>oracle</kbd> (uses the
<kbd>ns_ora</kbd> API in conjunction with the AOLserver Oracle
driver) and <kbd>generic</kbd> (uses the <kbd>ns_db</kbd> API in
conjunction with any AOLserver RDBMS driver). The default is
<kbd>Oracle</kbd>.</td>
</tr><tr>
<td><kbd>ShowCompiledTemplatesP</kbd></td><td>Enables a filter on the <kbd>cmp</kbd> extension so that the
compiled Tcl code for any template may be viewed in a browser for
debugging purposes. The default is 0 (disabled).</td>
</tr><tr>
<td><kbd>ShowDataDictionariesP</kbd></td><td>Enables a filter on the <kbd>dat</kbd> extension so that
documentation directives in Tcl scripts may be extracted and viewed
in a browser. The default is 1 (enabled).</td>
</tr><tr>
<td><kbd>ResourcePath</kbd></td><td>Specifies the absolute path to the system <kbd>templates</kbd>
directory, containing sitewide styles for forms, system messages,
etc. Defaults to <kbd>$::acs::pageroot/ats/resources</kbd>.</td>
</tr>
</table>
<h3>Testing the System</h3>
<p>To test the system, run the script <kbd>demo/demo.sql</kbd> to
create and populate a simple table in your database.</p>
<p>Save the configuration file and restart the server. Use the
samples included in the distribution to test whether the system is
working properly.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->