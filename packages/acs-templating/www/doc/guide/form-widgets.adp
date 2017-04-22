
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System User Guide: Custom Form Widgets}</property>
<property name="doc(title)">Templating System User Guide: Custom Form Widgets</property>
<master>
<h2>Custom Form Widgets</h2>
<a href="..">Templating System</a>
 : <a href="../developer-guide">Developer Guide</a>
 : User Guide
<p>Form widgets are implemented as Tcl procs that output the html
to generate the form element. The Tcl proc must be in the
template::widget namespace. So the proc for the search widget is
called template::widget::search. The code that generates the built
in widgets is in packages/acs-templating/tcl/widget-procs.tcl.</p>
<p>If the data from the form widget needs to be formatted or
processed a Tcl proc is created in the template::data::transform
namespace. For example, templatete::data::transform::search. This
takes the input from the user and processes it to be returned to
the Tcl code handling the form.</p>
<hr>
