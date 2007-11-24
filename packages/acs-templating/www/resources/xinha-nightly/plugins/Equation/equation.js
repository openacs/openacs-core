/* This compressed file is part of Xinha. For uncomressed sources, forum, and bug reports, go to xinha.org */
function Equation(_1){
this.editor=_1;
var _2=_1.config;
var _3=this;
_2.registerButton({id:"equation",tooltip:this._lc("Formula Editor"),image:_1.imgURL("equation.gif","Equation"),textMode:false,action:function(_4,id){
_3.buttonPress(_4,id);
}});
_2.addToolbarElement("equation","inserthorizontalrule",-1);
mathcolor=_2.Equation.mathcolor;
mathfontfamily=_2.Equation.mathfontfamily;
if(!Xinha.is_ie){
_1.notifyOn("modechange",function(e,_7){
_3.onModeChange(_7);
});
this.onBeforeSubmit=this.onBeforeUnload=function(){
_3.unParse();
};
}
if(typeof AMprocessNode!="function"){
Xinha._loadback(_editor_url+"plugins/Equation/ASCIIMathML.js",function(){
translate();
});
}
}
Xinha.Config.prototype.Equation={"mathcolor":"black","mathfontfamily":"serif"};
Equation._pluginInfo={name:"ASCIIMathML Formula Editor",version:"2.2 (2007-08-17)",developer:"Raimund Meyer",developer_url:"http://rheinaufCMS.de",c_owner:"",sponsor:"Rheinauf",sponsor_url:"http://rheinaufCMS.de",license:"GNU/LGPL"};
Equation.prototype._lc=function(_8){
return Xinha._lc(_8,"Equation");
};
Equation.prototype.onGenerate=function(){
this.parse();
};
Equation.prototype.onUpdateToolbar=function(){
var e=this.editor;
if(!Xinha.is_ie&&this.reParse){
AMprocessNode(e._doc.body,false);
this.reParse=false;
}
if(!Xinha.is_ie){
var _a=e._getFirstAncestor(e.getSelection(),["span"]);
if(_a&&_a.className=="AM"){
e.selectNodeContents(_a);
}
}
};
Equation.prototype.onModeChange=function(_b){
var _c=this.editor._doc;
switch(_b.mode){
case "text":
this.unParse();
break;
case "wysiwyg":
this.parse();
break;
}
};
Equation.prototype.parse=function(){
if(!Xinha.is_ie){
var _d=this.editor._doc;
var _e=_d.getElementsByTagName("span");
for(var i=0;i<_e.length;i++){
var _10=_e[i];
if(_10.className!="AM"){
continue;
}
_10.title=_10.innerHTML;
AMprocessNode(_10,false);
}
}
};
Equation.prototype.unParse=function(){
var doc=this.editor._doc;
var _12=doc.getElementsByTagName("span");
for(var i=0;i<_12.length;i++){
var _14=_12[i];
if(_14.className.indexOf("AM")==-1||_14.getElementsByTagName("math").length==0){
continue;
}
var _15=_14.getAttribute("title");
_14.innerHTML=_15;
_14.setAttribute("title",null);
this.editor.setHTML(this.editor.getHTML());
}
};
Equation.prototype.buttonPress=function(){
var _16=this;
var _17=this.editor;
var _18={};
_18["editor"]=_17;
var _19=_17._getFirstAncestor(_17.getSelection(),["span"]);
if(_19){
_18["editedNode"]=_19;
}
_17._popupDialog("plugin://Equation/dialog",function(_1a){
_16.insert(_1a);
},_18);
};
Equation.prototype.insert=function(_1b){
if(typeof _1b["formula"]!="undefined"){
var _1c=(_1b["formula"]!="")?_1b["formula"].replace(/^`?(.*)`?$/m,"`$1`"):"";
if(_1b["editedNode"]&&(_1b["editedNode"].tagName.toLowerCase()=="span")){
var _1d=_1b["editedNode"];
if(_1c!=""){
_1d.innerHTML=_1c;
if(!Xinha.is_ie){
_1d.title=_1c;
}
}else{
_1d.parentNode.removeChild(_1d);
}
}else{
if(!_1b["editedNode"]&&_1c!=""){
if(!Xinha.is_ie){
var _1d=document.createElement("span");
_1d.className="AM";
this.editor.insertNodeAtSelection(_1d);
_1d.innerHTML=_1c;
_1d.title=_1c;
}else{
this.editor.insertHTML("<span class=\"AM\">"+_1c+"</span>");
}
}
}
if(!Xinha.is_ie){
AMprocessNode(this.editor._doc.body,false);
}
}
};

