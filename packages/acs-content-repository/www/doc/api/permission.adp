
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Package: content_permission}</property>
<property name="doc(title)">Package: content_permission</property>
<master>
<h2>content_permission</h2>
<p>
<a href="../index">Content Repository</a> :
content_permission</p>
<hr>
<ul>
<li><a href="#overview">Overview</a></li><li><a href="#related">Related Objects</a></li><li><a href="#api">API</a></li>
</ul>
<p> </p>
<a name="overview" id="overview"><h3>Overview</h3></a>
<p>Permissions can be set to allow certain users certain things. -
They can be compared with the Unix filesystem permission: read,
write ...</p>
<p> </p>
<a name="related" id="related"><h3>Related Objects</h3></a>
 See also: {content_item }
<p> </p>
<a name="api" id="api"><h3>API</h3></a>
<ul>
<li>
<font size="+1">Function:</font>
content_permission.has_grant_authority
<p>Determine if the user may grant a certain permission to another
user. The permission may only be granted if the user has the
permission himself and possesses the cm_perm access, or if the user
possesses the cm_perm_admin access.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the donation is possible,
'f' otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">object_id:</th><td>  </td><td>The object whose permissions are to be changed</td>
</tr><tr>
<th align="right" valign="top">holder_id:</th><td>  </td><td>The person who is attempting to grant the permissions</td>
</tr><tr>
<th align="right" valign="top">privilege:</th><td>  </td><td>The privilege to be granted</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
  function has_grant_authority (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_permission.grant_permission,
content_permission.is_has_revoke_authority,
acs_permission.grant_permission</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font>
content_permission.has_revoke_authority
<p>Determine if the user may take a certain permission away from
another user. The permission may only be revoked if the user has
the permission himself and possesses the cm_perm access, while the
other user does not, or if the user possesses the cm_perm_admin
access.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if it is possible to revoke the
privilege, 'f' otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">object_id:</th><td>  </td><td>The object whose permissions are to be changed</td>
</tr><tr>
<th align="right" valign="top">holder_id:</th><td>  </td><td>The person who is attempting to revoke the permissions</td>
</tr><tr>
<th align="right" valign="top">privilege:</th><td>  </td><td>The privilege to be revoked</td>
</tr><tr>
<th align="right" valign="top">revokee_id:</th><td>  </td><td>The user from whom the privilege is to be taken away</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
  function has_revoke_authority (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE
  ) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_permission.has_grant_authority,
content_permission.revoke_permission,
acs_permission.revoke_permission</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font>
content_permission.permission_p
<p>Determine if the user has the specified permission on the
specified object. Does NOT check objects recursively: that is, if
the user has the permission on the parent object, he does not
automatically gain the permission on all the child objects.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the user has the specified
permission on the object, 'f' otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">object_id:</th><td>  </td><td>The object whose permissions are to be checked</td>
</tr><tr>
<th align="right" valign="top">holder_id:</th><td>  </td><td>The person whose permissions are to be examined</td>
</tr><tr>
<th align="right" valign="top">privilege:</th><td>  </td><td>The privilege to be checked</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
  function permission_p (
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_permission.grant_permission,
content_permission.revoke_permission,
acs_permission.permission_p</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_permission.grant_permission
<p>This is a helper function for
content_permission.grant_permission and should not be called
individually.</p><p>Grants a permission and revokes all descendants of the
permission, since they are no longer relevant.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">object_id:</th><td>  </td><td>The object whose permissions are to be changed</td>
</tr><tr>
<th align="right" valign="top">grantee_id:</th><td>  </td><td>The person who should gain the parent privilege</td>
</tr><tr>
<th align="right" valign="top">privilege:</th><td>  </td><td>The parent privilege to be granted</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
  procedure grant_permission_h (
    object_id         in acs_objects.object_id%TYPE,
    grantee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  );

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_permission.grant_permission</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_permission.grant_permission_h
<p>This is a helper function for
content_permission.grant_permission and should not be called
individually.</p><p>Grants a permission and revokes all descendants of the
permission, since they are no longer relevant.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">object_id:</th><td>  </td><td>The object whose permissions are to be changed</td>
</tr><tr>
<th align="right" valign="top">grantee_id:</th><td>  </td><td>The person who should gain the parent privilege</td>
</tr><tr>
<th align="right" valign="top">privilege:</th><td>  </td><td>The parent privilege to be granted</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
  procedure grant_permission_h (
    object_id         in acs_objects.object_id%TYPE,
    grantee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  );

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_permission.grant_permission</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_permission.inherit_permissions
<p>Make the child object inherit all of the permissions of the
parent object. Typically, this function is called whenever a new
object is created under a given parent</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">parent_object_id:</th><td>  </td><td>The parent object id</td>
</tr><tr>
<th align="right" valign="top">child_object_id:</th><td>  </td><td>The child object id</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
  procedure inherit_permissions (
    parent_object_id  in acs_objects.object_id%TYPE,
    child_object_id   in acs_objects.object_id%TYPE,
    child_creator_id  in parties.party_id%TYPE default null
  );

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_permission.grant, acs_permission.grant_permission</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_permission.revoke_permission
<p>This is a helper function for
content_permission.revoke_permission and should not be called
individually.</p><p>Revokes a permission but grants all child permissions to the
holder, to ensure that the permission is not permanently lost</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">object_id:</th><td>  </td><td>The object whose permissions are to be changed</td>
</tr><tr>
<th align="right" valign="top">revokee_id:</th><td>  </td><td>The person who should lose the parent permission</td>
</tr><tr>
<th align="right" valign="top">privilege:</th><td>  </td><td>The parent privilege to be revoked</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
  procedure revoke_permission_h (
    object_id         in acs_objects.object_id%TYPE,
    revokee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  );

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_permission.revoke_permission</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_permission.revoke_permission_h
<p>This is a helper function for
content_permission.revoke_permission and should not be called
individually.</p><p>Revokes a permission but grants all child permissions to the
holder, to ensure that the permission is not permanently lost</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">object_id:</th><td>  </td><td>The object whose permissions are to be changed</td>
</tr><tr>
<th align="right" valign="top">revokee_id:</th><td>  </td><td>The person who should lose the parent permission</td>
</tr><tr>
<th align="right" valign="top">privilege:</th><td>  </td><td>The parent privilege to be revoked</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
  procedure revoke_permission_h (
    object_id         in acs_objects.object_id%TYPE,
    revokee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  );

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_permission.revoke_permission</td>
</tr>
</table>
</li>
</ul>
<p> </p>

Last Modified: $&zwnj;Id: permission.html,v 1.2 2017/08/07 23:47:47
gustafn Exp $
