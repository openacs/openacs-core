function SmartReplace(_1){
this.editor=_1;
var _2=_1.config;
var _3=this;
_2.registerButton({id:"smartreplace",tooltip:this._lc("SmartReplace"),image:_editor_url+"plugins/SmartReplace/img/smartquotes.gif",textMode:false,action:function(_4){
_3.dialog(_4);
}});
_2.addToolbarElement("smartreplace","htmlmode",1);
}
SmartReplace._pluginInfo={name:"SmartReplace",version:"1.0",developer:"Raimund Meyer",developer_url:"http://rheinauf.de",c_owner:"Raimund Meyer",sponsor:"",sponsor_url:"",license:"htmlArea"};
SmartReplace.prototype._lc=function(_5){
return Xinha._lc(_5,"SmartReplace");
};
Xinha.Config.prototype.SmartReplace={"defaultActive":true,"quotes":null};
SmartReplace.prototype.toggleActivity=function(_6){
if(typeof _6!="undefined"){
this.active=_6;
}else{
this.active=this.active?false:true;
}
this.editor._toolbarObjects.smartreplace.state("active",this.active);
};
SmartReplace.prototype.onUpdateToolbar=function(){
this.editor._toolbarObjects.smartreplace.state("active",this.active);
};
SmartReplace.prototype.onGenerate=function(){
this.active=this.editor.config.SmartReplace.defaultActive;
this.editor._toolbarObjects.smartreplace.state("active",this.active);
var _7=this;
Xinha._addEvents(_7.editor._doc,["keypress"],function(_8){
return _7.keyEvent(Xinha.is_ie?_7.editor._iframe.contentWindow.event:_8);
});
var _9=this.editor.config.SmartReplace.quotes;
if(_9&&typeof _9=="object"){
this.openingQuotes=_9[0];
this.closingQuotes=_9[1];
this.openingQuote=_9[2];
this.closingQuote=_9[3];
}else{
this.openingQuotes=this._lc("OpeningDoubleQuotes");
this.closingQuotes=this._lc("ClosingDoubleQuotes");
this.openingQuote=this._lc("OpeningSingleQuote");
this.closingQuote=this._lc("ClosingSingleQuote");
}
if(this.openingQuotes=="OpeningDoubleQuotes"){
this.openingQuotes=String.fromCharCode(8220);
this.closingQuotes=String.fromCharCode(8221);
this.openingQuote=String.fromCharCode(8216);
this.closingQuote=String.fromCharCode(8217);
}
};
SmartReplace.prototype.keyEvent=function(ev){
if(!this.active){
return true;
}
var _b=this.editor;
var _c=Xinha.is_ie?ev.keyCode:ev.charCode;
var _d=String.fromCharCode(_c);
if(_c==32){
return this.smartDash();
}
if(_d=="\""||_d=="'"){
Xinha._stopEvent(ev);
return this.smartQuotes(_d);
}
return true;
};
SmartReplace.prototype.smartQuotes=function(_e){
if(_e=="'"){
var _f=this.openingQuote;
var _10=this.closingQuote;
}else{
var _f=this.openingQuotes;
var _10=this.closingQuotes;
}
var _11=this.editor;
var sel=_11.getSelection();
if(Xinha.is_ie){
var r=_11.createRange(sel);
if(r.text!==""){
r.text="";
}
r.moveStart("character",-1);
if(r.text.match(/\S/)){
r.moveStart("character",+1);
r.text=_10;
}else{
r.moveStart("character",+1);
r.text=_f;
}
}else{
if(!sel.isCollapsed){
_11.insertNodeAtSelection(document.createTextNode(""));
}
if(sel.anchorOffset>0){
sel.extend(sel.anchorNode,sel.anchorOffset-1);
}
if(sel.toString().match(/\S/)){
sel.collapse(sel.anchorNode,sel.anchorOffset);
_11.insertNodeAtSelection(document.createTextNode(_10));
}else{
sel.collapse(sel.anchorNode,sel.anchorOffset);
_11.insertNodeAtSelection(document.createTextNode(_f));
}
}
};
SmartReplace.prototype.smartDash=function(){
var _14=this.editor;
var sel=this.editor.getSelection();
if(Xinha.is_ie){
var r=this.editor.createRange(sel);
r.moveStart("character",-2);
if(r.text.match(/\s-/)){
r.text=" "+String.fromCharCode(8211);
}
}else{
sel.extend(sel.anchorNode,sel.anchorOffset-2);
if(sel.toString().match(/^-/)){
this.editor.insertNodeAtSelection(document.createTextNode(" "+String.fromCharCode(8211)));
}
sel.collapse(sel.anchorNode,sel.anchorOffset);
}
};
SmartReplace.prototype.replaceAll=function(){
var _17=["&quot;",String.fromCharCode(8220),String.fromCharCode(8221),String.fromCharCode(8222),String.fromCharCode(187),String.fromCharCode(171)];
var _18=["'",String.fromCharCode(8216),String.fromCharCode(8217),String.fromCharCode(8218),String.fromCharCode(8250),String.fromCharCode(8249)];
var _19=this.editor.getHTML();
var _1a=new RegExp("(\\s|^|>)("+_17.join("|")+")(\\S)","g");
_19=_19.replace(_1a,"$1"+this.openingQuotes+"$3");
var _1b=new RegExp("(\\s|^|>)("+_18.join("|")+")(\\S)","g");
_19=_19.replace(_1b,"$1"+this.openingQuote+"$3");
var _1c=new RegExp("(\\S)("+_17.join("|")+")","g");
_19=_19.replace(_1c,"$1"+this.closingQuotes);
var _1d=new RegExp("(\\S)("+_18.join("|")+")","g");
_19=_19.replace(_1d,"$1"+this.closingQuote);
var _1e=new RegExp("( |&nbsp;)(-)( |&nbsp;)","g");
_19=_19.replace(_1e," "+String.fromCharCode(8211)+" ");
this.editor.setHTML(_19);
};
SmartReplace.prototype.dialog=function(){
var _1f=this;
var _20=function(_21){
_1f.toggleActivity(_21.enable);
if(_21.convert){
_1f.replaceAll();
}
};
var _22=this;
Dialog(_editor_url+"plugins/SmartReplace/popups/dialog.html",_20,_22);
};

