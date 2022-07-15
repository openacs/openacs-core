<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>
  <div style="float: right;">
    <formtemplate id="locale_form">
      @form_vars;noquote@
      <table cellspacing="2" cellpadding="2" border="0">
        <tr class="form-element"><td class="form-label">Language</td>
        <td class="form-widget"><formwidget id="locale"></td></tr>
        <tr class="form-element">
        <td align="left" colspan="2"><formwidget id="formbutton:ok"></td></tr>
      </table>
    </formtemplate>
  </div>

<p>
  Show: 
  <multiple name="show_opts">
    <if @show_opts.rownum@ gt 1> | </if>
    <if @show_opts.selected_p;literal@ true><strong>@show_opts.label@ (@show_opts.count@)</strong> </if>
    <else><a href="@show_opts.url@">@show_opts.label@ (@show_opts.count@)</a> </else>
  </multiple>
</p>

<include src="/packages/acs-lang/lib/conflict-link" locale="@current_locale;literal@" package_key="@package_key;literal@">

<listtemplate name="messages"></listtemplate>
