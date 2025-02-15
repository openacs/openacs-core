
<property name="context">{/doc/acs-templating/ {ACS Templating}} {Commenting Tcl procedures for parsing}</property>
<property name="doc(title)">Commenting Tcl procedures for parsing</property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<h2>Using comments to document Tcl procedures</h2>
<strong>Templating System</strong>
<h3>Text divisions, grouping</h3>
<em>&lt; blah blah &gt;</em>
 The Tcl proc parser relies on three
main text markers to divvy the Tcl library file into neat
compartments: namespace, procedure and directive. Each of these
divisions has its own text marker(s). In the end, your Tcl file
should look something like this:
<blockquote><pre><code><kbd>

[------------------------------------------------------]
[------  <em>ignored text at beginning of file</em>  -----------]
[------------------------------------------------------]

# <font color="red">\@namespace</font><em>&lt;name&gt;</em><em>&lt;description of namespace&gt;</em>
        # <em>&lt;continued description&gt;</em>

        # <font color="red">\@author</font><em>&lt;name of the primary author for this namespace&gt;</em>

        # <font color="red">\@see</font><em>&lt;type of reference, like <strong>proc</strong>, <strong>namespace</strong>, <strong>url</strong>, or other&gt;</em><em>&lt;full name of reference&gt;</em><em>&lt;url of reference&gt;</em>
        # <font color="red">\@see</font> ... <em>&lt;more references&gt;</em>


   # (<font color="red">\@public</font>|<font color="red">\@private</font>) <em>&lt;name&gt;</em><em>&lt;description of procedure&gt;</em>
     # <em>&lt;continued description&gt;</em>

     # <font color="red">\@param</font><em>&lt;name&gt;</em><em>&lt;default value&gt;</em><em>&lt;description&gt;</em>
     # <em>&lt;continued description&gt;</em>

     # <font color="red">\@param</font> ... <em>&lt;info for other parameters&gt;</em>

     # <font color="red">\@option</font><em>&lt;name&gt;</em><em>&lt;default value&gt;</em><em>&lt;description&gt;</em>
     # <em>&lt;continued description&gt;</em>

     # <font color="red">\@option</font> ... <em>&lt;info for other options&gt;</em>
 
     # <font color="red">\@author</font><em>&lt;name of author&gt;</em>

     # <font color="red">\@return</font><em>&lt;description of return variable&gt;</em>

     # <font color="red">\@see</font><em>&lt;just like the namespace \@see directive&gt;</em>

     [------------------------------------------------------]
     [----------  <em>source text for procedure</em>  ---------------] 
     [------------------------------------------------------]


   # <font color="red">\@public</font> or <font color="red">\@private</font> ... <em>&lt; more procedures within the same namespace &gt;</em>


# <font color="red">\@namespace</font> ... <em>&lt;other namespaces&gt;</em>
</kbd></code></pre></blockquote>

Note that comment lines are indented to indicate the manner in
which they should be grouped only, and that there is no required
spacing scheme for comments.
<p>Use of these directive markers is largely straightforward, but a
more in depth guideline of how the markers guide parsing may help
those documenting their own work:</p>
<blockquote>
<strong>the \@namespace marker</strong><ul>
<li>
<code><strong>\@namespace</strong></code> is used to indicate
the starting point of all text -- code and comments -- related to
the procedures contained within that namespace. All text between
one <code>\@namespace</code> marker and the next is parsed out as
either Tcl proc source text or commentary of some sort</li><li>the body of text that falls between two <code>\@namespace</code>
markers is divided into sections identified by</li>
</ul><strong>the \@public/private markers</strong><ul>
<li>although this convention is in no way enforced, each Tcl
procedure should be prefaced with an <code>\@private</code> marker
if the procedure is meant only for internal package use, or with an
<code>\@public</code> marker if the proc is intended to be a CMA,
ATS, or ACS Content Repository developer api</li><li>any text that falls between one \@public/private marker and the
next <code>proc &lt;procedure name&gt;</code> call will be parsed
out as commentary text; all text after the <code>proc</code>
command but before the next <code>\@private</code> or
<code>\@public</code> marker is recorded as source code</li>
</ul><strong>the directive markers</strong><br>
The commentary text that precedes a Tcl <code>proc</code> command
should contain a list of directives identified by these markers:
<ul>
<li><code>\@author</code></li><li><code>\@param</code></li><li><code>\@option</code></li><li><code>\@return</code></li><li><code>\@see</code></li>
</ul>
The parser requires no specified ordering or grouping of these
directives. Note: there should be one <code>\@param</code> or
<code>\@option</code> directive marker for each parameter and option
accepted by Tcl procedure. For the <strong>\@option</strong> and
<strong>\@parameter</strong> markers, please follow one of the
following formats, depending on whether or not the parameter or
option you are detailing has a default value:
<blockquote>with a default value:
<blockquote><code># \@(param|option) <em>&lt;parameter name&gt;</em>
{default <em>&lt;description of default value&gt;</em>}
<em>&lt;description or explanation&gt;</em>
</code></blockquote>
for required parameters:
<blockquote><code># \@param <em>&lt;parameter name&gt;</em><em>&lt;description or explanation&gt;</em>
</code></blockquote>
</blockquote>
Note that the literal curly brackets with the word
<strong><em>default</em></strong> are required to include any
information about the option or parameter&#39;s default values.
When default-value information is not included, the entry value
will be marked as <em>required</em> if it is a parameter, or
display no information if it is an option.
<p>For example: the fictional procedure grant_permission might be
preceded by these comments:</p><blockquote><pre><code>
# \@public grant_permission
# checks for whether or not a user has the privilege 
# to manipulate an object in a specific manner

# \@param user_id id of the user to be granted the privilege

# \@param object_id id of the object which the user has been 
# granted privilege to manipulate

# \@param privilege_id {default defaults to read-write-edit on the object} 
# id of the privilege specifying 
# what actions the user can perform upon the object

# \@option granter_id {default taken from the current user&#39;s id} id of the user granting the privilege
# \@option alert_admin_email email of an admin to be alerted

# \@see namespace util util.html

</code></pre></blockquote>
In the above example <code>user_id</code> and
<code>object_id</code> would be marked as required,
<code>alert_admin_email</code> would show no default-value
description, and <code>granter_id</code> and
<code>privilege_id</code> would show the default info from above.
<p>On to <strong>\@see</strong> directive markers:</p><blockquote># \@see <em>&lt;type of reference&gt;</em><em>&lt;name
of reference&gt;</em><em>&lt;url of
reference&gt;</em>
</blockquote>
Indicating the url of the reference is made somewhat simple because
all namespaces will be described within their own static html page,
and all procedure information is anchor-referenced:
<blockquote><pre><code>
# \@see namespace util util.html
# \@see proc template::multirow::create multirow.html#template::multirow::create
# \@see url <em>&lt;a picture of wally my dog&gt;</em> http://my.page.net/dogs/wally.jpg
# \@see proc doc::util::eat_chicken
</code></pre></blockquote>
If you are referring to a namespace or procedure (use
<code>proc</code> for the reference type), the url value is
optional as long as you use the <strong>full</strong> and
<strong>completely qualified</strong> name of the namespace or
procedure.</blockquote>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->