
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Namespace cms_rel</h2>
<blockquote>Procedures for managing relation items and child
items</blockquote>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>
<a href="#cms_rel::sort_child_item_order">cms_rel::sort_child_item_order</a><br><a href="#cms_rel::sort_related_item_order">cms_rel::sort_related_item_order</a><br>
</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<strong>Public Methods:</strong>
<br>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="cms_rel::sort_child_item_order" id="cms_rel::sort_child_item_order"><font size="+1" weight="bold">cms_rel::sort_child_item_order</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Resort the child items order for a given content item,
ensuring that order_n is unique for an item_id. Chooses new order
based on the old order_n and then rel_id (the order the item was
related)</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item for which to resort child items</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="cms_rel::sort_related_item_order" id="cms_rel::sort_related_item_order"><font size="+1" weight="bold">cms_rel::sort_related_item_order</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Resort the related items order for a given content
item, ensuring that order_n is unique for an item_id. Chooses new
order based on the old order_n and then rel_id (the order the item
was related)</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item for which to resort related items</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
