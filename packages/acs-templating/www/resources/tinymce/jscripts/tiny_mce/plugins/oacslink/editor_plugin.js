/**
 * $Id$
 *
 * @author Moxiecode
 * @copyright Copyright © 2004-2008, Moxiecode Systems AB, All rights reserved.
 */

(function() {
     // Load plugin specific language pack
     tinymce.PluginManager.requireLangPack('oacslink');

     tinymce.create('tinymce.plugins.OacsLinkPlugin', {
		init : function(ed, url) {
			this.editor = ed;

			// Register commands
			ed.addCommand('mceOacsLink', function() {
				var se = ed.selection;

				// No selection and not in link
				// if (se.isCollapsed() && !ed.dom.getParent(se.getNode(), 'A'))
				//	return;

				ed.windowManager.open({
					file : '/acs-templating/scripts/xinha/attach-file',
					width : 480 + parseInt(ed.getLang('oacslink.delta_width', 0)),
					height : 400 + parseInt(ed.getLang('oacslink.delta_height', 0)),
					inline : 1
				}, {
					plugin_url : url
				});
			});
			// Register buttons
			ed.addButton('oacslink', {
				title : 'oacslink.link_desc',
				         cmd : 'mceOacsLink',
                                         image: ed.baseURI.path + '/plugins/oacslink/img/attach.png'
			});

			ed.addShortcut('ctrl+k', 'oacslink.oacslink_desc', 'mceOacsLink');

			ed.onNodeChange.add(function(ed, cm, n, co) {
				cm.setDisabled('link', co && n.nodeName != 'A');
				cm.setActive('link', n.nodeName == 'A' && !n.name);
			});
		},

		getInfo : function() {
			return {
				longname : 'Oacs link',
				author : 'Moxiecode Systems AB',
				authorurl : 'http://tinymce.moxiecode.com',
				infourl : 'http://wiki.moxiecode.com/index.php/TinyMCE:Plugins/oacslink',
				version : tinymce.majorVersion + "." + tinymce.minorVersion
			};
		}
	});

	// Register plugin
	tinymce.PluginManager.add('oacslink', tinymce.plugins.OacsLinkPlugin);
})();