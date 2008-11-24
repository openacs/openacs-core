// File-Selector Plugin for xinha
// Developed in the Learn@WU Project of the
// Vienna University of Economics and Business Administration
// www.wu-wien.ac.at
//
// Authors: Günter Ernst guenter.ernst@wu-wien.ac.at
//     Gustaf Neumann (cleanup and addons)
//
// Distributed under the same terms as HTMLArea itself.
// This notice MUST stay intact for use (see license.txt).
//

// HTMLArea.loadStyle("oacs-fs.css", "OacsFs");

OacsFs._pluginInfo = {
    name          : "OacsFs",
    version       : "0.4",
    developer     : "Guenter Ernst, Gustaf Neumann",
    developer_url : "http://learn.wu-wien.ac.at",
    c_owner       : "Guenter Ernst",
    sponsor       : "Wirtschaftsuniversitaet Wien",
    sponsor_url   : "http://www.wu-wien.ac.at",
    license       : "htmlArea"
};

function OacsFs(editor) {
    var args = arguments;
    this.editor = editor;
    var ArgsString = args[1].toString();
    var additionalArgs = ArgsString.split(",");
    OacsFs.fs_package_id = this.editor.config.fs_package_id;
    OacsFs.package_id    = this.editor.config.package_id;
    OacsFs.folder_id     = this.editor.config.folder_id;
    OacsFs.file_types    = this.editor.config.file_types;
    OacsFs.script_dir    = this.editor.config.script_dir;
    OacsFs.wiki_p        = this.editor.config.wiki_p;
    OacsFs.fullscreen_mode = additionalArgs[1]; 

    if (typeof OacsFs.script_dir == "undefined") {
      // if no script dir is specified, use xowiki as a fallback
      OacsFs.script_dir = "/xowiki";
    }

    if (OacsFs.wiki_p) {
      // if wiki_p is specified, add inser-wlink to the list of icon buttons
      OacsFs.btnList.push(["insert-wlink", "Insert Wiki Link"]);
    }

    var cfg = editor.config;
    var tt = OacsFs.I18N;
    var bl = OacsFs.btnList;
    var self = this;

    //alert(this.editor.config.fs_package_id);
    //alert("length=" + bl.length);

    // register the toolbar buttons provided by this plugin
    for (var i = 0; i < bl.length; ++i) {
	var btn = bl[i];
	var id = "LW-" + btn[0];

	cfg.registerButton(id, HTMLArea._lc(btn[1], "OacsFs"), editor.imgURL(btn[0] + ".gif", "OacsFs"), false,
			   function(editor, id) {
			       // dispatch button press event
			       self.buttonPress(editor, id);
			   });
		
	switch (id) {
	case "LW-insert-ilink":
	    cfg.addToolbarElement(id, "createlink", +1);
	    break;
	case "LW-insert-image":
	    cfg.addToolbarElement(id, "insertimage", +1);
	    break;
        case "LW-insert-wlink":
            cfg.addToolbarElement(id, "createlink", +1);
            break;
	}
    }

    cfg.hideSomeButtons(" insertimage ");
    cfg.pageStyle = "@import url(" + _editor_url + 
	"plugins/OacsFs/oacs-fs.css) screen; "
};

OacsFs.btnList = [
		  ["insert-ilink", "Insert Internal Link"],
		  ["insert-image", "Insert Image"]
		  ];

OacsFs.prototype.buttonPress = function(editor, id) {
    OacsFs.editor = editor;
    switch (id) {
    case "LW-insert-ilink":
	this.insertInternalLink();
	break;
    case "LW-insert-image":
	this.insertImage();
	break;
    case "LW-insert-wlink":
        this.insertWlink();
        break;
    case "LW-close":
	window.close();
	break;
    }
};

