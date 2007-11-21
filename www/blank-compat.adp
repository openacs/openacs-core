<master src="/www/blank-master">
<if @meta:rowcount@ not nil><property name="&meta">meta</property></if>
<if @link:rowcount@ not nil><property name="&link">link</property></if>
<if @script:rowcount@ not nil><property name="&script">script</property></if>
<if @doc@ defined><property name="&doc">doc</property></if>
<if @body@ defined><property name="&body">body</property></if>
<if @head@ not nil><property name="head">@head;noquote@</property></if>

<if @acs_blank_master.rte@ not nil and @acs_blank_master__htmlareas@ not nil>
<script type="text/javascript">
<!--
    initRTE("/resources/acs-templating/rte/images/", 
            "/resources/acs-templating/rte/", 
            "/resources/acs-templating/rte/rte.css");
// -->
</script>
</if>

<if @acs_blank_master.xinha@ not nil and @acs_blank_master__htmlareas@ not nil>
<script type="text/javascript">
<!--
  xinha_editors = null;
  xinha_init = null;
  xinha_config = null;
  xinha_plugins = null;
  xinha_init = xinha_init ? xinha_init : function() {
    xinha_plugins = xinha_plugins ? xinha_plugins : [@xinha_plugins;noquote@];
    // THIS BIT OF JAVASCRIPT LOADS THE PLUGINS, NO TOUCHING  :)
    if(!HTMLArea.loadPlugins(xinha_plugins, xinha_init)) return;
      xinha_editors = xinha_editors ? xinha_editors :
        [
        @htmlarea_ids@
        ];
      xinha_config = xinha_config ? xinha_config() : new HTMLArea.Config();
      @xinha_params;noquote@
      @xinha_options;noquote@
      xinha_editors = 
        HTMLArea.makeEditors(xinha_editors, xinha_config, xinha_plugins);
      HTMLArea.startEditors(xinha_editors);
  }
  window.onload = xinha_init;
// -->
</script>
</if>

<if @acs_blank_master__htmlareas@ not nil><textarea id="holdtext" style="display: none;" rows="1" cols="1"></textarea></if>

<slave />
