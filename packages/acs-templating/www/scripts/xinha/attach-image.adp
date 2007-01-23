<html>
<head>
  <title>#acs-templating.HTMLArea_InsertImageTitle#</title>

<script type="text/javascript" src="/resources/acs-templating/xinha-nightly/popups/popup.js"></script>
  
@js_source;noquote@

<script type="text/javascript">
	var selector_window;
	window.resizeTo(415, 300);
	
	function Init() {
	  __dlg_init();
	  var param = window.dialogArguments;
	  if (param) {
	      document.getElementById("f_url").value = param["f_url"];
	      document.getElementById("f_alt").value = param["f_alt"];
	      document.getElementById("f_border").value = param["f_border"];
	      document.getElementById("f_align").value = param["f_align"];
	      document.getElementById("f_vert").value = param["f_vert"];
	      document.getElementById("f_horiz").value = param["f_horiz"];

	      window.ipreview.location.replace(param.f_url);
	  }
	  // document.getElementById("f_url").focus();
	  var f_url = document.getElementById("f_url");
	  var url = f_url.value;
	  if (url) {
      		 onOK();
	      	 __dlg_close(null);
	  } else {
	  	initCarousel_html_carousel();
	  }
	};
	
	function onOK() {
	  var required = {
	    "f_url": "#acs-templating.HTMLArea_NoURL#"
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
	  var param = new Object();
	  /* 
	  var fields = ["f_url"];
	  for (var i in fields) {
	    var id = fields[i];
	    var el = document.getElementById(id);
	    param[id] = el.value;
	  } 
	  */
	  param["f_url"] = document.getElementById("f_url").value;
	  if (selector_window) {
	    selector_window.close();
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

	function onPreview() {
	  var f_url = document.getElementById("f_url");
	  var url = f_url.value;
	  if (!url) {
	    alert("You have to enter an URL first");
	    f_url.focus();
	    return false;
	  }
	  if (document.getElementById('preview_div').style.display == 'none') { 
		document.getElementById('showpreview').click();
	  }
	  window.ipreview.location.replace(url);
	  return false;
	};

	function resizeWindow(formname) {
		var w, h;
		if (formname == "url") {
			w = 415;
			h = 330;
		}
		if (formname == "upload") {
			w = 415;
			h = 310;
		}
		if (document.getElementById('showpreview').checked == true) {
			h = h + 200;
		}
		window.resizeTo(w, h);
	}

	function togglePreview() {
		var w = window.clientWidth;
		var h = window.clientHeight;
		if (document.getElementById('preview_div').style.display == 'none') { 
			document.getElementById('preview_div').style.display='';
		} else { 
			document.getElementById('preview_div').style.display='none'; 
		}
		if (document.getElementById('insert_image_url').style.display == 'none') { 
			resizeWindow('upload');
		} else { 
			resizeWindow('url');
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
	#html-carousel {
		background: #f5f4e4; 
	} 
	#html-carousel .carousel-list li {
		margin:4px 0px 0px 0px; 
	} 
	#html-carousel .carousel-list li {
		width: 106px;
		border: 0px solid green;
		padding: 2px;
		padding-top: 15px;
		margin: 0;
		color: #3F3F3F; 
	} 
	#html-carousel .carousel-list li img {
		border:1px solid #999;
		display:block; 
		width:100px;
	} 
	#html-carousel {
		margin-bottom: 10px;
		float: left;     
		width: 330px;;     
		height: 155px; 
	} 
	/* BUTTONS */ 
	#prev-arrow-container, #next-arrow-container {
		float:left;
		margin: 1px;
		padding: 0px; 
	} 
	#next-arrow {
		cursor:pointer; 
		float:right;
	} 
	#prev-arrow {
		cursor:pointer; 
	} 

</style>

<link href="/resources/ajaxhelper/carousel/carousel.css" media="all" rel="Stylesheet" type="text/css" />
<script src="/resources/ajaxhelper/carousel/carousel.js" type="text/javascript"></script>

</head>