// Called when the user clicks on "InsertLink" button.  If the link is already
// there, it will just modify it's properties.
OacsFs.prototype.insertInternalLink = function(link) {
    var editor = OacsFs.editor;	// for nested functions
    var outparam = null;

    if (typeof link == "undefined") {
	link = editor.getParentElement();
	if (link && !/^a$/i.test(link.tagName))
	    link = null;
    }
    if (link) {
	outparam = {
	    f_href   : HTMLArea.is_ie ? editor.stripBaseURL(link.href) : 
	    link.getAttribute("href"),
	    f_title  : link.title,
	    f_target : link.target,
	    f_usetarget : link.f_usetarget
	};
    } else {
	outparam = {
	    f_href   : '',
	    f_title  : '',
	    f_target : '',
	    f_usetarget : ''
	};
    }

    // normally, allow-tcl-page is turned of, so the link shows under /resources
    // the tcl source code, but not the result.
    // var PopupUrl = _editor_url + 
    //   "plugins/OacsFs/popups/insert-image.tcl?fs_package_id=" + 
    // fs_package_id;

    var PopupUrl = OacsFs.script_dir + "/xinha/insert-ilink?";
    if (typeof OacsFs.fs_package_id != "undefined") {
	PopupUrl = PopupUrl + "&fs_package_id=" + OacsFs.fs_package_id;
    }
    if (typeof OacsFs.folder_id != "undefined") {
	PopupUrl = PopupUrl + "&folder_id=" + OacsFs.folder_id;
    }
    if (typeof OacsFs.file_types != "undefined") {
	PopupUrl = PopupUrl + "&file_types=" + OacsFs.file_types;
    }

    Dialog(PopupUrl, function(param) {
	       if (!param) {	// user must have pressed Cancel
		   return false;
	       }
	       var ilink = editor._doc.createElement("a");
	       ilink.href = param.f_href.trim();
	       ilink.innerHTML = param.f_title.trim();
	       ilink.title = param.f_title.trim();
	       ilink.setAttribute("target", param.f_target.trim());
	       //ilink.setAttribute("use_target",param.f_usetarget.trim());

	       if (!link || link == null) {
		   if (HTMLArea.is_ie) {
		       editor.insertHTML(ilink.outerHTML);
		   } else {
		       editor.insertNodeAtSelection(ilink);
		   }
	       } else { 
		   var parent = link.parentNode;
		   parent.replaceChild(ilink, link);
	       }
	   }, outparam);
};


OacsFs.prototype.insertInternalLinkTlf = function(link) {
    var editor = OacsFs.editor;
    var outparam = null;
	
    if (typeof link == "undefined") {
	link = editor.getParentElement();
	if (link && /^a$/i.test(link.tagName)) {
	    alert("This is an external link and cannot be edited");
	    return false;
	}
	if (link && ((/^ilink$/i.test(link.tagName)== false) && 
		     (/^keyref$/i.test(link.tagName) == false) ))
	    link = null;
    }
	
	
    if (link) {
	outparam = {
	    f_title       : link.getAttribute("title"),
	    f_area        : link.getAttribute("area"),
	    f_restype     : link.getAttribute("restype"),
	    f_shortname   : link.getAttribute("shortname"),
	    f_presentation: link.getAttribute("presentation"),
	    f_label       : link.innerHTML
	};
    }

		
    var PopupUrl = OacsFs.script_dir + "/xinha/insert-ilink?";
    if (typeof OacsFs.fs_package_id != "undefined") {
	PopupUrl = PopupUrl + "&fs_package_id=" + OacsFs.fs_package_id;
    }
    if (typeof OacsFs.folder_id != "undefined") {
	PopupUrl = PopupUrl + "&folder_id=" + OacsFs.folder_id;
    }
	
    Dialog(PopupUrl, function(param) {
	       if (!param)
		   return false;
		
	       // create new ilink
	       var iLinkTagName;
	       if (param.f_restype.trim()== "glo") {
		   iLinkTagName = "keyref";
	       } else {
		   iLinkTagName = "ilink";
	       }
		
	       var iLink = editor._doc.createElement(iLinkTagName);
	       iLink.innerHTML = param.f_title.trim();
	       iLink.title = param.f_title.trim();
	       iLink.setAttribute("area", param.f_area.trim());
	       iLink.setAttribute("shortname",param.f_shortname.trim());
	       iLink.setAttribute("restype",param.f_restype.trim());		
		
	       // 		
	       if (!link || link == null) {
		   if (HTMLArea.is_ie) {
		       editor.insertHTML(iLink.outerHTML);
		   } else {
		       editor.insertNodeAtSelection(iLink);
		   }
	       } else { 
		   var iLinkParent = link.parentNode;
		   iLinkParent.replaceChild(iLink, link);
	       }
	       // 		var selection = editor._getSelection();
	       // 		selection.removeAllRanges();
	       editor.updateToolbar();
	   }, outparam);
};


