
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Distributing upgrades of your package}</property>
<property name="doc(title)">Distributing upgrades of your package</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-distribute" leftLabel="Prev"
		    title="
Chapter 10. Advanced Topics"
		    rightLink="tutorial-notifications" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-upgrades" id="tutorial-upgrades"></a>Distributing upgrades of your
package</h2></div></div></div><div class="authorblurb">
<p>by Jade Rubick</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>The OpenACS Package Repository builds a list of packages that
can be installed on OpenACS installations, and can be used by
administrators to update their packages. If you are a package
developer, there are a couple of steps you need to take in order to
release a new version of your package.</p><p>For the sake of this example, let&#39;s assume you are the
package owner of the <code class="computeroutput">notes</code>
package. It is currently at version 1.5, and you are planning on
releasing version 1.6. It is also located in OpenACS&#39;s CVS.</p><p>To release your package:</p><pre class="screen">
cd /path/to/notes
cvs commit -m "Update package to version 1.6."
cvs tag notes-1-6-final
cvs tag -F openacs-5-1-compat
</pre><p>Of course, make sure you write upgrade scripts (<a class="xref" href="tutorial-upgrade-scripts" title="Writing upgrade scripts">the section called
&ldquo;Writing upgrade scripts&rdquo;</a>)</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-distribute" leftLabel="Prev" leftTitle="Prepare the package for
distribution."
		    rightLink="tutorial-notifications" rightLabel="Next" rightTitle="Notifications"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial-advanced" upLabel="Up"> 
		