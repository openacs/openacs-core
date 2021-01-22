
<property name="context">{/doc/acs-templating {ACS Templating}} {Template Timing Results}</property>
<property name="doc(title)">Template Timing Results</property>
<master>
<h3>Results</h3>

The measurements were taken on <code>dev0103-001</code>
 on 5
October 2000, probably with acs-4-0-beta-R20001001. Here are the
graphs for the 14 stages, titled by the log message of their
beginning.
<h4>Invoking preauth filter rp_filter</h4>
<img src="time1/stage00.gif">
<p>No difference; all take about 2.6 ms. The same is the case for
the few following stages: Short times and apparently independent of
the kind of page.</p>
<h4>Looking for node to match
/acs-templating/admin/test/chain-frac-0.</h4>
<img src="time1/stage01.gif">
<h4>Found /acs-templating/.</h4>
<img src="time1/stage02.gif">
<h4>Performing developer support logging</h4>
<img src="time1/stage03.gif">
<h4>Checking for changed libraries</h4>
<img src="time1/stage04.gif">
<h4>Handling authentication</h4>
<img src="time1/stage05.gif">
<p>For some reason, this seems to take much longer on the Tcl-only
page. Maybe because it&#39;s the first in a triple of pages that
e-Tester requests? There may be a little longer time gap between
chain-frac-2 and the next request of chain-frac-0</p>
<h4>Handling authorization</h4>
<img src="time1/stage06.gif">
<p>An unexplained but clear distinction here: 0 is faster than 2,
and 1 is slowest.</p>
<h4>Done invoking preauth filter rp_filter (returning
filter_ok)</h4>
<img src="time1/stage07.gif">
<h4>Invoking registered procedure rp_handler</h4>
<img src="time1/stage08.gif">
<h4>Searching for
/webroot/web/brech/acs/packages/acs-templating/www/admin/test/chain-frac-0.*</h4>
<img src="time1/stage09.gif">
<h4>Serving
/webroot/web/brech/acs/packages/acs-templating/www/admin/test/chain-frac-0.tcl
with rp_handle_tcl_request</h4>
<img src="time1/stage10.gif">
<p>Here the actual work supposedly happens. The Tcl-only page is
clearly fastest. Always reparsing pages expectedly affects the
templated page, and -2, which compiles two ADP pages, is affected
more than -1. The benefit of -2, wrapping -1 in another include,
isn&#39;t apparent; on the contrary, -1 is in all cases a bit
faster than -2. The benefit of cacheing seems more than offset by
the extra complexity of nesting several templates.</p>
<h4>Invoking trace filter ad_issue_deferred_dml</h4>
<img src="time1/stage11.gif">
<p>For some reason, the Tcl-only page takes significantly
longer.</p>
<h4>Done invoking trace filter ad_issue_deferred_dml (returning
filter_ok)</h4>
<img src="time1/stage12.gif">
<h4>Invoking trace filter ds_trace_filter</h4>
<img src="time1/stage13.gif">
<p>That last phase is ended by <strong>Done invoking trace filter
ds_trace_filter (returning filter_ok)</strong>
</p>
<h4>Total time</h4>
<img src="time1/stage14.gif">
<p>Overall, the templated pages are delivered
<strong>faster</strong>. Forcing the template system to always
reread all files and to recompile the ADP part slows them down, as
expected, but overall they are still faster than the Tcl-only
page.</p>
<hr>
<address><a href="mailto:christian\@arsdigita.com">Christian
Brechbuehler</a></address>
<!-- Created: Tue Oct 17 11:39:55 EDT 2000 --><!-- hhmts start -->
Last modified: Tue Oct 17 20:04:29 EDT 2000 <!-- hhmts end -->