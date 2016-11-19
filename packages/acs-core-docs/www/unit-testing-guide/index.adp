
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {ACS4 Unit Tests}</property>
<property name="doc(title)">ACS4 Unit Tests</property>
<master>
<h2>ACS4 Unit Tests</h2>

by <a href="mailto:pmcneill\@arsdigita.com">Patrick McNeill</a>
<h3>Purpose</h3>

Prior to using these unit tests, all testing had to be completed
manually for each revision of a module. When a module is updated
several times a day, this can present a problem. The solution
adopted here is to create a suite of regression tests for each
module to ensure that the required functionality is not broken by
new code. The tests are constructed in such a way that they can be
run automatically, allowing developers to quickly determine if new
code breaks any functionality requirements.
<h3>Installation</h3>

The ACS4 unit testing suite requires several pieces of software to
function. First, you&#39;ll need to install <a href="http://jakarta.apache.org/ant/">Ant</a>
. Ant is a build tool
similar to make. It&#39;s used to both build your test cases and
run the tests themselves. The basic Ant functionality doesn&#39;t
have everything needed to automate the testing, so you&#39;ll want
to obtain David Eison&#39;s ForeachFileAntTask.java, available at
<a href="http://cvs.arsdigita.com/cgi-bin/cvsweb.pl/acs-java-4/WEB-INF/src/com/arsdigita/build/">
http://cvs.arsdigita.com/cgi-bin/cvsweb.pl/acs-java-4/WEB-INF/src/com/arsdigita/build/</a>
.
Compile the files and make sure that they are in your classpath.
<p>Once Ant is working, you&#39;ll need to obtain copies of both
<a href="http://www.junit.org/">JUnit</a> and <a href="http://httpunit.sourceforge.net/">HTTPUnit</a>. JUnit is a
framework to automate the running of unit tests, and HTTPUnit
provides an abstraction layer for HTTP. These are both needed to
compile the unit tests. Again, make sure your classpath is up to
date.</p>
<p>The final step is to replace the server properties in the
build.xml file so it will know how to talk to your server. You will
need to give it a base URL, a username, and password for that user.
are the "JVMARG" lines in the "JUNIT" section.
). In the near future, this will be moved out of the subdirectories
and either into the toplevel build.xml file or into a configuration
file.</p>
<p>You should now be ready to run the tests. Go to your
server&#39;s "packages" directory and type <code>source
./paths.sh</code> to set up your classpath. Now type
<code>ant</code>. Ant should find the toplevel build.xml file,
check that it can see JUnit, compile your java files, and finally
call Ant on each of the sub-directory build.xml files to run the
tests. You should be shown a report of which tests failed and which
succeeded.</p>
<h3>Adding Your Own Unit Tests</h3>

Adding new test cases is meant to be as easy as possible. Simple
create a new function in the appropriate .java file, making sure
that the function name begins with "test". I&#39;ve
adopted a naming convention where the function name consists of the
word "test", a short description of what the function
does (with words delimited by underscores), followed finally by the
QAS testcase ID, if such a testcase exists. If you need to test an
area of the site that requires a user id, you can use the
ACSCommon.Login function in the com.arsdigita.acs.acsKernel.test
package to obtain a Session object with appropriate cookies.
<p>Within the function, a typical unit test involves requesting a
page, saving the result, checking the HTTP return code, then
parsing out various strings to check for page functionality. The
return code should be checked with "assertEquals", and
any other checks should be performed with "assert". Use
of "assert", "assertEquals", and exceptions
allow JUnit to accurately report where a test fails.</p>
<p>If you need to create a set of tests for a module, the first
step is to create a directory tree beneath the module directory.
The current convention is to put all .java files in a
"/java/src/com/arsdigita/acs/<em>module name</em>/test"
directory. The <em>module name</em> should be the ACS module name,
but with all dashes removed and with appropriate capitilization.
All .java files that you create that contain test cases must have
the word Test in the filename. All of the classes you create should
be in the com.arsdigita.acs.<em>module name</em>.test package, and
should import "com.dallaway.jsptest.*" and
"junit.framework.*" (and optionally, if needed,
com.arsdigita.acs.acsKernel.ACSCommon). Next, the public class
needs to extend "TestCase", and provide new method
definitions for "suite()" and the constructor. Typically,
in the constructor, you should extract the system property
"system.url" to determine which server to test
against.</p>
<hr>
<em>Last updated - 2000-12-19</em>
<br>
<a href="mailto:pmcneill\@arsdigita.com"></a>
<address>pmcneill\@arsdigita.com</address>
