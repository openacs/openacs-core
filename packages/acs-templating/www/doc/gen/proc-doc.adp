
<property name="context">{/doc/acs-templating {Templating}} {Commenting Tcl procedures for parsing}</property>
<property name="doc(title)">Commenting Tcl procedures for parsing</property>
<master>
<h2>Using comments to document Tcl procedures</h2>
<b>Templating System</b>
<h3>Text divisions, grouping</h3>
<i>&lt; blah blah &gt;</i>
 The Tcl proc parser relies on three main
text markers to divvy the Tcl library file into neat compartments:
namespace, procedure and directive. Each of these divisions has its
own text marker(s). In the end, your Tcl file should look somthing
like this:
<blockquote><pre><code><tt>
[------------------------------------------------------]
[------  <i>ignored text at beginning of file</i>  -----------]
[------------------------------------------------------]

# <font color="red">\@namespace</font><i>&lt;name&gt;</i><i>&lt;description of namespace&gt;</i>
        # <i>&lt;continued description&gt;</i>

        # <font color="red">\@author</font><i>&lt;name of the primary author for this namespace&gt;</i>

        # <font color="red">\@see</font><i>&lt;type of reference, like <b>proc</b>, <b>namespace</b>, <b>url</b>, or other&gt;</i><i>&lt;full name of reference&gt;</i><i>&lt;url of reference&gt;</i>
        # <font color="red">\@see</font> ... <i>&lt;more references&gt;</i>


   # (<font color="red">\@public</font>|<font color="red">\@private</font>) <i>&lt;name&gt;</i><i>&lt;description of procedure&gt;</i>
     # <i>&lt;continued description&gt;</i>

     # <font color="red">\@param</font><i>&lt;name&gt;</i><i>&lt;default value&gt;</i><i>&lt;description&gt;</i>
     # <i>&lt;continued description&gt;</i>

     # <font color="red">\@param</font> ... <i>&lt;info for other paramaters&gt;</i>

     # <font color="red">\@option</font><i>&lt;name&gt;</i><i>&lt;default value&gt;</i><i>&lt;description&gt;</i>
     # <i>&lt;continued description&gt;</i>

     # <font color="red">\@option</font> ... <i>&lt;info for other options&gt;</i>
 
     # <font color="red">\@author</font><i>&lt;name of author&gt;</i>

     # <font color="red">\@return</font><i>&lt;description of return variable&gt;</i>

     # <font color="red">\@see</font><i>&lt;just like the namespace \@see directive&gt;</i>

     [------------------------------------------------------]
     [----------  <i>source text for procedure</i>  ---------------] 
     [------------------------------------------------------]


   # <font color="red">\@public</font> or <font color="red">\@private</font> ... <i>&lt; more procedures within the same namespace &gt;</i>


# <font color="red">\@namespace</font> ... <i>&lt;other namespaces&gt;</i>
</tt></code></pre></blockquote>

Note that comment lines are indented to indicate the manner in
which they should be grouped only, and that there is no required
spacing scheme for comments.
<p>Use of these directive markers is largely straightforward, but a
more in depth guideline of how the markers guide parsing may help
those documenting their own work:</p>
<blockquote>
<b>the \@namespace marker</b><ul>
<li>
<code><b>\@namespace</b></code> is used to indicate the starting
point of all text -- code and comments -- related to the procedures
contained within that namespace. All text between one
<code>\@namespace</code> marker and the next is parsed out as either
Tcl proc source text or commentary of some sort</li><li>the body of text that falls between two <code>\@namespace</code>
markers is divided into sections identified by</li>
</ul><b>the \@public/private markers</b><ul>
<li>although this convention is in no way enforced, each Tcl
procedure should be prefaced with an <code>\@private</code> marker
if the procedure is meant only for internal package use, or with an
<code>\@public</code> marker if the proc is intended to be a CMA,
ATS, or ACS Content Repository developer api</li><li>any text that falls between one \@public/private marker and the
next <code>proc &lt;procedure name&gt;</code> call will be parsed
out as commentary text; all text after the <code>proc</code>
command but before the next <code>\@private</code> or
<code>\@public</code> marker is recorded as source code</li>
</ul><b>the directive markers</b><br>
The commentary text that precedes a Tcl <code>proc</code> command
should contain a list of directives identified by these markers:
<ul>
<li><code>\@author</code></li><li><code>\@param</code></li><li><code>\@option</code></li><li><code>\@return</code></li><li><code>\@see</code></li>
</ul>
The parser requires no specified ordering or grouping of these
directives. Note: there should be one <code>\@param</code> or
<code>\@option</code> directive marker for each parameter and option
accepted by Tcl procedure. For the <b>\@option</b> and
<b>\@parameter</b> markers, please follow one of the following
formats, depending on whether or not the parameter or option you
are detailing has a default value:
<blockquote>with a default value:
<blockquote><code># \@(param|option) <i>&lt;parameter name&gt;</i>
{default <i>&lt;description of default value&gt;</i>}
<i>&lt;description or explanation&gt;</i>
</code></blockquote>
for required parameters:
<blockquote><code># \@param <i>&lt;parameter name&gt;</i><i>&lt;description or explanation&gt;</i>
</code></blockquote>
</blockquote>
Note that the literal curly brackets with the word
<b><i>default</i></b> are required to include any information about
the option or parameter's default values. When default-value
information is not included, the entry value will be marked as
<i>required</i> if it is a parameter, or display no information if
it is an option.
<p>For example: the fictional procedure grant_permission might be
preceded by these comments:</p><blockquote><pre><code># \@public grant_permission
# checks for whether or not a user has the privilege 
# to manipulate an object in a specific manner

# \@param user_id id of the user to be granted the privilege

# \@param object_id id of the object which the user has been 
# granted privilege to manipulate

# \@param privilege_id {default defaults to read-write-edit on the object} 
# id of the privilege specifying 
# what actions the user can perform upon the object

# \@option granter_id {default taken from the current user's id} id of the user granting the privilege
# \@option alert_admin_email email of an admin to be alerted

# \@see namespace util util.html

</code></pre></blockquote>
In the above example <code>user_id</code> and
<code>object_id</code> would be marked as required,
<code>alert_admin_email</code> would show no default-value
description, and <code>granter_id</code> and
<code>privilege_id</code> would show the the default info from
above.
<p>On to <b>\@see</b> directive markers:</p><blockquote># \@see <i>&lt;type of reference&gt;</i><i>&lt;name of
reference&gt;</i><i>&lt;url of reference&gt;</i>
</blockquote>
Indicating the url of the reference is made somewhat simple because
all namespaces will be described within their own static html page,
and all procedure information is anchor-referenced:
<blockquote><pre><code>
# \@see namespace util util.html
# \@see proc template::multirow::create multiow.html#template::multirow::create
# \@see url <i>&lt;a picture of wally my dog&gt;</i> http://my.page.net/dogs/wally.jpg
# \@see proc doc::util::eat_chicken
</code></pre></blockquote>
If you are referring to a namespace or procedure (use
<code>proc</code> for the reference type), the url value is
optional as long as you use the <b>full</b> and <b>completely
qualified</b> name of the namespace or procedure.</blockquote>
<hr>
<a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
