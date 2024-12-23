
<property name="context">{/doc/acs-templating/ {ACS Templating}} {Template Timing Results}</property>
<property name="doc(title)">Template Timing Results</property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<h3>Results</h3>
<p>The measurements were taken on <code>reusia.boston</code> on 17
October 2000, with tarball acs-3-4-6-R20001008. Templating under
3.4 is quite different; instead of a .tcl script, datasources are
defined in a .data file that has a different XML syntax.</p>
<p>We have graphs for 9 stages only. While Tcl pages generate four
more entries, these lack from templated pages, and hence I
suppressed them. The log message that marks the beginning of each
phase is written in the lower right of the graphs. Each curve curve
plots 288 page requests. As I didn&#39;t back port of the
configurable cache refreshing strategy ('never' or
'always'), I show all graphs in the 'normal'
colors. The label is 'do', though.</p>
<h4>Individual Stages</h4>
<p><img src="time3/stage00.gif"></p>
<p><img src="time3/stage01.gif"></p>
<p><img src="time3/stage02.gif"></p>
<p><img src="time3/stage03.gif"></p>
<p><img src="time3/stage04.gif"></p>
<p><img src="time3/stage05.gif"></p>
<p><img src="time3/stage06.gif"></p>
<p><img src="time3/stage07.gif"></p>
<p><img src="time3/stage08.gif"></p>
<h4>Total Time (Sum of all Stages)</h4>
<p><img src="time3/stage09.gif"></p>
<p>To show off the graphing method, compare the graph above with
the one below, which only uses the first 32 measurements. The
curves are less smooth, but the message is the same.</p>
<p><img src="time3a/stage09.gif"></p>
<p>In ACS 3.4.6, Tcl-only pages are sereved <strong>faster</strong>
than in 4.0 beta-2. The templated pages are delivered much
<strong>slower</strong>. The first time the template system reads a
templated page, it takes about 3 seconds! The result is cached,
mitigating the problem a lot.</p>
<hr>
<address><a href="mailto:christian\@arsdigita.com">Christian
Brechbuehler</a></address>
<!-- Created: Tue Oct 17 11:39:55 EDT 2000 --><!-- hhmts start -->
Last modified: Tue Oct 17 20:26:14 EDT 2000 <!-- hhmts end -->