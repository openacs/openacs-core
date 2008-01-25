/* Functions for the advimage plugin popup */

var preloadImg = null;
var orgImageWidth, orgImageHeight;

function preinit() {
	// Initialize
	tinyMCE.setWindowArg('mce_windowresize', false);
	// Import external list url javascript
	var url = tinyMCE.getParam("external_image_list_url");
	if (url != null) {
		// Fix relative
		if (url.charAt(0) != '/' && url.indexOf('://') == -1)
			url = tinyMCE.documentBasePath + "/" + url;

		document.write('<sc'+'ript language="javascript" type="text/javascript" src="' + url + '"></sc'+'ript>');
	}
}

function convertURL(url, node, on_save) {
	return eval("tinyMCEPopup.windowOpener." + tinyMCE.settings['urlconverter_callback'] + "(url, node, on_save);");
}

function getImageSrc(str) {
	var pos = -1;

	if (!str)
		return "";

	if ((pos = str.indexOf('this.src=')) != -1) {
		var src = str.substring(pos + 10);

		src = src.substring(0, src.indexOf('\''));

		if (tinyMCE.getParam('convert_urls'))
			src = convertURL(src, null, true);

		return src;
	}

	return "";
}

function init() {
	tinyMCEPopup.resizeToInnerSize();

	var formObj = document.forms[0];
	var inst = tinyMCE.getInstanceById(tinyMCE.getWindowArg('editor_id'));
	var elm = inst.getFocusElement();
	var action = "insert";
	var html = "";


	if (action == "update") {
		window.focus();
	}
}

function setSwapImageDisabled(state) {
	var formObj = document.forms[0];

	formObj.onmousemovecheck.checked = !state;

	setBrowserDisabled('overbrowser', state);
	setBrowserDisabled('outbrowser', state);

	if (formObj.imagelistover)
		formObj.imagelistover.disabled = state;

	if (formObj.imagelistout)
		formObj.imagelistout.disabled = state;

	formObj.onmouseoversrc.disabled = state;
	formObj.onmouseoutsrc.disabled  = state;
}

function setAttrib(elm, attrib, value) {
	var formObj = document.forms[0];
	var valueElm = formObj.elements[attrib];

	if (typeof(value) == "undefined" || value == null) {
		value = "";

		if (valueElm)
			value = valueElm.value;
	}

	if (value != "") {
		elm.setAttribute(attrib, value);

		if (attrib == "style")
			attrib = "style.cssText";

		if (attrib == "longdesc")
			attrib = "longDesc";

		if (attrib == "width") {
			attrib = "style.width";
			value = value + "px";
			value = value.replace(/%px/g, 'px');
		}

		if (attrib == "height") {
			attrib = "style.height";
			value = value + "px";
			value = value.replace(/%px/g, 'px');
		}

		if (attrib == "class")
			attrib = "className";

		eval('elm.' + attrib + "=value;");
	} else
		elm.removeAttribute(attrib);
}

