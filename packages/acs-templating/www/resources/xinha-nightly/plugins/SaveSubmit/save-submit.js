function SaveSubmit(_1){
this.editor=_1;
this.changed=false;
var _2=this;
var _3=_1.config;
this.textarea=this.editor._textArea;
this.image_changed=_editor_url+"plugins/SaveSubmit/img/ed_save_red.gif";
this.image_unchanged=_editor_url+"plugins/SaveSubmit/img/ed_save_green.gif";
_3.registerButton({id:"savesubmit",tooltip:_2._lc("Save"),image:this.image_unchanged,textMode:false,action:function(_4){
_2.save(_4);
}});
_3.addToolbarElement("savesubmit","popupeditor",-1);
}
SaveSubmit.prototype._lc=function(_5){
return Xinha._lc(_5,"SaveSubmit");
};
SaveSubmit._pluginInfo={name:"SaveSubmit",version:"1.0",developer:"Raimund Meyer",developer_url:"http://rheinauf.de",c_owner:"Raimund Meyer",sponsor:"",sponsor_url:"",license:"htmlArea"};
SaveSubmit.prototype.onGenerateOnce=function(){
this.initial_html=this.editor.getInnerHTML();
};
SaveSubmit.prototype.onKeyPress=function(ev){
if(ev.ctrlKey&&this.editor.getKey(ev)=="s"){
this.save(this.editor);
Xinha._stopEvent(ev);
return true;
}else{
if(!this.changed){
if(this.getChanged()){
this.setChanged();
}
return false;
}
}
};
SaveSubmit.prototype.onExecCommand=function(_7){
if(this.changed&&_7=="undo"){
if(this.initial_html==this.editor.getInnerHTML()){
this.setUnChanged();
}
return false;
}
};
SaveSubmit.prototype.onUpdateToolbar=function(){
if(!this.changed){
if(this.getChanged()){
this.setChanged();
}
return false;
}
};
SaveSubmit.prototype.getChanged=function(){
if(this.initial_html===null){
this.initial_html=this.editor.getInnerHTML();
}
if(this.initial_html!=this.editor.getInnerHTML()&&this.changed==false){
this.changed=true;
return true;
}else{
return false;
}
};
SaveSubmit.prototype.setChanged=function(){
this.editor._toolbarObjects.savesubmit.swapImage(this.image_changed);
this.editor.updateToolbar();
};
SaveSubmit.prototype.setUnChanged=function(){
this.changed=false;
this.editor._toolbarObjects.savesubmit.swapImage(this.image_unchanged);
};
SaveSubmit.prototype.changedReset=function(){
this.initial_html=null;
this.setUnChanged();
};
SaveSubmit.prototype.save=function(_8){
this.buildMessage();
var _9=this;
var _a=_8._textArea.form;
_a.onsubmit();
var _b="";
for(var i=0;i<_a.elements.length;i++){
_b+=((i>0)?"&":"")+_a.elements[i].name+"="+encodeURIComponent(_a.elements[i].value);
}
Xinha._postback(_8._textArea.form.action,_b,function(_d){
if(_d){
_9.setMessage(_d);
_9.changedReset();
}
removeMessage=function(){
_9.removeMessage();
};
window.setTimeout("removeMessage()",1000);
});
};
SaveSubmit.prototype.setMessage=function(_e){
var _f=this.textarea;
if(!document.getElementById("message_sub_"+_f.id)){
return;
}
var elt=document.getElementById("message_sub_"+_f.id);
elt.innerHTML=Xinha._lc(_e,"SaveSubmit");
};
SaveSubmit.prototype.removeMessage=function(){
var _11=this.textarea;
if(!document.getElementById("message_"+_11.id)){
return;
}
document.body.removeChild(document.getElementById("message_"+_11.id));
};
SaveSubmit.prototype.buildMessage=function(){
var _12=this.textarea;
var _13=this.editor._htmlArea;
var _14=document.createElement("div");
_14.id="message_"+_12.id;
_14.className="loading";
_14.style.width=_13.offsetWidth+"px";
_14.style.left=Xinha.findPosX(_13)+"px";
_14.style.top=(Xinha.findPosY(_13)+parseInt(_13.offsetHeight)/2)-50+"px";
var _15=document.createElement("div");
_15.className="loading_main";
_15.id="loading_main_"+_12.id;
_15.appendChild(document.createTextNode(this._lc("Saving...")));
var _16=document.createElement("div");
_16.className="loading_sub";
_16.id="message_sub_"+_12.id;
_16.appendChild(document.createTextNode(this._lc("in progress")));
_14.appendChild(_15);
_14.appendChild(_16);
document.body.appendChild(_14);
};

