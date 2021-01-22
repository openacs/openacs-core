
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System User Guide: Validating and Processing Form
Submissions}</property>
<property name="doc(title)">Templating System User Guide: Validating and Processing Form
Submissions</property>
<master>
<h2>Validating and Processing Form Submissions</h2>
<strong>
<a href="../index">Templating System</a> : User
Guide</strong>
<p>
<strong>Important Note:</strong> The <kbd><a href="http://openacs.org//api-doc/proc-view?proc=ad%5fform">ad_form</a></kbd>
function has been written to be a more consistent, easier way to
create and manage dynamic forms. Behind the scenes it uses the
templating system&#39;s form builder, but it hides much of its
complexity. You should definitely look at it and at the pages that
use it in the survey package.</p>
<p>The templating system provides a simple infrastructure for
validating form submissions. The typical life-cycle of a form is as
follows:</p>
<ol>
<li>The user makes the initial request for a page containing a
form. The code associated with the page creates the form (with the
<kbd>form create</kbd> command) and populates it with
elements.</li><li>The developer may use the <kbd>form is_request</kbd> command to
encapsulate any special initialization (for example, setting a
primary key value for an <strong>Add</strong> form, or retrieving
current values for an <strong>Edit</strong> form).</li><li>The <kbd>formtemplate</kbd> tag is used to enclose the form
template. This tag is responsible for generating the appropriate
HTML <kbd>FORM</kbd> tag in the final output. The
<kbd>formtemplate</kbd> tag also embeds a special hidden variable
in the form for the purpose of identifying incoming
submissions.</li><li>By default, the <kbd>formtemplate tag</kbd> sets the
<kbd>ACTION</kbd> attribute of the <kbd>FORM</kbd> tag to the
<em>same</em> URL as that of the form itself. The submission is
therefor processed within the framework of the same code that was
used to create the form.</li>
</ol>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->