/**
 * $Id$
 *
 * @author Moxiecode
 * @copyright Copyright © 2004-2008, Moxiecode Systems AB, All rights reserved.
 */

(function() {
	// Load plugin specific language pack
	tinymce.PluginManager.requireLangPack('oacsimage');

	tinymce.create('tinymce.plugins.OacsImage', {
		/**
		 * Initializes the plugin, this will be executed after the plugin has been created.
		 * This call is done before the editor instance has finished it's initialization so use the onInit event
		 * of the editor instance to intercept that event.
		 *
		 * @param {tinymce.Editor} ed Editor instance that the plugin is initialized in.
		 * @param {string} url Absolute URL to where the plugin is located.
		 */
		init : function(ed, url) {
			// Register the command so that it can be invoked by using tinyMCE.activeEditor.execCommand('mceExample');
			ed.addCommand('mceOacsImage', function() {
			    var elm = tinyMCE.activeEditor.selection.getNode();
			    if (elm != null && ed.dom.getAttrib(elm, 'class').indexOf('mceItem') != -1)
                                return true;

			    ed.windowManager.open({
                                url:'/acs-templating/scripts/xinha/attach-image',
                                width: 380,
                                height: 450,
                                movable: true,
                                inline: true});

			    return true;

                            });

			// Register example button
			ed.addButton('image', {
				title : 'oacsimage.desc',
				cmd : 'mceOacsImage'
			});

			// Add a node change handler, selects the button in the UI when a image is selected
			ed.onNodeChange.add(function(ed, cm, n) {
			    cm.setActive('image',n.nameName == "IMG");
                                            });
                },
		/**
		 * Creates control instances based in the incomming name. This method is normally not
		 * needed since the addButton method of the tinymce.Editor class is a more easy way of adding buttons
		 * but you sometimes need to create more complex controls like listboxes, split buttons etc then this
		 * method can be used to create those.
		 *
		 * @param {String} n Name of the control to create.
		 * @param {tinymce.ControlManager} cm Control manager to use inorder to create new control.
		 * @return {tinymce.ui.Control} New control instance or null if no control was created.
		 */
		createControl : function(n, cm) {
			return null;
		},

		/**
		 * Returns information about the plugin as a name/value array.
		 * The current keys are longname, author, authorurl, infourl and version.
		 *
		 * @return {Object} Name/value array containing information about the plugin.
		 */
		getInfo : function() {
		    return {
                        longname : 'Oacs image',
			author : 'SolutionGrove, Moxiecde Systems AB',
			authorurl : 'http://tinymce.moxiecode.com',
			infourl : 'http://tinymce.moxiecode.com/tinymce/docs/plugin_oacsimage.html',
			version : tinyMCE.majorVersion + "." + tinyMCE.minorVersion
		    };
		}
	});

	// Register plugin
	tinymce.PluginManager.add('oacsimage', tinymce.plugins.OacsImage);
})();