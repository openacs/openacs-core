
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Tag Reference: formerror}</property>
<property name="doc(title)">Templating System Tag Reference: formerror</property>
<master>
<h2>formerror</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : formerror
<h3>Summary</h3>
<p>The <kbd>formerror</kbd> tag is used to specify the presentation
of a form validation error.</p>
<h3>Usage</h3>
<pre>
  &lt;formtemplate id="add_user"&gt;
  &lt;table&gt;
  &lt;tr&gt;
    &lt;td&gt;First Name&lt;/td&gt;
    &lt;td&gt;
      &lt;formwidget id="first_name"&gt;
      &lt;formerror id="first_name" type="no_special_characters"&gt;
      The first name may not not contain special characters such as 
      \@, $, !, %, &amp; or #.
      &lt;/formerror&gt;
    &lt;/td&gt;
  &lt;/tr&gt;
  &lt;/table&gt;&lt;br&gt;
  &lt;input type="submit" value="Submit"&gt;
  &lt;/formtemplate&gt;
</pre>
<p>Another example:</p>
<pre>
  &lt;formtemplate id="add_user"&gt;
  &lt;table&gt;
  &lt;tr&gt;
    &lt;td&gt;First Name&lt;/td&gt;
    &lt;td&gt;
      &lt;formwidget id="first_name"&gt;
    &lt;/td&gt;
  &lt;/tr&gt;
  &lt;formerror id="first_name"&gt;
  &lt;tr&gt;
    &lt;td colspan="2"&gt;&lt;font color="red"&gt;\@formerror.first_name\@&lt;/font&gt;&lt;/td&gt;
  &lt;/tr&gt;
  &lt;/formerror&gt;
  &lt;/table&gt;&lt;br&gt;
  &lt;input type="submit" value="Submit"&gt;
  &lt;/formtemplate&gt;
</pre>
<p>This adds another table row which contains the error message for
that widget in red color. If there is no error then the table row
will not be added.</p>
<h3>Notes</h3>
<ul>
<li><p>The contents of the <kbd>formerror</kbd> tag may appear on the
form when a submission is returned to the user for correction.</p></li><li><p>The contents of the tag may use the special variables
<kbd>label</kbd> and <kbd>value</kbd> to refer to the element label
and submitted value.</p></li><li><p>You can use the variable \@formerror.element_id\@ to refer to the
automatically generated error message within the formerror
tags.</p></li><li><p>The <kbd>type</kbd> attribute is optional and is used to
distinguish messages for specific types of validation errors. Each
element may have any number of error messages associated with it,
corresponding to each of the validation checks performed by the
developer in the script associated with template.</p></li><li><p>If the contents of the tag are empty
(&lt;formerror&gt;&lt;/formerror&gt;), the message specified by the
developer in the script are inserted when appropriate. This is
particularly useful for international sites, where locale-dependent
messages may be stored in the database.</p></li><li><p>If the <kbd>type</kbd> attribute is not specified <em>and</em>
the contents of the tag are empty, all appropriate messages are
inserted (separated by &lt;,br&gt; tags).</p></li><li><p>See the <a href="formwidget"><kbd>formwidget</kbd></a> and
<a href="formgroup"><kbd>formgroup</kbd></a> tags for more
information on writing the body of a dynamic form template.</p></li>
</ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->