function GetHtmlImplementation(_1){
this.editor=_1;
}
GetHtmlImplementation._pluginInfo={name:"GetHtmlImplementation DOMwalk",origin:"Xinha Core",version:"$LastChangedRevision: 821 $".replace(/^[^:]*: (.*) \$$/,"$1"),developer:"The Xinha Core Developer Team",developer_url:"$HeadURL: http://svn.xinha.python-hosting.com/trunk/modules/GetHtml/DOMwalk.js $".replace(/^[^:]*: (.*) \$$/,"$1"),sponsor:"",sponsor_url:"",license:"htmlArea"};
Xinha.getHTML=function(_2,_3,_4){
try{
return Xinha.getHTMLWrapper(_2,_3,_4);
}
catch(ex){
alert(Xinha._lc("Your Document is not well formed. Check JavaScript console for details."));
return _4._iframe.contentWindow.document.body.innerHTML;
}
};
Xinha.emptyAttributes=" checked disabled ismap readonly nowrap compact declare selected defer multiple noresize noshade ";
Xinha.elGetsNewLine=function(el){
return (" br meta link title ".indexOf(" "+el.tagName.toLowerCase()+" ")!=-1);
};
Xinha.getHTMLWrapper=function(_6,_7,_8,_9){
var _a="";
if(!_9){
_9="";
}
switch(_6.nodeType){
case 10:
case 6:
case 12:
break;
case 2:
break;
case 4:
_a+=(Xinha.is_ie?("\n"+_9):"")+"<![CDATA["+_6.data+"]]>";
break;
case 5:
_a+="&"+_6.nodeValue+";";
break;
case 7:
_a+=(Xinha.is_ie?("\n"+_9):"")+"<"+"?"+_6.target+" "+_6.data+" ?>";
break;
case 1:
case 11:
case 9:
var _b;
var i;
var _d=(_6.nodeType==1)?_6.tagName.toLowerCase():"";
if((_d=="script"||_d=="noscript")&&_8.config.stripScripts){
break;
}
if(_7){
_7=!(_8.config.htmlRemoveTags&&_8.config.htmlRemoveTags.test(_d));
}
if(Xinha.is_ie&&_d=="head"){
if(_7){
_a+=(Xinha.is_ie?("\n"+_9):"")+"<head>";
}
var _e=RegExp.multiline;
RegExp.multiline=true;
var _f=_6.innerHTML.replace(Xinha.RE_tagName,function(str,p1,p2){
return p1+p2.toLowerCase();
}).replace(/\s*=\s*(([^'"][^>\s]*)([>\s])|"([^"]+)"|'([^']+)')/g,"=\"$2$4$5\"$3").replace(/<(link|meta)((\s*\S*="[^"]*")*)>/g,"<$1$2 />");
RegExp.multiline=_e;
_a+=_f+"\n";
if(_7){
_a+=(Xinha.is_ie?("\n"+_9):"")+"</head>";
}
break;
}else{
if(_7){
_b=(!(_6.hasChildNodes()||Xinha.needsClosingTag(_6)));
_a+=((Xinha.isBlockElement(_6)||Xinha.elGetsNewLine(_6))?("\n"+_9):"")+"<"+_6.tagName.toLowerCase();
var _13=_6.attributes;
for(i=0;i<_13.length;++i){
var a=_13.item(i);
if(typeof a.nodeValue=="object"){
continue;
}
if(_6.tagName.toLowerCase()=="input"&&_6.type.toLowerCase()=="checkbox"&&a.nodeName.toLowerCase()=="value"&&a.nodeValue.toLowerCase()=="on"){
continue;
}
if(!a.specified&&!(_6.tagName.toLowerCase().match(/input|option/)&&a.nodeName=="value")&&!(_6.tagName.toLowerCase().match(/area/)&&a.nodeName.match(/shape|coords/i))){
continue;
}
var _15=a.nodeName.toLowerCase();
if(/_moz_editor_bogus_node/.test(_15)){
_a="";
break;
}
if(/(_moz)|(contenteditable)|(_msh)/.test(_15)){
continue;
}
var _16;
if(Xinha.emptyAttributes.indexOf(" "+_15+" ")!=-1){
_16=_15;
}else{
if(_15!="style"){
if(typeof _6[a.nodeName]!="undefined"&&_15!="href"&&_15!="src"&&!(/^on/.test(_15))){
_16=_6[a.nodeName];
}else{
_16=a.nodeValue;
if(Xinha.is_ie&&(_15=="href"||_15=="src")){
_16=_8.stripBaseURL(_16);
}
if(_8.config.only7BitPrintablesInURLs&&(_15=="href"||_15=="src")){
_16=_16.replace(/([^!-~]+)/g,function(_17){
return escape(_17);
});
}
}
}else{
if(!Xinha.is_ie){
_16=_6.style.cssText.replace(/rgb\(.*?\)/ig,function(rgb){
return Xinha._colorToRgb(rgb);
});
}
}
}
if(/^(_moz)?$/.test(_16)){
continue;
}
_a+=" "+_15+"=\""+Xinha.htmlEncode(_16)+"\"";
}
if(Xinha.is_ie&&_6.style.cssText){
_a+=" style=\""+_6.style.cssText.toLowerCase()+"\"";
}
if(Xinha.is_ie&&_6.tagName.toLowerCase()=="option"&&_6.selected){
_a+=" selected=\"selected\"";
}
if(_a!==""){
if(_b&&_d=="p"){
_a+=">&nbsp;</p>";
}else{
if(_b){
_a+=" />";
}else{
_a+=">";
}
}
}
}
}
var _19=false;
if(_d=="script"||_d=="noscript"){
if(!_8.config.stripScripts){
if(Xinha.is_ie){
var _1a="\n"+_6.innerHTML.replace(/^[\n\r]*/,"").replace(/\s+$/,"")+"\n"+_9;
}else{
var _1a=(_6.hasChildNodes())?_6.firstChild.nodeValue:"";
}
_a+=_1a+"</"+_d+">"+((Xinha.is_ie)?"\n":"");
}
}else{
if(_d=="pre"){
_a+=((Xinha.is_ie)?"\n":"")+_6.innerHTML.replace(/<br>/g,"\n")+"</"+_d+">";
}else{
for(i=_6.firstChild;i;i=i.nextSibling){
if(!_19&&i.nodeType==1&&Xinha.isBlockElement(i)){
_19=true;
}
_a+=Xinha.getHTMLWrapper(i,true,_8,_9+"  ");
}
if(_7&&!_b){
_a+=(((Xinha.isBlockElement(_6)&&_19)||_d=="head"||_d=="html")?("\n"+_9):"")+"</"+_6.tagName.toLowerCase()+">";
}
}
}
break;
case 3:
if(/^script|noscript|style$/i.test(_6.parentNode.tagName)){
_a=_6.data;
}else{
if(_6.data.trim()==""){
_a="";
}else{
_a=Xinha.htmlEncode(_6.data);
}
}
break;
case 8:
_a="<!--"+_6.data+"-->";
break;
}
return _a;
};

