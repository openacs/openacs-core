
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Scheduled Procedures}</property>
<property name="doc(title)">Scheduled Procedures</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-caching" leftLabel="Prev"
		    title="
Chapter 10. Advanced Topics"
		    rightLink="tutorial-wysiwyg-editor" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-schedule-procs" id="tutorial-schedule-procs"></a>Scheduled Procedures</h2></div></div></div><p>Put this proc in a file <code class="computeroutput">/packages/<span class="replaceable"><span class="replaceable">myfirstpackage</span></span>/tcl/scheduled-init.tcl</code>.
Files in /tcl with the -init.tcl ending are sourced on server
startup. This one executes my_proc every 60 seconds:</p><pre class="programlisting">
ad_schedule_proc 60 myfirstpackage::my_proc
</pre><p>This executes once a day, at midnight:</p><pre class="programlisting">
ad_schedule_proc \
    -schedule_proc ns_schedule_daily \
    [list 0 0] \
    myfirstpackage::my_proc
</pre><p>See <a class="ulink" href="/api-doc/proc-view?proc=ad%5fschedule%5fproc" target="_top">ad_schedule_proc</a> for more information.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-caching" leftLabel="Prev" leftTitle="Basic Caching"
		    rightLink="tutorial-wysiwyg-editor" rightLabel="Next" rightTitle="Enabling WYSIWYG"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial-advanced" upLabel="Up"> 
		