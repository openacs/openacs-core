<form action="@perm_modify_url@" method="post">
  @perm_form_export_vars;noquote@
  <listtemplate name="permissions"></listtemplate>
  <p>
    <input type="submit" value="#acs-subsite.Confirm_Permissions#" class="btn btn-outline-secondary text-decoration-none">
  </p>
</form>

