
<property name="context">{/doc/acs-reference {ACS Reference Data}} {ACS Reference Requirements}</property>
<property name="doc(title)">ACS Reference Requirements</property>
<master>
<h2>ACS Reference Requirements</h2>
<p>by <a href="mailto:jon\@jongriffin.com">Jon Griffin</a>
</p>
<hr>
<h3>I. Introduction</h3>
<p>This document describes the requirements for the ACS Reference
service package. This package has the following primary
functions:</p>
<ul>
<li>It allows applications to refer to and employ a common set of
reference data.</li><li>It gives administrators the ability to run standard reports on
this data.</li><li>It offers a convenient repository for and the ability to run
reports on data of this sort.</li><li>It allows us to monitor the usage of reference data.</li>
</ul>
<h3>II. Vision Statement</h3>
<p>What is reference data? Simply put, it is data that doesn&#39;t
change very often and also in many cases comes from an external
source and not from within the system itself. Many times it is
created from a standards body, i.e. <a href="http://www.iso.ch/">ISO</a> or <a href="http://www.ansi.org">ANSI</a>, and may be required for a
client&#39;s particular industrial needs.</p>
<p>Some examples of reference data are:</p>
<ul>
<li>Geographic data: zip codes, country codes and
states/provinces</li><li>Standards bodies data: ISO 4217 currency codes, ISO 3166
Country Codes, ITU Vehicle Signs</li><li>Quasi-Standards: S&amp;P Long-term Issuer Credit Ratings</li><li>Internal: Status Codes, Employee Position Codes</li>
</ul>
<p>Historically, reference data has been looked upon by developers
as something less important than more immediate coding needs, and
so most data models simply defer the issue by treating reference
data as something simple to implement. Elsewhere. The reality is
that for most organizations reference data is extremely important
and also extremely difficult to manage.</p>
<p>This module will not only <em>package</em> all of a site&#39;s
reference data in one place, it will also help manage that
data.</p>
<h3>III. System Overview</h3>
<p>The ACS Reference package consists of:</p>
<ul>
<li>A standard framework for monjitoring and modifying reference
data.</li><li>A method of determining whether or not that data is
expired.</li><li>The ability to include not only the data but also functions to
work with that data.</li>
</ul>
<h3>IV. Use-cases and User-Scenarios</h3>
<p>Papi Programmer is developing a module that will use country
codes as part of his table structure. Instead of creating his own
table he can use the ACS Reference package and the country codes
therein. If the country codes change - which does in fact happen
from time to time - the ACS Reference package will maintain that
information for him.</p>
<h3>V. Related Links</h3>
<ul><li><a href="design">Design document</a></li></ul>
<h3>VI.A Requirements: Data Model</h3>
<p>10.10 The package should use a table that is the <em>master</em>
table for all reference tables.<br>
10.20 The package should employ a field to show whether this data
is internally derived or not.<br>
10.30 The package should employ a field to signify whether there is
a PL/SQL package involved with this table.<br>
10.40 The package should offer an indicatation of when this data
was last updated.<br>
10.50 The package should offer an indication of what the original
source of this data was.<br>
10.60 The package should offer an indication of what the original
source URL was, if any.<br>
10.70 The package should offer a representation of effective
datetime<br>
10.80 The package should offer a representation of discontinued
datetime<br>
10.90 The package should keep an indication of who the data
maintainer is, by user_id.</p>
<h3>VI.B Requirements: API</h3>
<p>20.10 The package should offer a function to determine if a
particular table has expired.</p>
<p>The requirements below are not met by the current
implementation:</p>
<p>30.10 There needs to be a way to query the data source and
update automatically. If that isn&#39;t possible, as it won&#39;t
be in many cases, the application should be able to query a master
server and see if there is new data for a particular table or
tables. For example: refdata.arsdigita.com could hold the reference
tables and when newer table versions become available, simply
upload only these versions or perhaps even only the differences
between the tables. In any case, there should be an admin page that
shows current status and revisions of various data, where to find
info about additional sources (if applicable), and provide a UI to
upload or import new data.</p>
<h3>VII. Implementation Notes</h3>
<p>The package needs to handle changes to reference data in a
graceful fashion. For example, if a country splits into two or more
countries, what should happen?</p>
<ul>
<li>The reference package should note this change.</li><li>The appropriate table is updated. In this case countries et
al.</li><li>An update to the repository database field effective_date is
added.</li><li>A <em>diff</em> type of entry into the reference repository
history. <font color="red"><em>This is not in the current data
model</em></font>
</li><li>Then any sub-programs using this data will note the change of
effective date and be able to handle the change as needed (i.e.
simply read the new table).</li><li>Historical data will be available using this <em>diff</em> for
those applications that need to use the old data</li>
</ul>
<p>Note also that it is possible to have overlapping effective
dates. This will not be implemented in the first version, but
should be recognized and accommodated throughout the development
process for the service package.</p>
