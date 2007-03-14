<html>
<head>
  <title>#acs-templating.HTMLArea_InsertLink#</title>

  <script type="text/javascript" 
	  src="/resources/acs-templating/xinha-nightly/popups/popup.js">
  </script>


<script type="text/javascript">
	var selector_window;
	window.resizeTo(450, 300);

	function Init() {
	  __dlg_init();

	  var f_href = document.getElementById("f_href");
	  var url = f_href.value;
	  if (url) {
      		onOK();
	      	__dlg_close(null);
	  }

	  var param = window.dialogArguments;
	  if (param) {
 	     if ( typeof param["f_href"] != "undefined" ) {
	        document.getElementById("f_href").value = param["f_href"];
	        document.getElementById("f_url").value = param["f_href"];
	        document.getElementById("f_title").value = param["f_title"];
	     }          
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
	.form-error { color : red}
</style>

</head>

<body onload="Init()">
	<table border="0" width="100%" style="margin: 0 auto; text-align: left;padding: 0px;">
	  <tbody>
      <td valign="top">
	<if @write_p@ eq 1>
	    <formtemplate id="upload_form">
	<formwidget id="f_href">
			<input type="hidden" id="f_target"/>
			<input type="hidden" id="f_usetarget"/>
			<table cellspacing="2" cellpadding="2" border="0" width="100%">
					<tr class="form-group">
				<if @formerror.upload_file@ not nil>
					<td class="form-widget-error">
				</if>
	          	<else>
		    		<td class="form-widget">
				</else> 	
					<fieldset>
						<legend>#acs-templating.Link_Title#</legend>
						<formwidget id="f_title">
		    				<formerror id="f_title">
		      				<div class="form-error">@formerror.f_title@</div>
		    			</formerror>
					</fieldset>
					You can link to the above text to a URL or a file. Select one of the options below.<br /><br />
					<fieldset>
						<legend>Link to a URL</legend>
						<formwidget id="f_url">
		    				<formerror id="f_url">
		      				<div class="form-error">@formerror.f_url@</div>
		    			</formerror>
		    			<br /><formwidget id="url_ok_btn">&nbsp;<button type="button" name="cancel" onclick="return onCancel();">#acs-templating.HTMLArea_action_cancel#</button>
					</fieldset>
					<if @recent_files_options@ ne "">
					<fieldset>
	        			<legend>#acs-templating.Choose_File#</legend>
						<formgroup id="choose_file">
							<if @formgroup.rownum@ odd and @formgroup.rownum@ gt 1><br /></if>
								@formgroup.widget;noquote@ @formgroup.label;noquote@
							</formgroup>
		    				<formerror id="choose_file">
		      					<div class="form-error">@formerror.choose_file@</div>
		    				</formerror>
						<br /><formwidget id="select_btn">&nbsp;<button type="button" name="cancel" onclick="return onCancel();">#acs-templating.HTMLArea_action_cancel#</button>
					</fieldset>
					</if>
					</td>
				</tr> 
		<tr class="form-element">
		  <if @formerror.f_title@ not nil>
		    <td class="form-widget-error">
		  </if>
		  <else>
		    <td class="form-widget">
		  </else>
	<fieldset>
	<legend>#acs-templating.Upload_a_New_File#</legend>                  
		<br />

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
                  		    <br />
		    <formerror id="share">
		      <div class="form-error">@formerror.share@</div>
		    </formerror>                        
	<formwidget id="ok_btn">&nbsp;<button type="button"
	name="cancel" onclick="return onCancel();">#acs-templating.HTMLArea_action_cancel#</button>
          </fieldset>
      </td>
    </tr>
    </table>
    </formtemplate>
    </fieldset>
    </if>
	</td>
	</tr>
	</tbody>
	</table>
</body>
</html>
