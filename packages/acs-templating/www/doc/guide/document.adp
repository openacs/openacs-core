
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System User Guide: Documenting Data
Sources}</property>
<property name="doc(title)">Templating System User Guide: Documenting Data
Sources</property>
<master>
<h2>Documenting Data Sources</h2>
<a href="..">Templating System</a>
 : <a href="../developer-guide">Developer Guide</a>
 : User Guide
<p>Effective coordination between the developer and designer is one
of the major challenges of any publishing team. The templating
system provides a set of simple documentation directives so that
developer comments on data sources can be extracted from Tcl
scripts and summarized for non-technical members of the publishing
team automatically.</p>
<p>To take advantage of this capability, the developer must
structure comments on a datasource in the following way:</p>
<pre>
  # \@datasource cars multirow
  # The cars owned by a user.
  # \@column make The make of the car, i.e. Toyota
  # \@column model The model of the car, i.e. Camry
  # \@column year The year of manufacture
   
  # \@datasource name onevalue
  # the name of the user
  
  # \@data_input add_entry form
  # a form for adding entries to user&#39;s address book 
  # \@input first_names text 
  # entry subject&#39;s first and middle names
  # \@input last_name text
  # \@input title text form of address for entry subject
  # \@input birthday date birthdate w/ "MONTH DD YYYY" format
  # \@input gender radio
  # either "m" for male or "f" for female
    </pre>
<p>A few formatting guidelines:</p>
<ul>
<li>all datasources (onevalues, onelists, multilists, multirows)
are documented with the datasource directive, their name, the type
of datasource, and then necessary comments:</li><blockquote><code># \@datasource <em>name</em> &lt;<em>type of
datasource</em>&gt; <em>comments</em>
</code></blockquote><li>multirow datasources are followed with a series of column
directives, column names, and associated explanations:</li><blockquote><code># \@column <em>name</em><em>comments</em>
</code></blockquote><li>forms are documented with the data_input directive, and are
also followed with a series of input directives with the name and
type of input widgets, and necessary comments:</li><blockquote><code># \@data_input <em>name</em> form
<em>comments</em> # \@input <em>name</em> &lt;<em>type of form
entry</em>&gt; <em>comments</em>
</code></blockquote>
Possible form entry types include text (or textentry), date,
checkbox, radio, select, multiselect and textbox</ul>
<p>Once the templates have been enabled, the designer can simply
visit the URL from which the page will be served, substituting
<kbd>acs</kbd> with the <kbd>dat</kbd> extension.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->