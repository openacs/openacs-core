
<property name="context">{/doc/acs-templating {Templating}} {Templating System User Guide: Validating and Processing Form
Submissions}</property>
<property name="doc(title)">Templating System User Guide: Validating and Processing Form
Submissions</property>
<master>
<h2>Validating and Processing Form Submissions</h2>
<p>
<b>Important Note:</b> The <tt><a href="http://openacs.org//api-doc/proc-view?proc=ad%5fform">ad_form</a></tt>
function has been written to be a more consistent, easier way to
create and manage dynamic forms. Behind the scenes it uses the
templating system's form builder, but it hides much of its
complexity. You should definitely look at it and at the pages that
use it in the survey package.</p>
<p>The templating system provides a simple infrastructure for
validating form submissions. The typical life-cycle of a form is as
follows:</p>
<ol>
<li>The user makes the initial request for a page containing a
form. The code associated with the page creates the form (with the
<tt>form create</tt> command) and populates it with elements.</li><li>The developer may use the <tt>form is_request</tt> command to
encapsulate any special initialization (for example, setting a
primary key value for an <b>Add</b> form, or retrieving current
values for an <b>Edit</b> form).</li><li>The <tt>formtemplate</tt> tag is used to enclose the form
template. This tag is responsible for generating the appropriate
HTML <tt>FORM</tt> tag in the final output. The
<tt>formtemplate</tt> tag also embeds a special hidden variable in
the form for the purpose of identifying incoming submissions.</li><li>By default, the <tt>formtemplate tag</tt> sets the
<tt>ACTION</tt> attribute of the <tt>FORM</tt> tag to the
<em>same</em> URL as that of the form itself. The submission is
therefor processed within the framework of the same code that was
used to create the form.</li>
</ol>
<hr>
<a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
