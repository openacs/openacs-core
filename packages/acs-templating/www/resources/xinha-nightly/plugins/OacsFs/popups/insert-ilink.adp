<html>
<head>
  <title>#acs-templating.HTMLArea_InsertModifyLink#</title>

  <script type="text/javascript" 
          src="/resources/acs-templating/xinha-nightly/popups/popup.js">
  </script>


<script type="text/javascript">
  window.resizeTo(500, 200);

HTMLArea = window.opener.HTMLArea;

function i18n(str) {
  return (HTMLArea._lc(str, 'HTMLArea'));
};

function onTargetChanged() {
  var f = document.getElementById("f_other_target");
  if (this.value == "_other") {
    f.style.visibility = "visible";
    f.select();
    f.focus();
  } else f.style.visibility = "hidden";
};

function Init() {
  __dlg_translate('HTMLArea');
  __dlg_init();

  // Make sure the translated string appears in the drop down. (for gecko)
  document.getElementById("f_target").selectedIndex = 1;
  document.getElementById("f_target").selectedIndex = 0;

  var param = window.dialogArguments;
  var target_select = document.getElementById("f_target");
  var use_target = true;
  if (param) {
    if ( typeof param["f_usetarget"] != "undefined" ) {
      use_target = param["f_usetarget"];
    }
    if ( typeof param["f_href"] != "undefined" ) {
      document.getElementById("f_href").value = param["f_href"];
      document.getElementById("f_title").value = param["f_title"];
      comboSelectValue(target_select, param["f_target"]);
      if (target_select.value != param.f_target) {
        var opt = document.createElement("option");
        opt.value = param.f_target;
        opt.innerHTML = opt.value;
        target_select.appendChild(opt);
        opt.selected = true;
      }
    }
  }
  if (! use_target) {
    document.getElementById("f_target_label").style.visibility = "hidden";
    document.getElementById("f_target").style.visibility = "hidden";
    document.getElementById("f_other_target").style.visibility = "hidden";
  }
  var opt = document.createElement("option");
  opt.value = "_other";
  opt.innerHTML = i18n("Other");
  target_select.appendChild(opt);
  target_select.onchange = onTargetChanged;
  document.getElementById("f_href").focus();
  document.getElementById("f_href").select();
};

function onOK() {
  var required = {
    // f_href shouldn't be required or otherwise removing the link by entering an empty
    // url isn't possible anymore.
    // "f_href": i18n("You must enter the URL where this link points to")
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
  var fields = ["f_href", "f_title", "f_target" ];
  var param = new Object();
  for (var i in fields) {
    var id = fields[i];
    var el = document.getElementById(id);
    param[id] = el.value;
  }
  if (param.f_target == "_other")
    param.f_target = document.getElementById("f_other_target").value;
  __dlg_close(param);
  return false;
};

function onCancel() {
  __dlg_close(null);
  return false;
};

function openFileSelector() {
    
    // open the file selector popup
    // make sure it is at least this size
    var w=640;
    var h=480;
		
    if (window.screen) {
	w = parseInt(window.screen.availWidth * 0.50);
	h = parseInt(window.screen.availHeight * 0.50);
    }
    
    (w < 640) ? w = 640 : w = w;
    (h < 480) ? h = 480 : h = h;
    var dimensons = "width="+w+",height="+h;
    if (!document.all) {
	selector_window = window.open("@file_selector_link;noquote@", 
	   "file_selector" , 
	   "toolbar=no,menubar=no,personalbar=no,scrollbars=yes,resizable=yes," + 
	   dimensons);
    } else {
	selector_window = window.open("@file_selector_link;noquote@", 
	 "file_selector", 
	 "channelmode=no,directories=no,location=no,menubar=no,resizable=yes,scrollbars=yes,toolbar=no," + 
	 dimensons);
    }
    selector_window.moveTo(w/2,h/2);
    selector_window.focus();
    // 	  return false;
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
.list-odd {
    background-color:#eff3ff;
}
	</style>
	
</head>

<body onload="Init()">
  <div class="title">#acs-templating.HTMLArea_InsertModifyLink#</div>
    <div style="padding-left:10px;padding-right:10px;">
<form>
<table border="0" width="400" >
  <tr>
    <td class="label">URL:</td>
    <td colspan="2"><input type="text" id="f_href" style="width: 100%;" /></td>
  </tr>
  <tr>
    <td class="label">Title (tooltip):</td>
    <td colspan="2"><input type="text" id="f_title" style="width: 100%;"  /></td>
  </tr>
  <tr>
    <td class="label"><span id="f_target_label">Target:</span></td>
    <td><select id="f_target">
      <option value="">None (use implicit)</option>
      <option value="_blank">New window (_blank)</option>
      <option value="_self">Same frame (_self)</option>
      <option value="_top">Top frame (_top)</option>
    </select>
    </td><td align="right">
<if @fs_found@ eq 1>
  <button  type="button" onClick="openFileSelector();">#acs-templating.HTMLArea_OpenFileStorage#</button>
</if>
<else>
    <span style="margin-top:2px; margin-bottom:2px; border:2px outset #FFFFFF;padding-top:1px;padding-bottom:1px;padding-right:6px;padding-left:6px;color:GrayText;cursor:default;" title="#acs-templating.HTMLArea_FileStorageNotFoundToolTip#">#acs-templating.HTMLArea_OpenFileStorage#</span> 
  </else>
    <input type="text" name="f_other_target" id="f_other_target" size="10" style="visibility: hidden" />
  </td>
  </tr>
  <tr><td colspan="2">&nbsp; 
  <button type="submit" name="ok" onclick="return onOK();">OK</button> 
  <button type="button" name="cancel" onclick="return onCancel();">#acs-templating.HTMLArea_action_cancel#</button>
</td>
</tr>
</table>



</form>
</body>
</html>
