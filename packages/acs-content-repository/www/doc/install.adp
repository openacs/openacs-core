
<property name="context">{/doc/acs-content-repository {Content Repository}} {Content Repository: Installation}</property>
<property name="doc(title)">Content Repository: Installation</property>
<master>
<h2>Installing the Content Repository</h2>
<p>The content repository is a part of the core data model of ACS
4.0 and greater, and is loaded automatically as part of the ACS
installation process.</p>
<p>If you wish to install the content repository in a database
schema outside the context of ACS, the following instructions
apply.</p>
<p>First install the data model and PL/SQL API:</p>
<ol>
<li>Obtain the latest distribution of ACS.</li><li>Run the SQL script
<tt>packages/acs-kernel/sql/acs-kernel-create.sql</tt> to load the
core ACS Objects data model.</li><li>Run the SQL script
<tt>packages/acs-workflow/sql/acs-workflow-create.sql</tt> to load
the workflow package.</li><li>Run the SQL script
<tt>packages/acs-workflow/sql/acs-content-repository-create.sql</tt>
to load the content repository itself.</li>
</ol>
<h3>Java</h3>
<p>In additional to SQL and PL/SQL, the content repository
implements a limited set of key methods in Java. The XML import and
export methods are dependent on Oracle's XML Parser for Java v2,
available from the Oracle Technology Network:</p>
<a href="http://technet.us.oracle.com/tech/xml/parser_java2/index.htm"><tt>http://technet.us.oracle.com/tech/xml/parser_java2/index.htm</tt></a>
<p>To load the XML parser, download and untar the distribution.
Load the class package <tt>lib/xmlparserv2.jar</tt> into Oracle
from a shell prompt:</p>
<pre>
$ loadjava -user user/password xmlparserv2.jar
</pre>
<p>Finally, load the SQLJ files in
<tt>packages/acs-content-repository/java</tt>:</p>
<pre>
$ loadjava -user user/password -resolve *.sqlj
</pre>
<p>Installation of the data model and API should now be
complete.</p>
<h3>Intermedia</h3>
<p>The content repository relies on an Intermedia with the INSO
filtering option to search text within a wide variety of file
formats, including PDF and Microsoft Word. When the index on the
<tt>content</tt> column of <tt>cr_revisions</tt> is built, the INSO
filter automatically detects the file type of each entry and
extracts all available text for indexing.</p>
<p>If your searches are not returning any results even after
rebuilding the index, INSO filtering may be silently failing. You
can verifying this by checking for entries in the
<tt>ctx_user_index_errors</tt> view following an <tt>alter
index</tt> statement.</p>
<p>If you experience errors on a UNIX system, check the
following:</p>
<ul>
<li>The operating system user running the Oracle database must have
execute permission on the files
<tt>$ORACLE_HOME/ctx/lib/*.flt</tt>.</li><li>The directory <tt>$ORACLE_HOME/ctx/lib</tt> must be in the
<tt>$PATH</tt> environment variable of the operating system user
running the Oracle database.</li><li>The directory <tt>$ORACLE_HOME/ctx/lib</tt> must be in the
<tt>$LD_LIBRARY_PATH</tt> of the operating system user running the
Oracle database.</li><li>The <tt>LD_LIBRARY_PATH</tt> environment variable must be
specified in the entry for <tt>PLSExtProc</tt> in the
<tt>$ORACLE_HOME/network/admin/listener.ora.</tt> For example:</li>
</ul>
<pre>
    (SID_DESC =
      (SID_NAME = PLSExtProc)
      (ORACLE_HOME = /ora8/m01/app/oracle/product/8.1.6)
      (ENVS = LD_LIBRARY_PATH=/ora8/m01/app/oracle/product/8.1.6/lib:/usr/lib:/lib:/usr/openwin/lib:/ora8/m01/app/oracle/product/8.1.6/ctx/lib)
      (PROGRAM = extproc)
    )
</pre>
<p>If your searches are still failing even after following these
instructions, try a simple <a href="intermedia">test case</a>
to determine whether the problem has something to do with the
content repository data model itself.</p>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last revised: $Id: install.html,v 1.1.1.1 2001/03/13 22:59:26 ben
Exp $
