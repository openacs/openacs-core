<if @show_p@ true>
  <table cellspacing="0" cellpadding="0" width="100%" class="developer-toolbar" border="0">
    <tr>
      <td style="padding-left: 8px;" >
        <a href="@ds_url@">Developer Support</a>

        <a href="@comments_toggle_url@" class="@comments_on@" title="Comments at page footer">CMT</a>
        
        <a href="@user_switching_toggle_url@" class="@user_switching_on@" title="User switching">USR</a>
        
        <a href="@db_toggle_url@" class="@db_on@" title="Database statistics">DB</a>
        
        <a href="@translator_toggle_url@" class="@translator_on@" title="Translator mode">TRN</a>
        
      </td>

      <td align="center">
        <a href="@request_info_url@" title="View request information">@request_info_label@</a>
        |
        <a href="@oacs_shell_url@" title="Execute commands and see the result">Shell</a>
        |
        <a href="/acs-admin/apm/" title="Modify/reload packages">APM</a>
        |
        <a href="/acs-admin/apm/?reload_links_p=1" title="Scan for changed library files">Changed files</a>
        |
        <a href="/acs-admin/users/" title="Add/edit/become users">Users</a>
        |
        <a href="/acs-lang/admin/" title="Add/edit message keys">I18n</a>
        |
        <a href="/doc/" title="View system documentation">Docs</a>
        |
        <a href="/api-doc/" title="View/search OpenACS Tcl API documentation">API doc</a>
      </td>

      <form action="/api-doc/proc-search">
        <input type="hidden" name="search_type" value="All+matches">
        <input type="hidden" name="name_weight" value="5">
        <input type="hidden" name="param_weight" value="3">
        <input type="hidden" name="doc_weight" value="2">

        <td align="right" style="padding-right: 8px;" id="search">
          <input name="query_string" onfocus="if(this.value=='Search API')this.value='';" onblur="if(this.value=='')this.value='Search API';" value="Search API">
          <input type="submit" value="Go">
        </td>
      </form>
    </tr>
  </table>
</if>
