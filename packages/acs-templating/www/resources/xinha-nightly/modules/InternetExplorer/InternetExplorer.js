InternetExplorer._pluginInfo={name:"Internet Explorer",origin:"Xinha Core",version:"$LastChangedRevision: 816 $".replace(/^[^:]*: (.*) \$$/,"$1"),developer:"The Xinha Core Developer Team",developer_url:"$HeadURL: http://svn.xinha.python-hosting.com/trunk/modules/InternetExplorer/InternetExplorer.js $".replace(/^[^:]*: (.*) \$$/,"$1"),sponsor:"",sponsor_url:"",license:"htmlArea"};
function InternetExplorer(_1){
this.editor=_1;
_1.InternetExplorer=this;
}
InternetExplorer.prototype.onKeyPress=function(ev){
if(this.editor.isShortCut(ev)){
switch(this.editor.getKey(ev).toLowerCase()){
case "n":
this.editor.execCommand("formatblock",false,"<p>");
Xinha._stopEvent(ev);
return true;
break;
case "1":
case "2":
case "3":
case "4":
case "5":
case "6":
this.editor.execCommand("formatblock",false,"<h"+this.editor.getKey(ev).toLowerCase()+">");
Xinha._stopEvent(ev);
return true;
break;
}
}
switch(ev.keyCode){
case 8:
case 46:
if(this.handleBackspace()){
Xinha._stopEvent(ev);
return true;
}
break;
}
return false;
};
InternetExplorer.prototype.handleBackspace=function(){
var _3=this.editor;
var _4=_3.getSelection();
if(_4.type=="Control"){
var _5=_3.activeElement(_4);
Xinha.removeFromParent(_5);
return true;
}
var _6=_3.createRange(_4);
var r2=_6.duplicate();
r2.moveStart("character",-1);
var a=r2.parentElement();
if(a!=_6.parentElement()&&(/^a$/i.test(a.tagName))){
r2.collapse(true);
r2.moveEnd("character",1);
r2.pasteHTML("");
r2.select();
return true;
}
};
InternetExplorer.prototype.inwardHtml=function(_9){
_9=_9.replace(/<(\/?)del(\s|>|\/)/ig,"<$1strike$2");
_9=_9.replace(/(&nbsp;)?([\s\S]*?)(<script|<!--)/i,"$2&nbsp;$3");
return _9;
};
InternetExplorer.prototype.outwardHtml=function(_a){
_a=_a.replace(/&nbsp;(\s*)(<script|<!--)/i,"$1$2");
return _a;
};
Xinha.prototype.insertNodeAtSelection=function(_b){
this.insertHTML(_b.outerHTML);
};
Xinha.prototype.getParentElement=function(_c){
if(typeof _c=="undefined"){
_c=this.getSelection();
}
var _d=this.createRange(_c);
switch(_c.type){
case "Text":
var _e=_d.parentElement();
while(true){
var _f=_d.duplicate();
_f.moveToElementText(_e);
if(_f.inRange(_d)){
break;
}
if((_e.nodeType!=1)||(_e.tagName.toLowerCase()=="body")){
break;
}
_e=_e.parentElement;
}
return _e;
case "None":
return _d.parentElement();
case "Control":
return _d.item(0);
default:
return this._doc.body;
}
};
Xinha.prototype.activeElement=function(sel){
if((sel===null)||this.selectionEmpty(sel)){
return null;
}
if(sel.type.toLowerCase()=="control"){
return sel.createRange().item(0);
}else{
var _11=sel.createRange();
var _12=this.getParentElement(sel);
if(_12.innerHTML==_11.htmlText){
return _12;
}
return null;
}
};
Xinha.prototype.selectionEmpty=function(sel){
if(!sel){
return true;
}
return this.createRange(sel).htmlText==="";
};
Xinha.prototype.saveSelection=function(){
return this.createRange(this._getSelection());
};
Xinha.prototype.restoreSelection=function(_14){
_14.select();
};
Xinha.prototype.selectNodeContents=function(_15,pos){
this.focusEditor();
this.forceRedraw();
var _17;
var _18=typeof pos=="undefined"?true:false;
if(_18&&_15.tagName&&_15.tagName.toLowerCase().match(/table|img|input|select|textarea/)){
_17=this._doc.body.createControlRange();
_17.add(_15);
}else{
_17=this._doc.body.createTextRange();
_17.moveToElementText(_15);
}
_17.select();
};
Xinha.prototype.insertHTML=function(_19){
this.focusEditor();
var sel=this.getSelection();
var _1b=this.createRange(sel);
_1b.pasteHTML(_19);
};
Xinha.prototype.getSelectedHTML=function(){
var sel=this.getSelection();
var _1d=this.createRange(sel);
if(_1d.htmlText){
return _1d.htmlText;
}else{
if(_1d.length>=1){
return _1d.item(0).outerHTML;
}
}
return "";
};
Xinha.prototype.getSelection=function(){
return this._doc.selection;
};
Xinha.prototype.createRange=function(sel){
return sel.createRange();
};
Xinha.prototype.isKeyEvent=function(_1f){
return _1f.type=="keydown";
};
Xinha.prototype.getKey=function(_20){
return String.fromCharCode(_20.keyCode);
};
Xinha.getOuterHTML=function(_21){
return _21.outerHTML;
};
Xinha.prototype.cc=String.fromCharCode(8201);
Xinha.prototype.setCC=function(_22){
if(_22=="textarea"){
var ta=this._textArea;
var pos=document.selection.createRange();
pos.collapse();
pos.text=this.cc;
var _25=ta.value.indexOf(this.cc);
var _26=ta.value.substring(0,_25);
var _27=ta.value.substring(_25+this.cc.length,ta.value.length);
if(_27.match(/^[^<]*>/)){
var _28=_27.indexOf(">")+1;
ta.value=_26+_27.substring(0,_28)+this.cc+_27.substring(_28,_27.length);
}else{
ta.value=_26+this.cc+_27;
}
}else{
var sel=this.getSelection();
var r=sel.createRange();
if(sel.type=="Control"){
var _2b=r.item(0);
_2b.outerHTML+=this.cc;
}else{
r.collapse();
r.text=this.cc;
}
}
};
Xinha.prototype.findCC=function(_2c){
var _2d=(_2c=="textarea")?this._textArea:this._doc.body;
range=_2d.createTextRange();
if(range.findText(escape(this.cc))){
range.select();
range.text="";
}
if(range.findText(this.cc)){
range.select();
range.text="";
}
if(_2c=="textarea"){
this._textArea.focus();
}
};
Xinha.getDoctype=function(doc){
return (doc.compatMode=="CSS1Compat")?"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">":"";
};

