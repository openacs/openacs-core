
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Content Repository: Object Model}</property>
<property name="doc(title)">Content Repository: Object Model</property>
<master>
<h2>Object Model</h2>
<strong><a href="index">Content Repository</a></strong>
<p>The content repository is an extension of the ACS Object Model.
The following diagram illustrates the relationship among the
standard object types defined by the content repository (click on a
box to view a description and API summary for a particular object
type):</p>
<img name="objectmodel" src="object-model.gif" width="500" height="400" border="0" usemap="#m_object_model" id="objectmodel">
<map name="m_object_model" id="m_object_model">
<area shape="rect" coords="191,45,287,90" href="api/keyword.html"><area shape="rect" coords="39,224,135,269" href="/doc/object-system-design"><area shape="rect" coords="345,306,440,364" href="api/type.html"><area shape="rect" coords="191,123,287,168" href="api/item.html"><area shape="rect" coords="191,313,287,358" href="api/revision.html"><area shape="rect" coords="343,25,439,70" href="api/folder.html"><area shape="rect" coords="345,89,441,134" href="api/template.html"><area shape="rect" coords="344,154,440,199" href="api/symlink.html"><area shape="rect" coords="345,221,441,266" href="api/extlink.html">
</map>
<p>Note that content revisions and content items inherit separately
from the root of the object model. Each item may be related to one
or more revisions, but they are fundamentally different types of
objects.</p>
<p>Also important to note is the relationship between custom
content types and the rest of the object model. You define new
content types as subtypes of Content Revision, not of Content Item.
This is because new content types are characterized by their
attributes, which are stored at the revision level to make changes
easy to audit. Custom content types typically do not require
additional unaudited attributes or methods beyond those already
provided by the Content Item type. It is thereful almost never
necessary to create a custom subtype of Content Item itself.</p>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last revised: $&zwnj;Id: object-model.html,v 1.3 2017/09/17 08:49:17
gustafn Exp $
