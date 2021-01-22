
<property name="context">{/doc/acs-automated-testing {ACS Automated Testing}} {Requirements}</property>
<property name="doc(title)">Requirements</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="usage" leftLabel="Prev"
		    title=""
		    rightLink="" rightLabel="">
		<div class="sect1" lang="en">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="requirements" id="requirements"></a>Requirements</h2></div></div></div><div class="authorblurb">
<p>by <a href="mailto:joel\@aufrecht.org" target="_top">Joel
Aufrecht</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2" lang="en">
<div class="titlepage"><div><div><h3 class="title">
<a name="requirements-introduction" id="requirements-introduction"></a>Introduction</h3></div></div></div><p>Automated Testing provides a framework for executing tests of
all varieties and for storing and viewing the results.</p>
</div><div class="sect2" lang="en">
<div class="titlepage"><div><div><h3 class="title">
<a name="gatekeeper-functional-requirements" id="gatekeeper-functional-requirements"></a>Functional
Requirements</h3></div></div></div><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><thead><tr>
<th><span class="strong">Req #</span></th><th><span class="strong">Status in 5.0</span></th><th><span class="strong">Priority for 5.1 (A=required,
B=optional)</span></th><th><span class="strong">Description</span></th>
</tr></thead><tbody>
<tr>
<td>1</td><td>Done</td><td>Done</td><td>
<span class="strong">Execute Tcl tests</span>. Execute a
sequence of Tcl code is executed and determine the correctness of
the results.</td>
</tr><tr>
<td>1.1</td><td>partial</td><td>Done</td><td>
<span class="strong">Execute HTTP tests</span>. Execute tests
that can interact with a the webserver via the external, HTTP
interface, including retrieving pages, following links, and
submitting forms. (This is partially done in the sense that we can
make http calls from tcl api, but there is no framework for doing
anything complicated.)</td>
</tr><tr>
<td>1.1.1</td><td> </td><td>Done</td><td>
<span class="strong">Execute tclwebtest scripts</span>. A test
can contain tclwebtest commands. If tclwebtest is not installed,
those commands fail gracefully.</td>
</tr><tr>
<td>1.1.1.1</td><td>partial</td><td>A</td><td>
<span class="strong">tclwebtest is easy to install</span>.
Tclwebtest installation is fully documented and can be installed
with less than five steps. (Install is documented in 5.0, but
there&#39;s a can&#39;t-find-config error; also, some new work in
tclwebtest HEAD needs to packaged in a new tarball release.)</td>
</tr><tr>
<td>2</td><td>Done</td><td>Done</td><td>
<span class="strong">Tests have categories</span>. Individual
tests can be marked as belonging to zero, one, or many of these
categories. The UI provides for running only tests in selected
categories, and for viewing only results of tests in selected
categories.</td>
</tr><tr>
<td>2.1</td><td> </td><td>A</td><td>Each test can be associated with a single OpenACS.org bug (ie,
store bug id as in integer, or store full url so that this can
point to other bugs)</td>
</tr><tr>
<td>3</td><td> </td><td>B</td><td>
<span class="strong">Tests can be ordered lists of other
tests</span>. minimal: verify that a test proc can call other test
procs. Better: A test can be created within the GUI by selecting
other tests. This test is stored in the database and can be
exported. (This is related to a bigger issue of storing test
scripts in some format other than tcl procs.)</td>
</tr><tr>
<td>4</td><td> </td><td>C</td><td>
<span class="strong">Test scripts can be imported and
exported</span>. It should be possible to import a test into the
database from a file, and to export it to a file. These files
should be sharable by different OpenACS installations. It should be
possible to import/export directly between running OpenACS sites.
(We should look at what did and didn&#39;t work in acs-lang catalog
files and work from there.)</td>
</tr><tr>
<td>5</td><td> </td><td>B</td><td>
<span class="strong">Macro Recording</span>. End users can
create and run tests from the web interface without writing code.
<p>1) UI to turn on macro mode.</p><p>2) basic recording: when you fill out a form while macro mode is
on, the submit is caught and displayed as tclwebtest code, and then
executed.</p><p>3) UI for creating aa_true tests automatically, based on the
content of the page. (For example, a form that says "the
returned page must contain [ type regexp here] that spits out
aa_true "test X" [string regexp blah blah]</p>
</td>
</tr><tr>
<td>6</td><td> </td><td>A</td><td>Notification subscriptions are available for "email me
whenever this test fails" and "notify me whenever a test
in this category fails"</td>
</tr><tr>
<td>7</td><td> </td><td>A</td><td>The results of an automated test are optionally written to an
xml file.</td>
</tr>
</tbody>
</table></div><p>Because the current test package uses in-memory variables
instead of database objects to track its tests, it is incompatible
with the standard category package. It uses an internal,
single-dimension category field. Should this eventually get
extended, a more complete list of categories to implement could
be:</p><pre class="programlisting">
Testing Mode
  Regression
  Smoke
  Stress
  Default-Only (for tests, such as front page UI tests, that will break 
                once the default site is modified and can be ignored on 
                non-default sites)
  production-safe
  security_risk
Layer
  Web Page
  Tcl Page Contract
  Tcl API
  SQL  
Severity (derives from ns_log values)
  Notice (use this for informational items that do not imply a problem)
  Warning (use this for submitted tests w/o fixes; hygiene tests such as deprecated function sweeps)
  Error (default severity)
  Test Validity Bug (use this for problems that suggest the test itself in invalid or broken)
Test Data
  Self-contained  Requires no test data, leaves no test data.
  Populate  Generates and leaves test data, for other tests or for end users.
Package Version
  5.0.0
  etc
</pre>
</div><div class="sect2" lang="en">
<div class="titlepage"><div><div><h3 class="title">
<a name="id2543127" id="id2543127"></a>References</h3></div></div></div><div class="itemizedlist"><ul type="disc">
<li><p>Forum Posting: <a href="http://openacs.org/forums/message-view?message_id=150581" target="_top">tclwebtest with openacs-4/etc/install tests -- help getting
started</a>
</p></li><li><p>Forum Posting: <a href="http://openacs.org/forums/message-view?message_id=153265" target="_top">Berlin bug bash proposal</a>
</p></li>
</ul></div>
</div><div class="sect2" lang="en">
<div class="titlepage"><div><div><h3 class="title">
<a name="revisions-history" id="revisions-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><thead><tr>
<th><span class="strong">Document Revision #</span></th><th><span class="strong">Action Taken, Notes</span></th><th><span class="strong">When?</span></th><th><span class="strong">By Whom?</span></th>
</tr></thead><tbody>
<tr>
<td>1</td><td>Creation</td><td>17 Jan 2004</td><td>Joel Aufrecht</td>
</tr><tr>
<td>2</td><td>Updated with notes from chat meeting</td><td>21 Jan 2004</td><td>Joel Aufrecht</td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="usage" leftLabel="Prev" leftTitle="Usage"
		    rightLink="" rightLabel="" rightTitle=""
		    homeLink="index" homeLabel="Home" 
		    upLink="index" upLabel="Up"> 
		