
<property name="context">{/doc/acs-reference {ACS Reference Data}} {acs-reference Design Documentation}</property>
<property name="doc(title)">acs-reference Design Documentation</property>
<master>

<body>
<h2>acs-reference Design Documentation</h2><h3>I. Introduction</h3><p>Reference data services are often overlooked in the rush to get
coding. Much of the code is redundant or of similarly patterned
implementations. This package intends to address some common
features and needs.</p><h3>II. Historical Considerations</h3><p>Before the existence of acs-reference, the ACS required that you
preload some tables in a script to get some basic reference
functionality. There were many problems with this:</p><ul>
<li>No easy way to find out what reference data even existed.</li><li>No way to find out how old the data was.</li><li>No way to find out where that data came from.</li><li>Very US/English slant on the data.</li>
</ul><h3>III. Design Tradeoffs</h3><h4>Primary Goals</h4><ul>
<li>This system was designed with maintainability and reusability
as its primary goals. By wrapping a layer around all of the
reference tables we have increased the maintainability
immensely.</li><li>Another goal was to bring together many different types of data
and present them in a logical fashion. It was amazing how little of
this data is available on the internet in a database friendly
form.</li>
</ul><h4>Performance</h4>
When updating the reference tables their is overhead due to the
fact that the table is registered with the repository. This should
rarely occur anyway as the tables are only added once. By not
having the actual data itself in the acs-object system, subsequent
additions and deletions to the reference tables themselves are
unaffected by this overhead.
<h3>IV. API</h3><p>See <a href="/api-doc/index?about_package_key=acs-reference">api-browser</a>
</p><h3>V. Data Model Discussion</h3><p>The UNSPSC reference data has a data model for handling data
revisions. An application can determine any new/revised category
based on existing, obsolete data.</p><h3>VI. User Interface</h3><p>Their is no end user interface. There needs to be some kind of
admin UI to report status and possibly manage updates per
requirements.</p><h3>VII. Configuration/Parameters</h3><p>None</p><h3>VIII. Future Improvements/Areas of Likely Change</h3><p>A server based update mechanism will be supported. This will
allow for tables to be updated (and preferably diffed) instead of
being reloaded with a package upgrade. An interface to produce
xml/csv from the reference data would be a nice service to the
community (allowing legacy applications a way to import this
data).</p><h3>IX. Authors</h3><p>Jon Griffin</p><h3>X. Pre-CVS Revision History</h3><pre>
$Log$
Revision 1.4  2006/08/06 20:40:20  torbenb
upgrading html, closing li p tags, adding quotes to tag attributes

Revision 1.3  2006/08/06 18:54:02  torbenb
added documentation commentary, applied bs filter, renumbered sections

Revision 1.2  2006/08/06 18:30:57  torbenb
removing c-Ms, wrapping text with p tags, added link to api-browser in api section

Revision 1.1  2001/04/22 00:53:12  jong
initial openacs import

Revision 1.2  2000/12/13 04:39:00  jong
Added Revision History and corrected typo in reference link
</pre>
</body>
