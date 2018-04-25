
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Release Version Numbering}</property>
<property name="doc(title)">Release Version Numbering</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="cvs-guidelines" leftLabel="Prev"
			title="Chapter 12. Engineering
Standards"
			rightLink="eng-standards-constraint-naming" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="eng-standards-versioning" id="eng-standards-versioning"></a>Release Version Numbering</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red"><span class="cvstag">($&zwnj;Id:
eng-standards-versioning.xml,v 1.11 2017/08/07 23:47:54 gustafn Exp
$)</span></span></p><p>By Ron Henderson, Revised by Joel Aufrecht</p>
&lt;/authorblurb&gt;
<p>OpenACS version numbers help identify at a high-level what is in
a particular release and what has changed since the last
release.</p><p>A "version number" is really just a string of the
form:</p><div class="blockquote"><blockquote class="blockquote"><p>
<span class="emphasis"><em>major</em></span>.<span class="emphasis"><em>minor</em></span>.<span class="emphasis"><em>dot</em></span>[ <span class="emphasis"><em>milestone</em></span> ]</p></blockquote></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>A <span class="emphasis"><em>major</em></span> number change
indicates a fundamental change in the architecture of the system,
e.g. OpenACS 3 to ACS 4. A major change is required if core
backwards compatibility is broken, if upgrade is non-trivial, or if
the platform changes substantially.</p></li><li class="listitem"><p>A <span class="emphasis"><em>minor</em></span> change represents
the addition of new functionality or changed UI.</p></li><li class="listitem"><p>A <span class="emphasis"><em>dot</em></span> holds only bug
fixes and security patches. Dot releases are always recommended and
safe.</p></li><li class="listitem">
<p>A <span class="emphasis"><em>milestone</em></span> marker
indicates the state of the release:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>
<span class="emphasis"><em>d</em></span>, for development, means
the release is in active development and is not in its intended
released form.</p></li><li class="listitem"><p>
<span class="emphasis"><em>a</em></span>, for alpha, means new
development is complete and code checkins are frozen. Alpha builds
should work well enough to be testable.</p></li><li class="listitem"><p>
<span class="emphasis"><em>b</em></span>, for beta, means most
severe bugs are fixed and end users can start trying the
release.</p></li><li class="listitem"><p>Release Candidate builds (<span class="emphasis"><em>rc</em></span>) are believed to meet all of the
criteria for release and can be installed on test instances of
production systems.</p></li><li class="listitem"><p>Final releases have no milestone marker. (Exception: In CVS,
they are tagged with -final to differentiate them from branch
tags.)</p></li>
</ul></div><p>Milestone markers are numbered: d1, d2, ..., a1, b1, rc1,
etc.</p>
</li>
</ul></div><p>A complete sequence of milestones between two releases:</p><pre class="programlisting">5.0.0
5.0.0rc2
5.0.0rc1
5.0.0b4
5.0.0b1
5.0.0a4
5.0.0a3
5.0.0a1
5.0.0d1
4.6.3</pre><p>Version numbers are also recorded in the CVS repository so that
the code tree can be restored to the exact state it was in for a
particular release. To translate between a distribution tar file
(acs-3.2.2.tar.gz) and a CVS tag, just swap '.' for
'-'.The entire release history of the toolkit is recorded
in the tags for the top-level <code class="computeroutput">readme.txt</code> file:</p><pre class="programlisting">
&gt; cvs log readme.txt
RCS file: /usr/local/cvsroot/acs/readme.txt,v
Working file: readme.txt
head: 3.1
branch:
locks: strict
access list:
symbolic names:
        acs-4-0: 3.1.0.8
        acs-3-2-2-R20000412: 3.1
        acs-3-2-1-R20000327: 3.1
        acs-3-2-0-R20000317: 3.1
        acs-3-2-beta: 3.1
        acs-3-2: 3.1.0.4
        acs-3-1-5-R20000304: 1.7.2.2
        acs-3-1-4-R20000228: 1.7.2.2
        acs-3-1-3-R20000220: 1.7.2.2
        acs-3-1-2-R20000213: 1.7.2.1
        acs-3-1-1-R20000205: 1.7.2.1
        acs-3-1-0-R20000204: 1.7
        acs-3-1-beta: 1.7
        acs-3-1-alpha: 1.7
        acs-3-1: 1.7.0.2
        v24: 1.5
        v23: 1.4
        start: 1.1.1.1
        arsdigita: 1.1.1
