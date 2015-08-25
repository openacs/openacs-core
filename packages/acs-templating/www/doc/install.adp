
<property name="context">{/doc/acs-templating {Templating}} {Templating System: Installation}</property>
<property name="doc(title)">Templating System: Installation</property>
<master>
<h2>Installation</h2>
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
<pre>
$ wget http://bob.sf.arsdigita.com:8089/ats/ats.tar.gz
$ cd /web/myserver/www
$ gunzip -c ats.tar.gz | tar xvf -
</pre>
<p>The distribution consists of four subdirectories:</p>
<ol>
<li>
<b><tt>demo</tt></b>: A set of sample templates and supporting
files.</li><li>
<b><tt>doc</tt></b>: Documentation and tutorials.</li><li>
<b><tt>tcl</tt></b>: The Tcl module.</li><li>
<b><tt>resources</tt></b>: Sitewide style templates for forms
and error messages and associated assets.</li>
</ol>
<p>You can also untar (or check out) the distribution somewhere
else and symlink it under your page root. (If you do not wish to
install the distribution under your page root, see the
configuration options below).</p>
<h3>Installing the Tcl module</h3>
<p>The templating system code is a Tcl-only module for AOLserver.
For AOLserver to load the module source code, you must move, copy
or symlink the <tt>tcl</tt> directory in the templating system
distribution to the private Tcl library of your AOLserver
installation (as indicated by the <tt>Library</tt> parameter in the
<tt>ns/server/myserver/tcl</tt> section of the AOLserver
configuration file):</p>
<pre>
$ cd /web/myserver/tcl
$ ln -s &lt;path_to_distribution&gt;/ats/tcl/ ats
</pre>
<h3>Configuring AOLserver</h3>
<p>The last step is to modify your AOLserver configuration file.
You will need to register the templating system as a Tcl-only
module:</p>
<pre>
[ns/server/myserver/modules]
nssock=nssock.so
nslog=nslog.so
<b>ats=Tcl</b>
</pre>
<p>or if you are using the new configuration file format:</p>
<pre>
ns_section "ns/server/${server}/modules"
ns_param   nssock          nssock.so
ns_param   nslog           nslog.so
<b>ns_param   ats          Tcl</b>
</pre>
<p>Note that you should replace <tt>ats</tt> with whatever you
named the directory or symlink for the templating code within your
private Tcl library.</p>
<p>You will also need to ensure that the "fancy" ADP parser is the
default:</p>
<pre>
[ns/server/<em>yourserver</em>/adp]
Map=/*.adp
DefaultParser=fancy

[ns/server/<em>yourserver</em>/adp/parsers]
fancy=.adp
</pre>
<h3>Optional Configuration</h3>
<p>The templating system recognizes two optional parameters in the
AOLserver configuration file in the
<tt>ns/server/<em>yourserver</em>/ats</tt> section:</p>
<table cellspacing="0" cellpadding="4" border="1">
<tr>
<td><tt>DatabaseInterface</tt></td><td>Specifies the set of procedures to use for accessing a
relational database from the templating system. Two interfaces are
supplied with the system: <tt>oracle</tt> (uses the <tt>ns_ora</tt>
API in conjunction with the AOLserver Oracle driver) and
<tt>generic</tt> (uses the <tt>ns_db</tt> API in conjunction with
any AOLserver RDBMS driver). The default is <tt>Oracle</tt>.</td>
</tr><tr>
<td><tt>ShowCompiledTemplatesP</tt></td><td>Enables a filter on the <tt>cmp</tt> extension so that the
compiled Tcl code for any template may be viewed in a browser for
debugging purposes. The default is 0 (disabled).</td>
</tr><tr>
<td><tt>ShowDataDictionariesP</tt></td><td>Enables a filter on the <tt>dat</tt> extension so that
documentation directives in Tcl scripts may be extracted and viewed
in a browser. The default is 1 (enabled).</td>
</tr><tr>
<td><tt>ResourcePath</tt></td><td>Specifies the absolute path to the system <tt>templates</tt>
directory, containing sitewide styles for forms, system messages,
etc. Defaults to <tt>$::acs::pageroot/ats/resources</tt>.</td>
</tr>
</table>
<h3>Testing the System</h3>
<p>To test the system, run the script <tt>demo/demo.sql</tt> to
create and populate a simple table in your database.</p>
<p>Save the configuration file and restart the server. Use the
samples included in the distribution to test whether the system is
working properly.</p>
<hr>
<a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