function makeAttrib(attrib, value) {
	var formObj = document.forms[0];
	var valueElm = formObj.elements[attrib];

	if (typeof(value) == "undefined" || value == null) {
		value = "";

		if (valueElm)
			value = valueElm.value;
	}

	if (value == "")
		return "";

	// XML encode it
	value = value.replace(/&/g, '&amp;');
	value = value.replace(/\"/g, '&quot;');
	value = value.replace(/</g, '&lt;');
	value = value.replace(/>/g, '&gt;');

	return ' ' + attrib + '="' + value + '"';
}

function insertAction() {

	var inst = tinyMCE.getInstanceById(tinyMCE.getWindowArg('editor_id'));
	var elm = inst.getFocusElement();

	var formsList = document.forms;
        for (var i = 0; i < formsList.length; i ++)  {
            var src = formsList[i].f_url.value;
            if (src) break;
        }    

	if (elm != null && elm.nodeName == "IMG") {

		setAttrib(elm, 'src', convertURL(src, tinyMCE.imgElement));
		setAttrib(elm, 'mce_src', src);

		// Refresh in old MSIE
		if (tinyMCE.isMSIE5)
			elm.outerHTML = elm.outerHTML;
			
	} else {

		var html = "<img";

		html += makeAttrib('src', convertURL(src, tinyMCE.imgElement));
		html += makeAttrib('mce_src', src);
		html += " />";	

		tinyMCEPopup.execCommand("mceInsertContent", false, html);
	}

	tinyMCE._setEventsEnabled(inst.getBody(), false);
	tinyMCEPopup.close();
}

function cancelAction() {
	tinyMCEPopup.close();
}

function changeAppearance() {
	var formObj = document.forms[0];
	var img = document.getElementById('alignSampleImg');

	if (img) {
		img.align = formObj.align.value;
		img.border = formObj.border.value;
		img.hspace = formObj.hspace.value;
		img.vspace = formObj.vspace.value;
	}
}

function changeMouseMove() {
	var formObj = document.forms[0];

	setSwapImageDisabled(!formObj.onmousemovecheck.checked);
}

function updateStyle() {
	var formObj = document.forms[0];
	var st = tinyMCE.parseStyle(formObj.style.value);

	if (tinyMCE.getParam('inline_styles', false)) {
		st['width'] = formObj.width.value == '' ? '' : formObj.width.value + "px";
		st['height'] = formObj.height.value == '' ? '' : formObj.height.value + "px";
		st['border-width'] = formObj.border.value == '' ? '' : formObj.border.value + "px";
		st['margin-top'] = formObj.vspace.value == '' ? '' : formObj.vspace.value + "px";
		st['margin-bottom'] = formObj.vspace.value == '' ? '' : formObj.vspace.value + "px";
		st['margin-left'] = formObj.hspace.value == '' ? '' : formObj.hspace.value + "px";
		st['margin-right'] = formObj.hspace.value == '' ? '' : formObj.hspace.value + "px";
	} else {
		st['width'] = st['height'] = st['border-width'] = null;

		if (st['margin-top'] == st['margin-bottom'])
			st['margin-top'] = st['margin-bottom'] = null;

		if (st['margin-left'] == st['margin-right'])
			st['margin-left'] = st['margin-right'] = null;
	}

	formObj.style.value = tinyMCE.serializeStyle(st);
}

function styleUpdated() {
	var formObj = document.forms[0];
	var st = tinyMCE.parseStyle(formObj.style.value);

	if (st['width'])
		formObj.width.value = st['width'].replace('px', '');

	if (st['height'])
		formObj.height.value = st['height'].replace('px', '');

	if (st['margin-top'] && st['margin-top'] == st['margin-bottom'])
		formObj.vspace.value = st['margin-top'].replace('px', '');

	if (st['margin-left'] && st['margin-left'] == st['margin-right'])
		formObj.hspace.value = st['margin-left'].replace('px', '');

	if (st['border-width'])
		formObj.border.value = st['border-width'].replace('px', '');
}

function changeHeight() {
	var formObj = document.forms[0];

	if (!formObj.constrain.checked || !preloadImg) {
		updateStyle();
		return;
	}

	if (formObj.width.value == "" || formObj.height.value == "")
		return;

	var temp = (formObj.width.value / preloadImg.width) * preloadImg.height;
	formObj.height.value = temp.toFixed(0);
	updateStyle();
}

function changeWidth() {
	var formObj = document.forms[0];

	if (!formObj.constrain.checked || !preloadImg) {
		updateStyle();
		return;
	}

	if (formObj.width.value == "" || formObj.height.value == "")
		return;

	var temp = (formObj.height.value / preloadImg.height) * preloadImg.width;
	formObj.width.value = temp.toFixed(0);
	updateStyle();
}

function onSelectMainImage(target_form_element, name, value) {
	var formObj = document.forms[0];

	formObj.alt.value = name;
	formObj.title.value = name;

	resetImageData();
	showPreviewImage(formObj.elements[target_form_element].value, false);
}

function showPreviewImage(src, start) {
	var formObj = document.forms[0];

	selectByValue(document.forms[0], 'imagelistsrc', src);

	var elm = document.getElementById('prev');
	var src = src == "" ? src : tinyMCE.convertRelativeToAbsoluteURL(tinyMCE.settings['base_href'], src);

	if (!start && tinyMCE.getParam("advimage_update_dimensions_onchange", true))
		resetImageData();

	if (src == "")
		elm.innerHTML = "";
	else
		elm.innerHTML = '<img id="previewImg" src="' + src + '" border="0" onload="updateImageData();" onerror="resetImageData();" />'
}

function updateImageData() {
	var formObj = document.forms[0];
	var preloadImg = document.getElementById('previewImg');

	if (formObj.width.value == "")
		formObj.width.value = preloadImg.width;

	if (formObj.height.value == "")
		formObj.height.value = preloadImg.height;

	updateStyle();
}

function resetImageData() {
	var formObj = document.forms[0];
	formObj.width.value = formObj.height.value = "";	
}

function getSelectValue(form_obj, field_name) {
	var elm = form_obj.elements[field_name];

	if (elm == null || elm.options == null)
		return "";

	return elm.options[elm.selectedIndex].value;
}

function getImageListHTML(elm_id, target_form_element, onchange_func) {
	if (typeof(tinyMCEImageList) == "undefined" || tinyMCEImageList.length == 0)
		return "";

	var html = "";

	html += '<select id="' + elm_id + '" name="' + elm_id + '"';
	html += ' class="mceImageList" onfocus="tinyMCE.addSelectAccessibility(event, this, window);" onchange="this.form.' + target_form_element + '.value=';
	html += 'this.options[this.selectedIndex].value;';

	if (typeof(onchange_func) != "undefined")
		html += onchange_func + '(\'' + target_form_element + '\',this.options[this.selectedIndex].text,this.options[this.selectedIndex].value);';

	html += '"><option value="">---</option>';

	for (var i=0; i<tinyMCEImageList.length; i++)
		html += '<option value="' + tinyMCEImageList[i][1] + '">' + tinyMCEImageList[i][0] + '</option>';

	html += '</select>';

	return html;

	// tinyMCE.debug('-- image list start --', html, '-- image list end --');
}

// While loading
preinit();
