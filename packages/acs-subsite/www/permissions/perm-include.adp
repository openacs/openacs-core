<form action="@perm_modify_url@" method="post">
  @perm_form_export_vars;noquote@
  <listtemplate name="permissions"></listtemplate>
  <p>
    <input type="submit" value="#acs-subsite.Confirm_Permissions#" class="btn btn-outline-secondary text-decoration-none">
  </p>
  <if @::__csrf_token@ defined>
    <input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@">
  </if>
</form>
