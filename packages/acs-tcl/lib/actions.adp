  <if @actions:rowcount@ gt 0>
  <dl>
    <multiple name="actions">
      <if @actions.type@ eq "SECTION">
        <if @actions.title_text@ not nil><h3>@actions.title_text@</h3></if>
        <if @actions.long_text@ not nil>@actions.long_text;noquote@</if>
      </if>
      <else>
        <dt><a href="@actions.url_stub@" title="@actions.title_text@">@actions.text@</a></dt>
        <if @actions.long_text@ not nil><dd>@actions.long_text;noquote@</dd></if>
      </else>
    </multiple>
  </dl>
  </if>

