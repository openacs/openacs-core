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
Xinha.prependDom0Event(_1._textArea.form,"submit",function(){
_3.unParse();
_3.reParse=true;
});
}
if(typeof AMprocessNode!="function"){
Xinha._loadback(_editor_url+"plugins/Equation/ASCIIMathML.js",function(){
translate();
});
}
}
Xinha.Config.prototype.Equation={"mathcolor":"red","mathfontfamily":"serif"};
Equation._pluginInfo={name:"ASCIIMathML Formula Editor",version:"2.0",developer:"Raimund Meyer",developer_url:"http://rheinaufCMS.de",c_owner:"",sponsor:"Rheinauf",sponsor_url:"http://rheinaufCMS.de",license:"GNU/LGPL"};
Equation.prototype._lc=function(_8){
return Xinha._lc(_8,"Equation");
};
Equation.prototype.onGenerate=function(){
this.parse();
};
Equation.prototype.onUpdateToolbar=function(){
if(!Xinha.is_ie&&this.reParse){
AMprocessNode(this.editor._doc.body,false);
}
};
Equation.prototype.onModeChange=function(_9){
var _a=this.editor._doc;
switch(_9.mode){
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
var _b=this.editor._doc;
var _c=_b.getElementsByTagName("span");
for(var i=0;i<_c.length;i++){
var _e=_c[i];
if(_e.className!="AM"){
continue;
}
_e.title=_e.innerHTML;
AMprocessNode(_e,false);
}
}
};
Equation.prototype.unParse=function(){
var _f=this.editor._doc;
var _10=_f.getElementsByTagName("span");
for(var i=0;i<_10.length;i++){
var _12=_10[i];
if(_12.className.indexOf("AM")==-1){
continue;
}
var _13=_12.getAttribute("title");
_12.innerHTML=_13;
_12.setAttribute("title",null);
this.editor.setHTML(this.editor.getHTML());
}
};
Equation.prototype.buttonPress=function(){
var _14=this;
var _15=this.editor;
var _16={};
_16["editor"]=_15;
var _17=_15._getFirstAncestor(_15.getSelection(),["span"]);
if(_17){
_16["editedNode"]=_17;
}
_15._popupDialog("plugin://Equation/dialog",function(_18){
_14.insert(_18);
},_16);
};
Equation.prototype.insert=function(_19){
if(typeof _19["formula"]!="undefined"){
var _1a=(_19["formula"]!="")?_19["formula"].replace(/^`?(.*)`?$/m,"`$1`"):"";
if(_19["editedNode"]&&(_19["editedNode"].tagName.toLowerCase()=="span")){
var _1b=_19["editedNode"];
if(_1a!=""){
_1b.innerHTML=_1a;
_1b.title=_1a;
}else{
_1b.parentNode.removeChild(_1b);
}
}else{
if(!_19["editedNode"]&&_1a!=""){
if(!Xinha.is_ie){
var _1b=document.createElement("span");
_1b.className="AM";
this.editor.insertNodeAtSelection(_1b);
_1b.innerHTML=_1a;
_1b.title=_1a;
}else{
this.editor.insertHTML("<span class=\"AM\" title=\""+_1a+"\">"+_1a+"</span>");
}
}
}
if(!Xinha.is_ie){
AMprocessNode(this.editor._doc.body,false);
}
}
};

