
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Writing upgrade scripts}</property>
<property name="doc(title)">Writing upgrade scripts</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="tutorial-parameters" leftLabel="Prev"
			title="Chapter 10. Advanced
Topics"
			rightLink="tutorial-second-database" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-upgrade-scripts" id="tutorial-upgrade-scripts"></a>Writing upgrade scripts</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">by <a class="ulink" href="mailto:jade\@rubick.com" target="_top">Jade Rubick</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><p>If your package changes its data model, you have to write an
upgrade script. This is very easy in OpenACS.</p><p>First, you want to make sure you change the original .sql file
so that new installation will have the new data model.</p><p>Next, check what version your package is currently at. For
example, it may be at version 1.0b1. Create a file in
sql/postgres/upgrade called packagename-1.0b1-1.0b2.sql and put the
SQL code that will update the data model. For example, if you add
in a column, you would have an alter table add column statement in
this file. Test this out very well, because data model changes are
more serious and fundamental changes than the program .tcl
files.</p><p>Now use the APM to create a new package version 1.0b2. Commit
all your changes, tag the release (<a class="xref" href="tutorial-upgrades" title="Distributing upgrades of your package">the section called
“Distributing upgrades of your package”</a>), and both new
installations and upgrades will be taken care of.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="tutorial-parameters" leftLabel="Prev" leftTitle="Adding in parameters for your
package"
			rightLink="tutorial-second-database" rightLabel="Next" rightTitle="Connect to a second database"
			homeLink="index" homeLabel="Home" 
			upLink="tutorial-advanced" upLabel="Up"> 
		    