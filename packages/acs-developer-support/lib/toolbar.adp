<if @show_p@ true>
  <table cellspacing="0" cellpadding="0" width="100%" border="0" id="developer-toolbar">
    <tr>
      <td>
        <a href="@ds_url@">Developer Support</a>
      </td>

      <td class="action-list">
        <ul>
          <li><a href="@user_switching_toggle_url@" class="@user_switching_on@" title="User switching">USR</a></li>
          <li><a href="@db_toggle_url@" class="@db_on@" title="Database statistics">DB</a></li>
          <li><a href="@translator_toggle_url@" class="@translator_on@" title="Translator mode">TRN</a></li>
        </ul>
      </td>

      <td align="center" class="action-list">
        <ul>
          <li><a href="@request_info_url@" title="View request information">@request_info_label@</a>
          <span style="color: #cccccc;">|</span></li>
          <li><a href="@oacs_shell_url@" title="Execute commands and see the result">Shell</a>
          <span style="color: #cccccc;">|</span></li>
          <li><a href="/acs-admin/apm/" title="Modify/reload packages">APM</a>
          <span style="color: #cccccc;">|</span></li>
          <li><a href="/admin/site-map/" title="Manage your package instances">Site Map</a>
          <span style="color: #cccccc;">|</span></li>
          <li><a href="/acs-admin/apm/?reload_links_p=1" title="Scan for changed library files">Changed</a>
          <span style="color: #cccccc;">|</span></li>
          <li><a href="@flush_url@" title="Flush entire util_memoize cache">Flush</a>
          <span style="color: #cccccc;">|</span></li>
          <li><a href="@auto_test_url@" title="Automated Testing Home">Test</a>
          <span style="color: #cccccc;">|</span></li>
          <li><a href="/acs-admin/users/" title="Add/edit/become users">Users</a>
          <span style="color: #cccccc;">|</span></li>
          <li><a href="/acs-lang/admin/" title="Add/edit message keys">I18n</a>
          <span style="color: #cccccc;">|</span></li>
          <li><a href="/doc/" title="View system documentation">Docs</a>
          <span style="color: #cccccc;">|</span></li>
          <li><a href="/api-doc/" title="View/search OpenACS Tcl API documentation">API doc</a></li>
        </ul>
      </td>

      <form action="/api-doc/proc-search">
        <input type="hidden" name="search_type" value="All+matches">
        <input type="hidden" name="name_weight" value="5">
        <input type="hidden" name="param_weight" value="3">
        <input type="hidden" name="doc_weight" value="2">

        <td align="right" style="padding-right: 4px;" id="search">
          <input name="query_string" onfocus="if(this.value=='Search API')this.value='';" onblur="if(this.value=='')this.value='Search API';" value="Search API">
          <input type="submit" value="Go">
        </td>
      </form>
    </tr>
  </table>
</if>
