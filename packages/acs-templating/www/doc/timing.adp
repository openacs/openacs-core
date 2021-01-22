
<property name="context">{/doc/acs-templating {ACS Templating}} {Timing a Templated Page}</property>
<property name="doc(title)">Timing a Templated Page</property>
<master>
<h2>Timing a Templated Page</h2>

by <a href="mailto:christian\@arsdigita.com">Christian
Brechbühler</a>
<h3>I. Introduction</h3>

One of the <a href="requirements">requirements</a>
 for the
template system asks for efficiency:
<blockquote><ul><li>
<a name="110.0"><strong>110.0 Performance</strong></a><p>The Templating System must not cause any performance problems to
a site. It must be fast and efficient, and it must not slow down
page load speed by more than 10% versus a Tcl page with inline
HTML.</p>
</li></ul></blockquote>

This page documents the attempt to verify this requirement.
<h3>II. Methods</h3>
<p>I wrote a sample page for this test. It expands four real
numbers into continued fractions. I created three versions:</p>
<ul>
<li>
<a href="">chain-frac-0</a>, a Tcl page with inline HTML,</li><li>
<a href="">chain-frac-1</a>, a templated page, i.e. a Tcl and
an HTML file, and</li><li>
<a href="">chain-frac-2</a>, an ADP page that simply
<code>&lt;include&gt;</code>s chain-frac-1.</li>
</ul>
<p>The reason for creating <code>chain-frac-2.adp</code> is that in
this way, the script <code>chain-frac-1.tcl</code> is handled
inside the templating system, and hence loaded once and cached.
There is hope that this might be faster.</p>
<p>Normally, the templating system re-reads a file whenever the
version on disk is out of date. ADP pages are compiled to TCL, and
both ADP and Tcl pages are cached as Tcl procs. The parameter
<code>RefreshCache</code> in section <code>template</code> can be
set to <code>always</code> or <code>never</code> to affect the
cacheing strategy; the latter may be useful for a production site.
All timing is carried out for the three settings
<code>always</code>, <code>normal</code>, and <code>never</code>;
the associated variable is called <code>check</code>.</p>
<p>I created a script in e-Tester that requests the three pages
from my development server on dev0103-001. One timing of requesting
a page isn&#39;t very expressive. A lot of factors affect the page
load time. To offset these and get better results, I repeatedly
request the pages. For the timing, I have e-Tester iterate this
script 200 times. To compesate for varying load on the machine, i
ran the iteration twice for each setting of
<code>RefreshCache</code> at different times of the day.</p>
<p>The timing information is taken from the error log file entries
that the request processor produces with parameter
<code>LogDebugP=1</code>. For finer granularity I changed rp_debug
to divide the clock clicks (microsecond) difference by 1000.0
instead of 1000. Delivering a page gives us 15 log file entries
with timestamps. I treat the first one (? ms) as 0. There must be
no other page requests from this AOLserver during the measurement.
I note the length of the error log before and after one run of the
script. Afterwards I cut out the error log sections indicated by
these positions into files <code>never</code>, <code>normal</code>,
and <code>always</code>.</p>
<p>The following steps extract the relevant information and bring
it in a form suitable for gnuplot.</p>
<ul>
<li>
<em>Extract time from log file sections</em>. This is done in
tcsh.
<pre>
foreach i ( never normal always )
  fgrep '] Notice: RP (' $i                        &gt;  $i-0
  echo                                             &gt;  $i-1
  foreach conn (`cut -d- -f2 always-0 | sort -u`)
    echo "$i '$conn'"
    fgrep "[-$conn-]" $i-0 | cut -d: -f5-          &gt;&gt; $i-1
  end
  cut -d" " -f3 $i-1| cut -c2-| tr \? 0            &gt;  $i-2
end
        
