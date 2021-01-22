
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h3>Data Source API</h3>
<p>We need to resolve how onerow and multirow data sources are
represented internally, and plug in the proper API. I originally
used ns_sets to represent rows in a data source (and continue to do
so for the time being). jsalz instead uses arrays and lists to
represent rows. Task: look at jsalz&#39;s data source code.</p>