keyword substitution: kv
total revisions: 13;    selected revisions: 13
description:
...
</pre><p>In the future, OpenACS packages should follow this same
convention on version numbers.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-transition-rules" id="eng-standards-transition-rules"></a>Transition Rules</h3></div></div></div><p>So what distinguishes an <span class="emphasis"><em>alpha</em></span> release from a <span class="emphasis"><em>beta</em></span> release? Or from a production
release? We follow a specific set of rules for how OpenACS makes
the transition from one state of maturity to the next. These rules
are fine-tuned with each release; an example is <a class="ulink" href="http://openacs.org/projects/openacs/5.0/milestones" target="_top">5.0.0 Milestones and Milestone Criteria</a>
</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-package-maturity" id="eng-standards-package-maturity"></a>Package Maturity</h3></div></div></div><p>Each package has a maturity level. Maturity level is recorded in
the .info file for each major-minor release of OpenACS, and is set
to the appropriate value for that release of the package.</p><pre class="programlisting">
    &lt;version ...&gt;
        &lt;provides .../&gt;
        &lt;requires .../&gt;
        &lt;maturity&gt;1&lt;/maturity&gt;
        &lt;callbacks&gt;
            ...
    </pre><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>Level -1:
Incompatible.</strong></span> This package is not supported for
this platform and should not be expected to work.</p></li><li class="listitem"><p>
<span class="strong"><strong>Level 0: New
Submission.</strong></span> This is the default for packages that
do not have maturity explicitly set, and for new contributions. The
only criterion for level 0 is that at least one person asserts that
it works on a given platform.</p></li><li class="listitem"><p>
<span class="strong"><strong>Level 1: Immature.</strong></span>
Has no open priority 1 or priority 2 bugs. Has been installed by at
least 10? different people, including 1 core developer. Has been
available in a stable release for at least 1 month. Has API
documentation.</p></li><li class="listitem"><p>
<span class="strong"><strong>Level 2: Mature.</strong></span>
Same as Level 1, plus has install guide and user documentation; no
serious deviations from general coding practices; no namespace
conflicts with existing level 2 packages.</p></li><li class="listitem"><p>
<span class="strong"><strong>Level 3: Mature and
Standard.</strong></span> Same as level 2, plus meets published
coding standards; is fully internationalized; available on both
supported databases.</p></li><li class="listitem"><p>
<span class="strong"><strong>Level 4:
Deprecated.</strong></span> The package was in some earlier version
is use, but was probably replaced by a another package. The package
description should point to a preferred version.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="naming-upgrade-scripts" id="naming-upgrade-scripts"></a>Naming Database Upgrade Scripts</h3></div></div></div><p>Database upgrade scripts must be named very precisely in order
for the Package Manager to run the correct script at the correct
time.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Upgrade scripts should be named <code class="computeroutput">/packages/<em class="replaceable"><code>myfirstpackage</code></em>/sql/<em class="replaceable"><code>postgresql</code></em>/upgrade/upgrade-<em class="replaceable"><code>OLDVERSION</code></em>-<em class="replaceable"><code>NEWVERSION</code></em>.sql</code>
</p></li><li class="listitem"><p>If the version you are working on is a later version than the
current released version, OLDVERSION should be the current version.
The current version is package version in the APM and in
<code class="computeroutput">/packages/<em class="replaceable"><code>myfirstpackage</code></em>/<em class="replaceable"><code>myfirstpackage</code></em>.info</code>. So if
forums is at 2.0.1, OLDVERSION should be 2.0.1d1. Note that this
means that new version development that includes an upgrade must
start at d2, not d1.</p></li><li class="listitem"><p>If you are working on a pre-release version of a package, use
the current package version as OLDVERSION. Increment the package
version as appropriate (see above) and use the new version as
NEWVERSION. For example, if you are working on 2.0.1d3, make it
2.0.1d4 and use <code class="computeroutput">upgrade-2.0.1d3-2.0.1d4.sql</code>.</p></li><li class="listitem"><p>Database upgrades should be confined to development releases,
not alpha or beta releases.</p></li><li class="listitem"><p>Never use a final release number as a NEWVERSION. If you do,
then it is impossible to add any more database upgrades without
incrementing the overall package version.</p></li><li class="listitem"><p>Use only the d, a, and b letters in OLDVERSION and NEWVERSION.
rc is not supported by OpenACS APM.</p></li><li class="listitem"><p>The distance from OLDVERSION to NEWVERSION should never span a
release. For example if we had a bug fix in acs-kernel on 5.1.0 you
wouldn&#39;t want a file upgrade-5.0.4-5.1.0d1.sql since if you
subsequently need to provide a 5.0.4-5.0.5 upgrade you will have to
rename the 5.0.4-5.1.0 upgrade since you can&#39;t have upgrades
which overlap like that. Instead, use <code class="computeroutput">upgrade-5.1.0d1-5.1.0d2.sql</code>
</p></li>
</ol></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="cvs-guidelines" leftLabel="Prev" leftTitle="CVS Guidelines"
			rightLink="eng-standards-constraint-naming" rightLabel="Next" rightTitle="Constraint naming standard"
			homeLink="index" homeLabel="Home" 
			upLink="eng-standards" upLabel="Up"> 
		    