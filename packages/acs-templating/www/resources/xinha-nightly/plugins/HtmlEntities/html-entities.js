/*------------------------------------------*\
HtmlEntities for Xinha
____________________

Intended to faciliate the use of special characters with ISO 8 bit encodings.

Using the conversion map provided by mharrisonline in ticket #127

If you want to adjust the list, e.g. to except the characters that are available in the used charset,
edit Entities.js. 
You may save it under a different name using the xinha_config.HtmlEntities.EntitiesFile variable
\*------------------------------------------*/

function HtmlEntities(editor) {
	this.editor = editor;
}

HtmlEntities._pluginInfo = {
  name          : "HtmlEntities",
  version       : "1.0",
  developer     : "Raimund Meyer",
  developer_url : "http://rheinauf.de",
  c_owner       : "Xinha community",
  sponsor       : "",
  sponsor_url   : "",
  license       : "Creative Commons Attribution-ShareAlike License"
}
HTMLArea.Config.prototype.HtmlEntities =
{
	EntitiesFile : _editor_url + "plugins/HtmlEntities/Entities.js"
}
HtmlEntities.prototype.onGenerate = function() {
    eval("var e = "+ HTMLArea._geturlcontent(this.editor.config.HtmlEntities.EntitiesFile));
    var specialReplacements = this.editor.config.specialReplacements;
    for (var i in e)
    {
    	specialReplacements[i] = e[i];	
    }
}
