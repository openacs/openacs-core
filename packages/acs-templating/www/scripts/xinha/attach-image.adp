<master src="/www/blank-master">

<div id="insert_image_upload">

	<table border="0" style="margin: 0 auto; text-align: left;padding: 0px;" width="100%">
	  <tbody>
      <td valign="top">
	<if @write_p;literal@ true>

	    <formtemplate id="upload_form" style="attach-image-form">
		  <input type="hidden" name="f_url" id="f_url" value="@f_url@"/>
	      <table cellspacing="2" cellpadding="2" border="0">
		<tr class="form-group">
		  <if @formerror.upload_file@ not nil>
		    <td class="form-widget-error">
		  </if>
	          <else>
		    <td class="form-widget">
                  </else> 	
                  <if @ajaxhelper_p;literal@ true>
                 <fieldset>
        <legend>#acs-templating.Choose_Image#</legend>
        	<table border="0" cellpadding="0" cellspacing="0" width="100%">
        	<tr>
        	<td>
        	<table border="0" cellpadding="0" cellspacing="0" width="330px">
        	<tr><td>
			<div id="prev-arrow-container">
				<img id="prev-arrow" class="left-button-image" src="/resources/ajaxhelper/carousel/left-disabled.gif"/>
			</div> 
			</td><td>
			<div id="next-arrow-container" >
				<img id="next-arrow" class="right-button-image" src="/resources/ajaxhelper/carousel/right-disabled.gif"/>
			</div> 
			</td></tr>
			</table>
			</td>			
			</tr>
			<tr>
			<td align="center">
			<div class="carousel-component" id="html-carousel">
				<div class="carousel-clip-region">
					<ul class="carousel-list"></ul>   
				</div>
			</div> 
		</td></tr>
		<tr><td>
			<formwidget id="select_btn">&nbsp;<input type="button" name="cancel" value="#acs-templating.HTMLArea_action_cancel#" onclick="javascript:onCancel();">
		</td></tr>
		</table>
		</fieldset>
              </if>
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
	<legend>#acs-templating.Upload_a_New_Image#</legend>

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
	<br /><formwidget id="upload_btn">&nbsp;<input type="button" name="cancel" value="#acs-templating.HTMLArea_action_cancel#" onclick="javascript:onCancel();">
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
