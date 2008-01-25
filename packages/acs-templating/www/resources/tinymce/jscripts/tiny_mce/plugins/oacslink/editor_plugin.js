/**
 * $Id$
 *
 * @author Moxiecode
 * @copyright Copyright © 2004-2007, Moxiecode Systems AB, All rights reserved.
 */

/* Import plugin specific language pack */
tinyMCE.importPluginLanguagePack('oacslink');

var TinyMCE_OacsLinkPlugin = {
        getInfo : function() {
                return {
                        longname : 'OACS Advanced link',
                        author : 'SolutionGrove & Moxiecode Systems AB',
                        authorurl : 'http://tinymce.moxiecode.com',
                        infourl : 'http://tinymce.moxiecode.com/tinymce/docs/plugin_oacslink.html',
                        version : tinyMCE.majorVersion + "." + tinyMCE.minorVersion
                };
        },

        initInstance : function(inst) {
                inst.addShortcut('ctrl', 'k', 'lang_oacslink_desc', 'mceOacslink');
        },

        getControlHTML : function(cn) {
                switch (cn) {
                        case "oacslink":
                                return tinyMCE.getButtonHTML(cn, 'lang_oacslink_desc', '/resources/acs-templating/tinymce/jscripts/tiny_mce/plugins/oacslink/images/attach.png', 'mceOacslink');
                }
                return "";
        },

        execCommand : function(editor_id, element, command, user_interface, value) {
                switch (command) {
                        case "mceOacslink":
                                var anySelection = true;
                                var inst = tinyMCE.getInstanceById(editor_id);
                                var focusElm = inst.getFocusElement();
                                var selectedText = inst.selection.getSelectedText();

                                // anySelection = (tinyMCE.selectedElement.nodeName.toLowerCase() == "img") || (selectedText && selectedText.length > 0);

                                // if (anySelection || (focusElm != null && focusElm.nodeName == "A")) {
                                        var template = new Array();

                                        template['file']   = '/acs-templating/scripts/xinha/attach-file';
                                        template['width']  = 500;
                                        template['height'] = 400;

                                        tinyMCE.openWindow(template, {editor_id : editor_id, inline : "yes"});

								// }
                                return true;
				}
                	    
                return false;
        },

        handleNodeChange : function(editor_id, node, undo_index, undo_levels, visual_aid, any_selection) {
                if (node == null)
                        return;

                do {
                        if (node.nodeName == "A" && tinyMCE.getAttrib(node, 'href') != "") {
                                tinyMCE.switchClass(editor_id + '_link', 'mceButtonSelected');
                                return true;
                        }
                } while ((node = node.parentNode));

                tinyMCE.switchClass(editor_id + '_link', 'mceButtonNormal');

                return true;
        }
};

tinyMCE.addPlugin("oacslink", TinyMCE_OacsLinkPlugin);
