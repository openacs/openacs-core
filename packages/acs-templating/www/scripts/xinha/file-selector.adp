<html>
<head>
  <title>@HTML_Title@</title>
  <link rel="stylesheet" type="text/css" 
	href="/resources/acs-templating/lists.css" media="all">
  <link rel="stylesheet" type="text/css" 
	href="/resources/acs-templating/forms.css" media="all">  

  <script type="text/javascript">
function onOK() {
    if (document.forms.fs.linktarget) {
	var id = getRadioValue(document.forms.fs.linktarget);
	if (id == null) {
	    alert("@HTML_NothingSelected@");
	} else {
<if @selector_type@ eq "image">
	    opener.document.getElementById("f_url").value = document.getElementById(id + "_file_url").value;
	    opener.document.getElementById("f_name").value = document.getElementById(id +  "_file_name").value;
	    opener.document.getElementById("f_alt").value = document.getElementById(id +  "_file_title").value;
	    opener.onPreview();
</if>
<else>
	    opener.document.getElementById("f_href").value = document.getElementById(id + "_file_url").value;
	    opener.document.getElementById("f_title").value = document.getElementById(id +  "_file_title").value;
</else>
	    window.close();
	}
    } else {
	alert("@HTML_NothingSelected@");
    }
};


			
function onCancel() {
    window.close();
};
			
function getRadioValue (radioButtonOrGroup) {
    var value = null;
    if (radioButtonOrGroup.length) { // group 
	for (var b = 0; b < radioButtonOrGroup.length; b++)
	    if (radioButtonOrGroup[b].checked)
		value = radioButtonOrGroup[b].value;
    }
    else if (radioButtonOrGroup.checked)
	value = radioButtonOrGroup.value;
    return value;
}
function selectImage(OId, url, mime) {
    document.getElementById("oi" + OId).checked = true;
    onPreview(url, mime);
}
			
function onPreview(url,mime) {
    if (mime.match(/image\//)) {
        window.ipreview.location.replace(url);
    } else {
        window.ipreview.location.replace("./blank.html");
    }
    return false;
}

// in order window.focus() does not work here for IE. It is not the best
// solution, but for the time being, we simply skip it. 
function myFocus() {
  if (!window.ActiveXObject) { // no IE
    window.focus();
  }
}
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
table {font: 11px Tahoma,Verdana,sans-serif; }

form { padding: 0px; margin: 0px; }
form p { margin-top: 5px; margin-bottom: 5px;}

.fl { width: 9em; float: left; padding: 2px 5px; text-align: right; }
.fr { width: 6em; float: left; padding: 2px 5px; text-align: right; }
fieldset { padding: 0px 10px 5px 5px; }
select, input, button { font: 11px Tahoma,Verdana,sans-serif; }
.space { padding: 2px; }

.title { background: #ddf; color: #000; font-weight: bold; font-size: 120%; 
    padding: 3px 10px; margin-bottom: 10px;
    border-bottom: 1px solid black; letter-spacing: 2px;
}
</style>
		
</head>
<!-- <body onBlur="window.focus();"> -->
<body onBlur="myFocus();">
  <div class="title">@HTML_Title@</div>
  <div style="border-bottom:1px solid #000000;font-weight:bold;margin-bottom: 5px;">@HTML_Context@</div>

  <fieldset style="padding-top:10px;">
    <legend><strong>@HTML_Legend@</strong></legend>
    <if @up_url@ not nil>
      <div style="margin-bottom:3px;"><a href="@up_url@"><img 
        src="/resources/acs-templating/xinha-nightly/plugins/OacsFS/img/up.gif" 
        border="0"/> @up_name@</a></div>
    </if>		
    <div style="margin-left:10px;margin-bottom:3px;"><img src="/resources/file-storage/folder.gif"/> @folder_name@</div>
    <form action="" method="get" name="fs">
      <listtemplate name="contents"></listtemplate>
    </form>
  </fieldset>

  
  <table width="100%" style="margin-bottom: 0.2em">
    <tr>
      <td valign="bottom" align="center" width="50%" rowspan="2">
	<fieldset style="margin-top:10px;padding-top:10px;">
	  <legend><strong>@HTML_Preview@</strong></legend>
	  <iframe name="ipreview" id="ipreview" frameborder="0" style="width:95%;" height="150"  src="./blank.html"></iframe>
	</fieldset>
      </td>

      <td valign="top" width="50%" >
	<if @write_p;literal@ true>
	  <fieldset style="margin-top:10px;padding-top:10px;">
	    <legend><strong>@HTML_UploadTitle@</strong></legend>
	    <formtemplate id="upload_form">
	      <table cellspacing="2" cellpadding="2" border="0" width="55%">
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
		    </formerror>
      </td>
    </tr>
    <tr class="form-element">
      <td class="form-widget" colspan="2" align="center">
	<formwidget id="ok_btn">
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
    <div style="margin-top: 10px; text-align: right;">
      <button type="button" name="ok" onclick="return onOK();"> #acs-kernel.common_OK# </button>
      <button type="button" name="cancel" onclick="return onCancel();">#acs-templating.HTMLArea_action_cancel#</button>
    </div>						
  </td>
</tr>
</table>

</body>
</html>

