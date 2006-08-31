<html style="width: 400px; height: 260px">
<head>
  <title>#acs-templating.HTMLArea_InsertFileTitle#</title>

  <script type="text/javascript" 
	  src="/resources/acs-templating/xinha-nightly/popups/popup.js">
  </script>


<script type="text/javascript">
	var selector_window;
	window.resizeTo(415, 300);

	function Init() {
	  __dlg_init();
	  var param = window.dialogArguments;
	  var f_href = document.getElementById("f_href");
	  var url = f_href.value;
	  if (url) {
      		onOK();
	      	__dlg_close(null);
	  }
	};
	
	function onOK() {
	  var required = {
	    "f_href": "#acs-templating.HTMLArea_NoURL#"
	  };
	  for (var i in required) {
	    var el = document.getElementById(i);
	    if (!el.value) {
	      alert(required[i]);
	      el.focus();
	      return false;
	    }
	  }
	  // pass data back to the calling window
	  var fields = ["f_href","f_title", "f_target"];
	  var param = new Object();
	  for (var i in fields) {
	    var id = fields[i];
	    var el = document.getElementById(id);
	    param[id] = el.value;
	    alert(id + "='" + el.value + "'");
	  }
	  __dlg_close(param);
	  return false;
	};
	
	function onCancel() {
	  if (selector_window) {
	    selector_window.close();
	  }
	  __dlg_close(null);
	  return false;
	};

</script>

<style type="text/css">
	html, body {
	  background: ButtonFace;
	  color: ButtonText;
	  font: 11px Tahoma,Verdana,sans-serif;
	  margin: 0px;
	  padding: 0px;
	}
	body { padding: 5px; }
	table {
	  font: 11px Tahoma,Verdana,sans-serif;
	}
	form p {
	  margin-top: 5px;
	  margin-bottom: 5px;
	}
	.fl { width: 9em; float: left; padding: 2px 5px; text-align: right; }
	.fr { width: 6em; float: left; padding: 2px 5px; text-align: right; }
	fieldset { padding: 0px 10px 5px 5px; }
	select, input, button { font: 11px Tahoma,Verdana,sans-serif; }
	.space { padding: 2px; }
	
	.title { background: #ddf; color: #000; font-weight: bold; font-size: 120%; padding: 3px 10px; margin-bottom: 10px;
	border-bottom: 1px solid black; letter-spacing: 2px;
	}
	form { padding: 0px; margin: 0px; }
</style>

</head>

<body onload="Init()">

	<table border="0" width="100%" style="margin: 0 auto; text-align: left;padding: 0px;">
	  <tbody>
      <td valign="top" width="50%" >
	<if @write_p@ eq 1>
	  <fieldset style="margin-top:10px;padding-top:10px;">
	    <legend><b>@HTML_UploadTitle@</b></legend>
	    <formtemplate id="upload_form">
<input type="hidden" name="f_href" id="f_href" value="@f_href@" />
<input type="hidden" id="f_target"/>
<input type="hidden" id="f_usetarget"/>

	      <table cellspacing="2" cellpadding="2" border="0" width="55%">
		<tr class="form-element">
		  <if @formerror.f_title@ not nil>
		    <td class="form-widget-error">
		  </if>
		  <else>
		    <td class="form-widget">
		  </else>
		#acs-templating.Link_Title#<br />
		  <formwidget id="f_title">
		    <formerror id="f_title">
		      <div class="form-error">@formerror.f_title@</div>
		    </formerror><br />
	</td></tr>
		<tr class="form-element">
		  <if @formerror.upload_file@ not nil>
		    <td class="form-widget-error">
		  </if>
		  <else>
		    <td class="form-widget">
		  </else>
		  <formwidget id="upload_file">
		    <formerror id="upload_file">
		      <div class="form-error">@formerror.upload_file@</div>
		    </formerror><br />
                        #acs-templating.This_file_can_be_reused_by#<br />
                        <formgroup id="share">
                          @formgroup.widget;noquote@ @formgroup.label@
		    <br /></formgroup>
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  #acs-templating.This_file_can_be_reused_help#
		    <formerror id="share">
		      <div class="form-error">@formerror.share@</div>
		    </formerror>                        
      </td>
    </tr>
    <tr class="form-element">
      <td class="form-widget" colspan="2" align="center">
	<formwidget id="ok_btn">&nbsp;<button type="button" name="cancel" onclick="return onCancel();">#acs-templating.HTMLArea_action_cancel#</button>        
      </td>
    </tr>
    </table>
    </formtemplate>
    </fieldset>
    </if>
	</td>
	</tr>
	<tr>
	<td>
	</td>
	</tr>
	  </tbody>
	</table>

</body>
</html>
