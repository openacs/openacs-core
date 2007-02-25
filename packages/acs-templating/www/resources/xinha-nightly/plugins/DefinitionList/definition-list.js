function DefinitionList(_1){
this.editor=_1;
var _2=_1.config;
var bl=DefinitionList.btnList;
var _4=this;
var _5=["linebreak"];
for(var i=0;i<bl.length;++i){
var _7=bl[i];
if(!_7){
_5.push("separator");
}else{
var id=_7[0];
_2.registerButton(id,this._lc(_7[1]),_1.imgURL("ed_"+_7[0]+".gif","DefinitionList"),false,function(_9,id){
_4.buttonPress(_9,id);
});
_5.push(id);
}
}
_2.toolbar.push(_5);
}
DefinitionList._pluginInfo={name:"DefinitionList",version:"1.0",developer:"Udo Schmal",developer_url:"",c_owner:"Udo Schmal",license:"htmlArea"};
DefinitionList.btnList=[["dl","definition list"],["dt","definition term"],["dd","definition description"]];
DefinitionList.prototype._lc=function(_b){
return HTMLArea._lc(_b,"DefinitionList");
};
DefinitionList.prototype.onGenerate=function(){
var _c="DefinitionList-style";
var _d=this.editor._doc.getElementById(_c);
if(_d==null){
_d=this.editor._doc.createElement("link");
_d.id=_c;
_d.rel="stylesheet";
_d.href=_editor_url+"plugins/DefinitionList/definition-list.css";
this.editor._doc.getElementsByTagName("HEAD")[0].appendChild(_d);
}
};
DefinitionList.prototype.buttonPress=function(_e,_f){
if(_f=="dl"){
var pe=_e.getParentElement();
while(pe.parentNode.tagName.toLowerCase()!="body"){
pe=pe.parentNode;
}
var dx=_e._doc.createElement(_f);
dx.innerHTML="&nbsp;";
if(pe.parentNode.lastChild==pe){
pe.parentNode.appendChild(dx);
}else{
pe.parentNode.insertBefore(dx,pe.nextSibling);
}
}else{
if((_f=="dt")||(_f=="dd")){
var pe=_e.getParentElement();
while(pe&&(pe.nodeType==1)&&(pe.tagName.toLowerCase()!="body")){
if(pe.tagName.toLowerCase()=="dl"){
var dx=_e._doc.createElement(_f);
dx.innerHTML="&nbsp;";
pe.appendChild(dx);
break;
}else{
if((pe.tagName.toLowerCase()=="dt")||(pe.tagName.toLowerCase()=="dd")){
var dx=_e._doc.createElement(_f);
dx.innerHTML="&nbsp;";
if(pe.parentNode.lastChild==pe){
pe.parentNode.appendChild(dx);
}else{
pe.parentNode.insertBefore(dx,pe.nextSibling);
}
break;
}
}
pe=pe.parentNode;
}
if(pe.tagName.toLowerCase()=="body"){
alert("You can insert a definition term or description only in a definition list!");
}
}
}
};

