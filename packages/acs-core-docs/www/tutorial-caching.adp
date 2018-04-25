
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Basic Caching}</property>
<property name="doc(title)">Basic Caching</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="tutorial-html-email" leftLabel="Prev"
			title="Chapter 10. Advanced
Topics"
			rightLink="tutorial-schedule-procs" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-caching" id="tutorial-caching"></a>Basic Caching</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">Based on <a class="ulink" href="http://openacs.org/forums/message-view?message_id=157448" target="_top">a post by Dave Bauer</a>.</span></p><span style="color: red">&lt;/authorblurb&gt;</span><p>Caching using the database API is described in the database API
tutorial.</p><p>Caching using util_memoize</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Implement your proc as <code class="computeroutput">my_proc_not_cached</code>
</p></li><li class="listitem">
<p>Create a version of your proc called <code class="computeroutput">my_proc</code> which wraps the non-cached version
in the caching mechanism. In this example, my_proc_not_cached takes
one argument, -foo, so the wrapper passes that on. The wrapper also
uses the list command, to ensure that the arguments get passed
correctly and to prevent commands passed in as arguments from being
executed.</p><pre class="programlisting">ad_proc my_proc {-foo} {
        Get a cached version of my_proc.
} {
    return [util_memoize [list my_proc_not_cached -foo $foo]]
}</pre>
</li><li class="listitem"><p>In your code, always call my_proc. There will be a separate
cache item for each unique call to my_proc_not_cached so that calls
with different arguments are cached separately. You can flush the
cache for each cache key by calling util_memoize_flush
my_proc_not_cached args.</p></li><li class="listitem">
<p>The cached material will of course become obsolete over time.
There are two ways to handle this.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Timed Expiration: pass in max_age to util_memoize. If the
content is older than max_age, it will be re-generated.</p></li><li class="listitem"><p>Direct Flushing. In any proc which invalidates the cached
content, call util_memoize_flush my_proc_not_cached args.</p></li>
</ul></div>
</li><li class="listitem"><p>If you are correctly flushing the cached value, then it will
need to be reloaded. You may wish to pre-load it, so that the
loading delay does not impact users. If you have a sequence of
pages, you could call the cached proc in advance, to increase the
chances that it&#39;s loaded and current when the user reaches it.
Or, you can call (and discard) it immediately after flushing
it.</p></li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="tutorial-html-email" leftLabel="Prev" leftTitle="Sending HTML email from your
application"
			rightLink="tutorial-schedule-procs" rightLabel="Next" rightTitle="Scheduled Procedures"
			homeLink="index" homeLabel="Home" 
			upLink="tutorial-advanced" upLabel="Up"> 
		    