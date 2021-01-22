<if @show_p@ true>
  <table width="100%" id="developer-toolbar">
    <tr align="center">
      <td>
        <a href="@ds_url@" title="@ip_address@">Developer&nbsp;Support</a>
      </td>

      <td class="actions">
        <ul>
          <multiple name="ds_buttons">
            <li><a id="ACS_DS_@ds_buttons.label@" href="@ds_buttons.toggle_url@" class="@ds_buttons.state@" title="@ds_buttons.title@">@ds_buttons.label@</a></li>
          </multiple>
        </ul>
      </td>

      <td align="center" class="actions">
        <ul>
          <li><a href="@request_info_url@" title="View request information">@request_info_label@</a>
          <span>|</span></li>
          <li><a href="@oacs_shell_url@" title="Execute commands and see the result">Shell</a>
          <span>|</span></li>
          <li><a href="/acs-admin/apm/" title="Modify/reload packages">APM</a>
          <span>|</span></li>
          <li><a href="/admin/site-map/?root_id=@this_side_node@" title="Configure current package via Site Map">Site&nbsp;Map</a>
          <span>|</span></li>
          <li><a href="/acs-admin/apm/?reload_links_p=1" title="Scan for changed library files">Changed</a>
          <span>|</span></li>
          <li><a href="@flush_url@" title="Flush entire util_memoize cache">Flush</a>
          <span>|</span></li>
          <li><a href="@auto_test_url@" title="Automated Testing Home">Test</a>
          <span>|</span></li>
          <li><a href="/acs-admin/users/" title="Add/edit/become users">Users</a>
          <span>|</span></li>
          <li><a href="/acs-lang/admin/" title="Add/edit message keys">I18n</a>
          <span>|</span></li>
          <li><a href="/doc/" title="View system documentation">Docs</a>
          <span>|</span></li>
          <li><a href="/api-doc/" title="View/search OpenACS Tcl API documentation">API&nbsp;doc</a></li>
          <if @xocore_url@ ne ""><span>|</span>
           <li><a href="@xocore_url@" title="XoTcl Documentation Browser">XoTcl</a></li>
          </if>
          <if @rm_url@ ne ""><span>|</span>
           <li><a href="@rm_url@" title="View requests in the request monitor">Requests</a></li>
	  </if><else>
           </li>
          </else>
        </ul>
      </td>

      <td align="right" id="developer-search">
        <form action="/api-doc/proc-search">
	  <div><input type="hidden" name="search_type" value="All+matches">
          <input type="hidden" name="name_weight" value="5">
          <input type="hidden" name="param_weight" value="3">
          <input type="hidden" name="doc_weight" value="2">
          <input name="query_string" placeholder="Search API">
          <input type="submit" value="Go"></div>
        </form>
      </td>
    </tr>
  </table>
</if>