</pre>
The three resulting files, ending in -2, contain 18000 numbers, for
2 runs * 200 tries * 3 pages * 15 stages.</li><li>
<em>Group and sort times</em>. The time one stage of processing
takes is given by the difference of two time adjacent entries. This
defines stage00 to stage13; I keep the total time in stage14. This
is done by the Tcl script
<code>dev0103-001:/home/brech/prog/tcl/timing.tcl</code>, which
generates the directories <code>stage00</code> to
<code>stage14</code> and the ten files
{<code>0</code>,<code>1</code>,<code>2</code>}-{<code>never</code>,<code>normal</code>,<code>always</code>},
and <code>t_max</code> in each of them. Each of the former files
contains the 2*200 samples, ordered for graphing.
<h3>III. Presentation</h3><h4>Color Codes</h4><p>The different experiments are color coded as follows.</p><table cellspacing="6">
<tr>
<td></td><th>never</th><th>normal</th><th>always</th>
</tr><tr>
<th>chain-frac-0</th><td width="80" height="30" bgcolor="#3D8AFF"> </td><td width="80" height="30" bgcolor="#24A7A7"> </td><td width="80" height="30" bgcolor="#0AC44F"> </td>
</tr><tr>
<th>chain-frac-1</th><td width="80" height="30" bgcolor="#9962D7"> </td><td width="80" height="30" bgcolor="#808080"> </td><td width="80" height="30" bgcolor="#669D28"> </td>
</tr><tr>
<th>chain-frac-2</th><td width="80" height="30" bgcolor="#F53BB0"> </td><td width="80" height="30" bgcolor="#DB5858"> </td><td width="80" height="30" bgcolor="#C27500"> </td>
</tr>
</table>
(They lie in the isoluminant plane in the middle of the RGB color
space.)
<h4>Presenting Distributions</h4><p>A number of statistic measures can summarize an ensemble of
data, in our case, the 400 timings. The average is affected by
outliers; the median is much more robust. Maybe some dispersion
measure would be of interest, too. Some people plot histograms, but
that approach is frought with its own problems. I chose to use all
the data and plot estimated distribution functions. Our random
variable being time <var>T</var>, its distribution function is
defined as</p><center>
<var>F<sub>T</sub>
</var>(<var>t</var>) =
<var>P</var>[<var>T</var> &lt;= <var>t</var>] 
 .</center>
It is sometimes referred to as cumulative density function. Its
deriviative <var>p</var>(<var>t</var>) =
<var>F</var>'(<var>t</var>) is the distribution density of the
random variable T, which histograms approximate.
<p>The curve always increases monotonically from 0 to 1. In case of
a normal distribution, you get the erf shape; for a uniform
distribution it is a ramp. This form of presentation throws away no
information, and it shows all about the distribution of a single
variable. I am pretty sure the times that different stages of one
request take are statistically dependent, but I don&#39;t consider
that for the time being. The median is the abscissa <var>t</var> at
which the ordinate <var>F</var>(<var>t</var>)=1/2.</p><p>The curves for all nine experiments are drawn in the same graph
for comparison. Note that the abscissa is scaled very differently
for various stages.</p><h4>Steps</h4><ul>
<li>I scp the stage?? directories to my linux box, where gnuplot is
installed. Another approach would be to install gnuplot on the
machine that runs the server, i.e., dev0103-001.</li><li>The csh script plot-all goes into each stage?? subdirectory and
runs the gnuplot script distrib.gplt:
<pre>
   #! /bin/csh
   foreach i (stage[01][0-9])
     (cd $i; gnuplot ../distrib.gplt &gt; $i.gif)
     echo $i done.
   end
        
</pre>
</li>
</ul><h3>IV. Results</h3><ul>
<li>
<a href="timing-1">graphs</a> from dev0103-001,
approximately acs-4-0-beta-R20001001.</li><li>
<a href="timing-2">graphs</a> from reusia.boston,
approximately acs-4-0-beta-2-R20001009.</li><li>
<a href="timing-3">graphs</a> from reusia.boston, from ACS
3.4.6 tarball. This comparison is not completely fair.</li>
</ul><h3>V. Conclusion</h3><p>Currently, the template system doesn&#39;t meet the performance
requirement.</p><p>Earlier on dev0103-001, templated pages loaded fast enough.
Although the processing stage seems to a lot be more than 10%
slower, the overall performance is rather increased than slowed by
templating.</p><p>On reusia.boston, we had a much better performance of the
request processor. The processing times of the pages proper (stage
10 before, 11 now) didn&#39;t change much; we just got clearer
results. The total processing time of Tcl-only pages is around
155ms, while templated pages take around 220ms, that is 42% longer
(or Tcl-only pages take 30% less).</p><p>Relative times depend on the other components of the pipeline.
The difference of 65ms is a large percentage of a total serving
time of 155ms; when other parts of the system (e.g., the request
processor) were slower, this wasn&#39;t that noticeable.</p><p>For ACS 3.4, Tcl-only chain-frac-0 pages take 115ms, where the
templated versisons are much slower, 320ms for chain-frac-1 and 340
for -2.</p><h3>VI. Further Work</h3><p>Tune templating in ACS 4.0.</p><hr><address><a href="mailto:christian\@arsdigita.com">Christian
Brechbühler</a></address><!-- Created: Fri Oct  6 15:45:48 EDT 2000 --><!-- hhmts start -->
Last modified: Tue Oct 17 20:11:49 EDT 2000 <!-- hhmts end -->
</li>
</ul>
