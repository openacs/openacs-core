
<property name="context">{/doc/acs-templating/ {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<h2>Namespace content</h2>
<blockquote>Procedures for generating and processing content
content creation and editing forms..</blockquote>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>
<a href="#content::add_attribute_element">content::add_attribute_element</a><br><a href="#content::add_attribute_elements">content::add_attribute_elements</a><br><a href="#content::add_basic_revision">content::add_basic_revision</a><br><a href="#content::add_child_relation_element">content::add_child_relation_element</a><br><a href="#content::add_content">content::add_content</a><br><a href="#content::add_content_element">content::add_content_element</a><br><a href="#content::add_revision">content::add_revision</a><br><a href="#content::add_revision_form">content::add_revision_form</a><br><a href="#content::copy_content">content::copy_content</a><br><a href="#content::get_attribute_enum_values">content::get_attribute_enum_values</a><br><a href="#content::get_latest_revision">content::get_latest_revision</a><br><a href="#content::get_object_id">content::get_object_id</a><br><a href="#content::new_item">content::new_item</a><br><a href="#content::new_item_form">content::new_item_form</a><br><a href="#content::validate_name">content::validate_name</a><br>
</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<strong>Public Methods:</strong>
<br>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::add_attribute_element" id="content::add_attribute_element"><font size="+1" weight="bold">content::add_attribute_element</font></a></td></tr><tr><td>
<blockquote>Add a form element (possibly a compound widget) to an
ATS form object. for entering or editing an attribute
value.</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form_name</code><font color="red">*</font>
</td><td align="left">The name of the ATS form object to which the
element should be added.</td>
</tr><tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The content type keyword to which this attribute
belongs.</td>
</tr><tr>
<td align="right">
<code>attribute</code><font color="red">*</font>
</td><td align="left">The name of the attribute, as represented in the
attribute_name column of the acs_attributes table.</td>
</tr><tr>
<td align="right">
<code>attribute_data</code><font color="red">*</font>
</td><td align="left">Optional nested list of parameter data for the
attribute (generated by get_attribute_params).</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::add_attribute_elements" id="content::add_attribute_elements"><font size="+1" weight="bold">content::add_attribute_elements</font></a></td></tr><tr><td>
<blockquote>Add form elements to an ATS form object for all
attributes of a content type.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form_name</code><font color="red">*</font>
</td><td align="left">The name of the ATS form object to which objects
should be added.</td>
</tr><tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The content type keyword for which attribute
widgets should be added.</td>
</tr><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The revision from which default values should be
queried</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>The list of attributes that were added.</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::add_basic_revision" id="content::add_basic_revision"><font size="+1" weight="bold">content::add_basic_revision</font></a></td></tr><tr><td>
<blockquote>Create a basic new revision using the content_revision
PL/SQL API.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left"></td>
</tr><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left"></td>
</tr><tr>
<td align="right">
<code>title</code><font color="red">*</font>
</td><td align="left"></td>
</tr>
</table>
</dd><dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>description</code></td><td align="left"></td>
</tr><tr>
<td align="right"><code>mime_type</code></td><td align="left"></td>
</tr><tr>
<td align="right"><code>text</code></td><td align="left"></td>
</tr><tr>
<td align="right"><code>tmpfile</code></td><td align="left"></td>
</tr>
</table></dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::add_child_relation_element" id="content::add_child_relation_element"><font size="+1" weight="bold">content::add_child_relation_element</font></a></td></tr><tr><td>
<blockquote>Add a select box listing all valid child relation tags.
The form must contain a parent_id element and a content_type
element. If the elements do not exist, or if there are no valid
relation tags, this proc does nothing.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>form_name</code><font color="red">*</font>
</td><td align="left">The name of the form</td>
</tr></table>
</dd><dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>section</code></td><td align="left">
<em>none</em> If present, creates a new form
section for the element.</td>
</tr><tr>
<td align="right"><code>label</code></td><td align="left">{Child relation tag} The label for the
element</td>
</tr>
</table></dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::add_content" id="content::add_content"><font size="+1" weight="bold">content::add_content</font></a></td></tr><tr><td>
<blockquote>Update the BLOB column of a revision with content
submitted in a form</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The object ID of the revision to be updated.</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::add_content_element" id="content::add_content_element"><font size="+1" weight="bold">content::add_content_element</font></a></td></tr><tr><td>
<blockquote>Adds a content input element to an ATS form
object.</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form_name</code><font color="red">*</font>
</td><td align="left">The name of the form to which the object should be
added.</td>
</tr><tr>
<td align="right">
<code>content_method</code><font color="red">*</font>
</td><td align="left">One of no_content, text_entry or file_upload</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::add_revision" id="content::add_revision"><font size="+1" weight="bold">content::add_revision</font></a></td></tr><tr><td>
<blockquote>Create a new revision for an existing item based on a
valid form submission. Queries for attribute names and inserts a
row into the attribute input view for the appropriate content type.
Inserts the contents of a file into the content column of the
cr_revisions table for the revision as well.</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form_name</code><font color="red">*</font>
</td><td align="left">Name of the form from which to obtain attribute
values. The form should include an item_id and revision_id.</td>
</tr><tr>
<td align="right">
<code>tmpfile</code><font color="red">*</font>
</td><td align="left">Name of the temporary file containing the content
to upload.</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::add_revision_form" id="content::add_revision_form"><font size="+1" weight="bold">content::add_revision_form</font></a></td></tr><tr><td>
<blockquote>Adds elements to an ATS form object for adding a
revision to an existing item. If the item already exists, element
values default a previous revision (the latest one by default). If
the form does not already exist, creates the form object and sets
its enctype to multipart/form-data to allow for text entries
greater than 4000 characters.</blockquote><dl>
<dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>form_name</code></td><td align="left">The name of the ATS form object. Defaults to {
new_item} .</td>
</tr><tr>
<td align="right"><code>content_type</code></td><td align="left">The content_type of the item. Defaults to {
content_revision} .</td>
</tr><tr>
<td align="right"><code>content_method</code></td><td align="left">The method to use for uploading the content body.
If the content type is text, defaults to text entry, otherwise
defaults to file upload.</td>
</tr><tr>
<td align="right"><code>item_id</code></td><td align="left">The item ID of the revision. Defaults to null
(item_id must be set by the calling code).</td>
</tr><tr>
<td align="right"><code>revision_id</code></td><td align="left">The revision ID from which to draw default values.
Defaults to the latest revision</td>
</tr><tr>
<td align="right"><code>attributes</code></td><td align="left">A list of attribute names for which to create form
elements.</td>
</tr><tr>
<td align="right"><code>action</code></td><td align="left">The URL to which the form should redirect
following a successful form submission.</td>
</tr>
</table></dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::copy_content" id="content::copy_content"><font size="+1" weight="bold">content::copy_content</font></a></td></tr><tr><td>
<blockquote>Update the BLOB column of one revision with the content
of another revision</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>revision_id_src</code><font color="red">*</font>
</td><td align="left">The object ID of the revision with the content to
be copied.</td>
</tr><tr>
<td align="right">
<code>revision_id_dest</code><font color="red">*</font>
</td><td align="left">The object ID of the revision to be updated.
copied.</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::get_attribute_enum_values" id="content::get_attribute_enum_values"><font size="+1" weight="bold">content::get_attribute_enum_values</font></a></td></tr><tr><td>
<blockquote>Returns a list of { pretty_name enum_value } for an
attribute of datatype enumeration.</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>attribute_id</code><font color="red">*</font>
</td><td align="left">The primary key of the attribute as in the
attribute_id column of the acs_attributes table.</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::get_latest_revision" id="content::get_latest_revision"><font size="+1" weight="bold">content::get_latest_revision</font></a></td></tr><tr><td>
<blockquote>Get the ID of the latest revision for the specified
content item.</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The ID of the content item.</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::get_object_id" id="content::get_object_id"><font size="+1" weight="bold">content::get_object_id</font></a></td></tr><tr><td><blockquote>Grab an object ID for creating a new ACS
object.</blockquote></td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::new_item" id="content::new_item"><font size="+1" weight="bold">content::new_item</font></a></td></tr><tr><td>
<blockquote>Create a new item, including the initial revision,
based on a valid form submission.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form_name</code><font color="red">*</font>
</td><td align="left">Name of the form from which to obtain item
attributes, as well as attributes of the initial revision. The form
should include an item_id, name and revision_id.</td>
</tr><tr>
<td align="right">
<code>tmpfile</code><font color="red">*</font>
</td><td align="left">Name of the temporary file containing the content
to upload for the initial revision.</td>
</tr>
</table>
</dd><dt><strong>See Also:</strong></dt><dd>add_revision - <a href=""></a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::new_item_form" id="content::new_item_form"><font size="+1" weight="bold">content::new_item_form</font></a></td></tr><tr><td>
<blockquote>Adds elements to an ATS form object for creating an
item and its initial revision. If the form does not already exist,
creates the form object and sets its enctype to multipart/form-data
to allow for text entries greater than 4000
characters.</blockquote><dl>
<dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>form_name</code></td><td align="left">The name of the ATS form object. Defaults to {
new_item} .</td>
</tr><tr>
<td align="right"><code>content_type</code></td><td align="left">The content_type of the item. Defaults to {
content_revision} .</td>
</tr><tr>
<td align="right"><code>content_method</code></td><td align="left">The method to use for uploading the content body.
Valid values are { no_content} , { text_entry} , and { file_upload}
. If the content type allows text, defaults to text entry,
otherwise defaults to file upload.</td>
</tr><tr>
<td align="right"><code>parent_id</code></td><td align="left">The item ID of the parent. Defaults to null
(Parent is the root folder).</td>
</tr><tr>
<td align="right"><code>name</code></td><td align="left">The default name of the item. Default is an empty
string (User must supply name).</td>
</tr><tr>
<td align="right"><code>attributes</code></td><td align="left">A list of attribute names for which to create form
elements.</td>
</tr><tr>
<td align="right"><code>action</code></td><td align="left">The URL to which the form should redirect
following a successful form submission.</td>
</tr>
</table></dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::validate_name" id="content::validate_name"><font size="+1" weight="bold">content::validate_name</font></a></td></tr><tr><td>
<blockquote>Make sure that name is unique for the
folder</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>form_name</code><font color="red">*</font>
</td><td align="left">The name of the form (containing name and
parent_id)</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>0 if there are items with the same name, 1 otherwise</dd>
</dl>
</td></tr>
</table>
<p>
<strong>Private Methods</strong>:<br>
</p>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::add_revision_dml" id="content::add_revision_dml"><font size="+1" weight="bold">content::add_revision_dml</font></a></td></tr><tr><td>
<blockquote>Perform the DML to insert a revision into the
appropriate input view.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>statement</code><font color="red">*</font>
</td><td align="left">The DML for the insert statement, specifying a
bind variable for each column value.</td>
</tr><tr>
<td align="right">
<code>bind_vars</code><font color="red">*</font>
</td><td align="left">An ns_set containing the values for all bind
variables.</td>
</tr><tr>
<td align="right">
<code>tmpfile</code><font color="red">*</font>
</td><td align="left">The server-side name of the file containing the
body of the revision to upload into the content BLOB column of
cr_revisions.</td>
</tr><tr>
<td align="right">
<code>filename</code><font color="red">*</font>
</td><td align="left">The client-side name of the file containing the
body of the revision to upload into the content BLOB column of
cr_revisions</td>
</tr>
</table>
</dd><dt><strong>See Also:</strong></dt><dd>add_revision - <a href=""></a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::attribute_insert_statement" id="content::attribute_insert_statement"><font size="+1" weight="bold">content::attribute_insert_statement</font></a></td></tr><tr><td>
<blockquote>Prepare the insert statement into the attribute input
view for a new revision (see the content repository documentation
for details about the view).</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The content type of the item for which a new
revision is being prepared.</td>
</tr><tr>
<td align="right">
<code>table_name</code><font color="red">*</font>
</td><td align="left">The storage table of the content type.</td>
</tr><tr>
<td align="right">
<code>bind_vars</code><font color="red">*</font>
</td><td align="left">The name of an ns_set in which to store the
attribute values for the revision. (Typically duplicates the
contents of {[ns_getform].}</td>
</tr><tr>
<td align="right">
<code>form_name</code><font color="red">*</font>
</td><td align="left">The name of the ATS form object used to process
the submission.</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::get_attribute_params" id="content::get_attribute_params"><font size="+1" weight="bold">content::get_attribute_params</font></a></td></tr><tr><td>
<blockquote>Query for parameters associated with a particular
attribute</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The content type keyword to which this attribute
belongs.</td>
</tr><tr>
<td align="right">
<code>attribute_name</code><font color="red">*</font>
</td><td align="left">The name of the attribute, as represented in the
attribute_name column of the acs_attributes table.</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::get_attributes" id="content::get_attributes"><font size="+1" weight="bold">content::get_attributes</font></a></td></tr><tr><td>
<blockquote>Returns columns from the acs_attributes table for all
attributes associated with a content type.</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The name of the content type (ACS Object Type) for
which to obtain the list of attributes.</td>
</tr><tr>
<td align="right">
<code>args</code><font color="red">*</font>
</td><td align="left">Names of columns to query. If no columns are
specified, returns a simple list of attribute names.</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::get_default_content_method" id="content::get_default_content_method"><font size="+1" weight="bold">content::get_default_content_method</font></a></td></tr><tr><td>
<blockquote>Gets the content input method most appropriate for a
content type, based on the MIME types that are registered for that
content type.</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The content type for which an input method is
needed.</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::get_sql_value" id="content::get_sql_value"><font size="+1" weight="bold">content::get_sql_value</font></a></td></tr><tr><td>
<blockquote>Return the SQL statement for a column value in an
insert or update statement, using a bind variable for the actual
value and wrapping it in a conversion function where
appropriate.</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>name</code><font color="red">*</font>
</td><td align="left">The name of the column and bind variable (they
should be the same).</td>
</tr><tr>
<td align="right">
<code>datatype</code><font color="red">*</font>
</td><td align="left">The datatype of the column.</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::get_type_attribute_params" id="content::get_type_attribute_params"><font size="+1" weight="bold">content::get_type_attribute_params</font></a></td></tr><tr><td>
<blockquote>Query for attribute form metadata</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>args</code><font color="red">*</font>
</td><td align="left">Any number of object types</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>A list of attribute parameters nested by object_type,
attribute_name and the is_html flag. For attributes with no
parameters, there is a single entry with is_html as null.</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::get_type_info" id="content::get_type_info"><font size="+1" weight="bold">content::get_type_info</font></a></td></tr><tr><td>
<blockquote>Return specified columns from the acs_object_types
table.</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>object_type</code><font color="red">*</font>
</td><td align="left">Object type key for which info is required.</td>
</tr><tr>
<td align="right">
<code>ref</code><font color="red">*</font>
</td><td align="left">If no further arguments, name of the column value
to return. If further arguments are specified, name of the array in
which to store info in the calling</td>
</tr><tr>
<td align="right">
<code>args</code><font color="red">*</font>
</td><td align="left">Column names to query.</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::get_widget_param_value" id="content::get_widget_param_value"><font size="+1" weight="bold">content::get_widget_param_value</font></a></td></tr><tr><td>
<blockquote>Utility procedure to return the value of a widget
parameter</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>array_ref</code><font color="red">*</font>
</td><td align="left">The name of an array in the calling frame
containing parameter data selected from the form metadata.</td>
</tr><tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The current content {type;} defaults to
content_revision</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::prepare_content_file" id="content::prepare_content_file"><font size="+1" weight="bold">content::prepare_content_file</font></a></td></tr><tr><td>
<blockquote>Looks for an element named { content} in a form and
prepares a temporarily file in UTF-8 for uploading to the content
repository. Checks for a query variable named { content.tmpfile} to
distinguish between file uploads and text entry. If the type of the
file is text, then ensures that is in UTF-8. Does nothing if the
uploaded file is in binary format.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>form_name</code><font color="red">*</font>
</td><td align="left">The name of the form object in which content was
submitted.</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The path of the temporary file containing the content, or an
empty string if the form does not include a content element or the
value of the element is null.</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::set_attribute_values" id="content::set_attribute_values"><font size="+1" weight="bold">content::set_attribute_values</font></a></td></tr><tr><td>
<blockquote>Set the default values for attribute elements in ATS
form object based on a previous revision</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form_name</code><font color="red">*</font>
</td><td align="left">The name of the ATS form object containing the
attribute elements.</td>
</tr><tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The type of item being revised in the form.</td>
</tr><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The revision ID from where to get the default
values</td>
</tr><tr>
<td align="right">
<code>attributes</code><font color="red">*</font>
</td><td align="left">The list of attributes whose values should be
set.</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::set_content_value" id="content::set_content_value"><font size="+1" weight="bold">content::set_content_value</font></a></td></tr><tr><td>
<blockquote>Set the default value for the content text area in an
ATS form object based on a previous revision</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form_name</code><font color="red">*</font>
</td><td align="left">The name of the ATS form object containing the
content element.</td>
</tr><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The revision ID of the content to revise</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::string_to_file" id="content::string_to_file"><font size="+1" weight="bold">content::string_to_file</font></a></td></tr><tr><td>
<blockquote>Write a string in UTF-8 encoding to of temp file so it
can be uploaded into a BLOB (which is blind to character
encodings). Returns the name of the temp file.</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>s</code><font color="red">*</font>
</td><td align="left">The string to write to the file.</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::update_content_from_file" id="content::update_content_from_file"><font size="+1" weight="bold">content::update_content_from_file</font></a></td></tr><tr><td>
<blockquote>Update the BLOB column of a revision with the contents
of a file</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The object ID of the revision to update.</td>
</tr><tr>
<td align="right">
<code>tmpfile</code><font color="red">*</font>
</td><td align="left">The name of a temporary file containing the
content. The file is deleted following the update.</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="content::upload_content" id="content::upload_content"><font size="+1" weight="bold">content::upload_content</font></a></td></tr><tr><td>
<blockquote>Inserts content into the database from an uploaded
file. Does automatic mime_type updating Parses text/html content
and removes tags</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>db</code><font color="red">*</font>
</td><td align="left">A db handle</td>
</tr><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The revision to which the content belongs</td>
</tr><tr>
<td align="right">
<code>tmpfile</code><font color="red">*</font>
</td><td align="left">The server-side name of the file containing the
body of the revision to upload into the content BLOB column of
cr_revisions.</td>
</tr><tr>
<td align="right">
<code>filename</code><font color="red">*</font>
</td><td align="left">The client-side name of the file containing the
body of the revision to upload into the content BLOB column of
cr_revisions</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