<body onload="Init()">
<!-- @parent_id@ -->
<div id="insert_image_upload">

	<table border="0" style="margin: 0 auto; text-align: left;padding: 0px;" width="100%">
	  <tbody>
      <td valign="top">
	<if @write_p@ eq 1>
	    <legend><b>@HTML_UploadTitle@</b></legend>
	    <formtemplate id="upload_form">
		   <input type="hidden" name="f_url" id="f_url" value="@f_url@"/>
	      <table cellspacing="2" cellpadding="2" border="0">
		<tr class="form-group">
		  <if @formerror.upload_file@ not nil>
		    <td class="form-widget-error">
		  </if>
	          <else>
		    <td class="form-widget">
                  </else> 	
		<fieldset>
        <legend>Choose Image</legend>
        	<table border=0 cellpadding=0 cellspacing=0 width="100%">
        	<tr>
        	<td>
        	<table border=0 cellpadding=0 cellspacing=0 width="330px">
        	<tr><td>
			<div id="prev-arrow-container">
				<img id="prev-arrow" class="left-button-image" src="/resources/ajaxhelper/carousel/left-enabled.gif"/>
			</div> 
			</td><td>
			<div id="next-arrow-container" >
				<img id="next-arrow" class="right-button-image" src="/resources/ajaxhelper/carousel/right-enabled.gif"/>
			</div> 
			</td></tr>
			</table>
			</td>			
			</tr>
			<tr>
			<td align="center">
			<div class="carousel-component" id="html-carousel">
				<div class="carousel-clip-region">
					<ul class="carousel-list">
						<formgroup id="choose_file">
							<li>
								<img src="/image/@formgroup.option@/thumbnail" onclick="document.getElementById('upload_form:elements:choose_file:@formgroup.option@').click()"  /><br / >@formgroup.widget;noquote@
								<formerror id="upload_file">
									<div class="form-error"><br />@formerror.upload_file@</div>
								</formerror>	
							</li>	
						</formgroup>						
					</ul>   
				</div> 			
			</div> 
						
			<script type="text/javascript">   

			function initCarousel_html_carousel() {
				carousel = new Carousel('html-carousel', {numVisible:1,scrollInc:3,animHandler:animHandler, animParameters:{duration:0.5}, buttonStateHandler:buttonStateHandler, nextElementID:'next-arrow', prevElementID:'prev-arrow', size:@recent_images:rowcount@})
			}
									
			function buttonStateHandler(button, enabled) {
				if (button == "prev-arrow") {
					$('prev-arrow').src = enabled ? "/resources/ajaxhelper/carousel/left-enabled.gif" : "/resources/ajaxhelper/carousel/left-disabled.gif"
				} else {
					$('next-arrow').src = enabled ? "/resources/ajaxhelper/carousel/right-enabled.gif" : "/resources/ajaxhelper/carousel/right-disabled.gif"
				}
			}
			
			function animHandler(carouselID, status, direction) {
				var region = $(carouselID).down(".carousel-clip-region")
				if (status == "before") {
					Effect.Fade(region, {to: 0.3, queue: { position:'end', scope: "carousel" }, duration: 0.2})
				}
				if (status == "after") {
					Effect.Fade(region, {to: 1, queue: { position:'end', scope: "carousel" }, duration: 0.2})
				}
			}			
			
			</script> 
		</td></tr>
		<tr><td>
			<formwidget id="select_btn">&nbsp;<button type="button" name="cancel" onclick="return onCancel();">#acs-templating.HTMLArea_action_cancel#</button>
		</td></tr>
		</table>
		</fieldset>
		</td>
	        </tr> 
		<tr class="form-element">
		  <if @formerror.upload_file@ not nil>
		    <td class="form-widget-error">
		  </if>
		  <else>
		    <td class="form-widget">
		  </else>
	<fieldset>
	<legend>or Upload a New Image</legend>

		  <formwidget id="upload_file">
		    <formerror id="upload_file">
		      <div class="form-error">@formerror.upload_file@</div>
		    </formerror><br />
                        #acs-templating.This_image_can_be_reused_by#<br />
                        <formgroup id="share">
                          @formgroup.widget;noquote@ @formgroup.label@
		    <br /></formgroup>
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  #acs-templating.This_image_can_be_reused_help#
		    <formerror id="share">
		      <div class="form-error">@formerror.share@</div>
		    </formerror>                        
	<br /><formwidget id="upload_btn">&nbsp;<button type="button" name="cancel" onclick="return onCancel();">#acs-templating.HTMLArea_action_cancel#</button>
	</fieldset>
      </td>
    </tr>
    </table>
    </formtemplate>
    </if>
	</td>
	</tr>
	<tr>
	<td>
	</td>
	</tr>
	  </tbody>
	</table>
</div>
</body>
</html>
