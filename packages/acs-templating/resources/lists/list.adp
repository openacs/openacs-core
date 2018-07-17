<div class="@list_properties.class@">
<noparse>
  <if \@@list_properties.multirow@:rowcount@ eq 0>
</noparse>
    @list_properties.no_data@
<noparse>
  </if>
  <else>
</noparse>
  <if @bulk_actions:rowcount;literal@ gt 0>
  <if @list_properties.bulk_action_method@ not nil>
  <form name="@list_properties.name@" method="@list_properties.bulk_action_method@">
  </if>
  <else>
  <form name="@list_properties.name@" method="GET">
  </else>
    <noparse>
    @list_properties.bulk_action_export_chunk;noquote@
    </noparse>
  </if>

  <if @actions:rowcount;literal@ gt 0>
    <div class="list-button-bar">
      <multiple name="actions">
        <span class="list-button-header"><a href="@actions.url@" class="list-button" title="@actions.title@">@actions.label@</a></span>
      </multiple>
    </div>
  </if>

    <noparse>
      <multiple name="@list_properties.multirow@">
      <if \@@list_properties.multirow@.rownum@ odd>
         <div class="list-row odd">
      </if><else>
         <div class="list-row even">
      </else>
    </noparse>

        <listrow>
      </div>

    <noparse>
      </multiple>
    </noparse>

  <if @bulk_actions:rowcount;literal@ gt 0>
    <div class="list-button-bar">
      <multiple name="bulk_actions">
	<% template::add_event_listener -id "$list_properties(name)-bulk_action-$bulk_actions(rownum)" -script [subst {
	    $list_properties(bulk_action_click_function)('$list_properties(name)', '$bulk_actions(url)');
	}] %>
        <span class="list-button-header"><a href="#" class="list-button" title="@bulk_actions.title@"
	id="@list_properties.name;literal@-bulk_action-@bulk_actions.rownum;literal@">@bulk_actions.label@</a></span>
      </multiple>
    </div>
    </form>
  </if>



<noparse>
  </else>
</noparse>
</div>
