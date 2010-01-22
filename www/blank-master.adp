@doc_type;noquote@
<html>
  <head>
    <title>@title;noquote@</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8">
    <meta name="generator" content="OpenACS version @openacs_version@">
    <if @developer_support_p@ true>
      <link rel="stylesheet" type="text/css" href="/resources/acs-developer-support/acs-developer-support.css" media="all">
    </if>
    <multiple name="header_links">
      <link rel="@header_links.rel@" type="@header_links.type@" href="@header_links.href@" media="@header_links.media@">
    </multiple>

    <if @acs_blank_master.xinha@ not nil>
      <if @htmlarea_support:rowcount@ ne 0>
       <script type="text/javascript">
        _editor_url  = "@xinha_dir@"  // (preferably absolute)URL (including trailing slash) where Xinha is installed   
        _editor_lang = "@lang@";
       </script>
       <script type="text/javascript" src="@xinha_dir@htmlarea.js" language="javascript"></script>
      </if>
    </if>

    <if @acs_blank_master.rte@ not nil>
      <if @acs_blank_master__htmlareas@ not nil>
        <script language="JavaScript" type="text/javascript" 
             src="/resources/acs-templating/rte/richtext.js">
         </script>
      </if>
    </if>

    <script type="text/javascript" src="/resources/acs-subsite/core.js" language="javascript"></script>

    @header_stuff;noquote@
  </head>
  <body<multiple name="attribute"> @attribute.key@="@attribute.value@"</multiple>>
  <textarea id="holdtext" style="display: none;" rows="1" cols="1"></textarea>

    <if @dotlrn_toolbar_p@ true>
      <include src="/packages/dotlrn/lib/toolbar">
    </if>
    <if @developer_support_p@ true>
      <include src="/packages/acs-developer-support/lib/toolbar">
    </if>

    <if @acs_blank_master.rte@ not nil>
     <if @acs_blank_master__htmlareas@ not nil>
       <script language="JavaScript" type="text/javascript"><!--
           initRTE("/resources/acs-templating/rte/images/", "/resources/acs-templating/rte/", "/resources/acs-templating/rte/rte.css");
      // -->
       </script>
     </if>
  </if>

  <if @acs_blank_master.xinha@ not nil>
    <if @htmlarea_support:rowcount@ ne 0>
      <script type="text/javascript">
	xinha_editors = null;
	xinha_init = null;
	xinha_config = null;
	xinha_plugins = null;
	xinha_init = xinha_init ? xinha_init : function()
	{
	xinha_plugins = xinha_plugins ? xinha_plugins :
	[@xinha_plugins@];
	// THIS BIT OF JAVASCRIPT LOADS THE PLUGINS, NO TOUCHING  :)
	if(!HTMLArea.loadPlugins(xinha_plugins, xinha_init)) return;
	xinha_editors = xinha_editors ? xinha_editors :
	[
           <multiple name="htmlarea_support" delimiter=",">
             '@htmlarea_support.id@'
           </multiple>
	];
       xinha_config = xinha_config ? xinha_config() : new HTMLArea.Config();
       @xinha_params@
       @xinha_options@
        xinha_editors = HTMLArea.makeEditors(xinha_editors, xinha_config, xinha_plugins);
       HTMLArea.startEditors(xinha_editors);
    }
    window.onload = xinha_init;
    </script>
   </if>
  </if>

    <slave>

    <if @developer_support_p@ true>
      <include src="/packages/acs-developer-support/lib/footer">
    </if>
    <if @translator_mode_p@ true>
      <include src="/packages/acs-lang/lib/messages-to-translate">
    </if>
  </body>
</html>