// Called when the user clicks on "InsertImage" button.  If an image is already
// there, it will just modify it's properties.
OacsFs.prototype.insertImage = function(image) {
    var editor = OacsFs.editor;	// for nested functions
    var fs_package_id = OacsFs.fs_package_id;
    var outparam = null;
    if (typeof image == "undefined") {
	image = editor.getParentElement();
	if (image && !/^img$/i.test(image.tagName))
	    image = null;
    }
    if (image) outparam = {
	f_url    : HTMLArea.is_ie ? editor.stripBaseURL(image.src) : 
	image.getAttribute("src"),
	f_alt    : image.alt,
	f_border : image.border,
	f_align  : image.align,
	f_vert   : image.vspace,
	f_horiz  : image.hspace
    };

    // normally, allow tcl page is turned of, so the link shows under /resources
    // the source code, but not the result.
    // var PopupUrl = _editor_url + 
    //   "plugins/OacsFs/popups/insert-image.tcl?fs_package_id=" + 
    // fs_package_id;

    var PopupUrl = OacsFs.script_dir + "/xinha/insert-image?";
    if (typeof OacsFs.fs_package_id != "undefined") {
	PopupUrl = PopupUrl + "&fs_package_id=" + OacsFs.fs_package_id;
    }
    if (typeof OacsFs.folder_id != "undefined") {
	PopupUrl = PopupUrl + "&folder_id=" + OacsFs.folder_id;
    }
	
    Dialog(PopupUrl, function(param) {
	       if (!param) {	// user must have pressed Cancel
		   return false;
	       }
	       var img = image;
	       if (!img) {
		   var sel = editor._getSelection();
		   var range = editor._createRange(sel);
		   editor._doc.execCommand("insertimage", false, param.f_url);
		   if (HTMLArea.is_ie) {
		       img = range.parentElement();
		       // wonder if this works...
		       if (img.tagName.toLowerCase() != "img") {
			   img = img.previousSibling;
		       }
		   } else {
		       img = range.startContainer.previousSibling;
		   }
	       } else {
		   img.src = param.f_url;
	       }
	       for (field in param) {
		   var value = param[field];
		   switch (field) {
		   case "f_alt"    : img.alt	 = value; break;
		   case "f_border" : img.border = parseInt(value || "0"); break;
		   case "f_align"  : img.align	 = value; break;
		   case "f_vert"   : img.vspace = parseInt(value || "0"); break;
		   case "f_horiz"  : img.hspace = parseInt(value || "0"); break;
		   }
	       }
	   }, outparam);
};

// Called when the user clicks on "InserWikiLink" button.
OacsFs.prototype.insertWlink = function(link) {
    var editor = OacsFs.editor;     // for nested functions
    var PopupUrl = OacsFs.script_dir + "/xinha/insert-wlink?";

    // Check, if we have a package_id. Without a package_id, we do not
    // know from which directory we should list the wiki links.

    if (typeof OacsFs.package_id == "undefined" || !OacsFs.wiki_p) {
         alert("One can only insert Wiki links from inside a Wiki");
    } else {
         PopupUrl = PopupUrl + "&package_id=" + OacsFs.package_id;
         Dialog(PopupUrl, function(page) {
             if (!page) {   // user must have pressed Cancel
               return false;
             }

             // If there is a selection, use the selection as label,
             // otherwise use the title of the wiki page.
             var selection = editor._getSelection();
             var label = selection != "" ? selection : page.label;

             // Insert the page name and the label in wiki syntax
             editor.insertHTML("[[" + page.name 
                               + ((label != "") ? ("|" + label) : "") 
                               + "]]");
           },null);
    }
}
