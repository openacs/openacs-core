
<property name="context">{/doc/acs-templating/ {ACS Templating}} {Template Timing Results}</property>
<property name="doc(title)">Template Timing Results</property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<h3>Results</h3>

The measurements were taken on <code>reusia.boston</code>
 on 13
October 2000, with approximately acs-4-0-beta-2-R20001009.
<p>Here are the graphs for the 15 stages, and the log message of
their beginning is written in the lower right of the graphs. In
comparison with <a href="timing-1">the first measurement</a>,
the steeper slopes indicate much less variation in the
measurements, which reflects the more reproducible conditions
(essentially no other activity) on reusia.boston in comparison with
dev0103-001.</p>
<h4>Individual Stages</h4>
<p><img src="time2/stage00.gif"></p>
<p><img src="time2/stage01.gif"></p>
<p><img src="time2/stage02.gif"></p>
<p><img src="time2/stage03.gif"></p>
<p><img src="time2/stage04.gif"></p>
<p><img src="time2/stage05.gif"></p>
<p><img src="time2/stage06.gif"></p>
<p><img src="time2/stage07.gif"></p>
<p><img src="time2/stage08.gif"></p>
<p><img src="time2/stage09.gif"></p>
<p><img src="time2/stage10.gif"></p>
<p><img src="time2/stage11.gif"></p>
<p><img src="time2/stage12.gif"></p>
<p><img src="time2/stage13.gif"></p>
<p><img src="time2/stage14.gif"></p>
<h4>Total Time (Sum of all Stages)</h4>
<p><img src="time2/stage15.gif"></p>
<p>Overall, the templated pages are delivered markedly
<strong>slower</strong>, by about 65ms. Forcing the template system
to always reread all files and to recompile the ADP part slows them
down, as expected, but overall they are still faster than the
Tcl-only page.</p>
<hr>
<address><a href="mailto:christian\@arsdigita.com">Christian
Brechbuehler</a></address>
<!-- Created: Tue Oct 17 11:39:55 EDT 2000 --><!-- hhmts start -->
Last modified: Wed Oct 18 16:45:17 EDT 2000 <!-- hhmts end -->