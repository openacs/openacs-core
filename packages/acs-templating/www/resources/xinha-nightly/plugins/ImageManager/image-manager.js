function ImageManager(_1){
}
ImageManager._pluginInfo={name:"ImageManager",version:"1.0",developer:"Xiang Wei Zhuo",developer_url:"http://www.zhuo.org/htmlarea/",license:"htmlArea"};
HTMLArea.Config.prototype.ImageManager={"backend":_editor_url+"plugins/ImageManager/backend.php?__plugin=ImageManager&","backend_data":null,"backend_config":null,"backend_config_hash":null,"backend_config_secret_key_location":"Xinha:ImageManager"};
HTMLArea.prototype._insertImage=function(_2){
var _3=this;
var _4=null;
if(typeof _2=="undefined"){
_2=this.getParentElement();
if(_2&&!/^img$/i.test(_2.tagName)){
_2=null;
}
}
if(_2){
_4={f_url:HTMLArea.is_ie?_2.src:_2.src,f_alt:_2.alt,f_border:_2.style.borderWidth?_2.style.borderWidth:_2.border,f_align:_2.align,f_padding:_2.style.padding,f_margin:_2.style.margin,f_width:_2.width,f_height:_2.height,f_backgroundColor:_2.style.backgroundColor,f_borderColor:_2.style.borderColor};
function shortSize(_5){
if(/ /.test(_5)){
var _6=_5.split(" ");
var _7=true;
for(var i=1;i<_6.length;i++){
if(_6[0]!=_6[i]){
_7=false;
break;
}
}
if(_7){
_5=_6[0];
}
}
return _5;
}
_4.f_border=shortSize(_4.f_border);
_4.f_padding=shortSize(_4.f_padding);
_4.f_margin=shortSize(_4.f_margin);
}
var _9=_3.config.ImageManager.backend+"__function=manager";
if(_3.config.ImageManager.backend_config!=null){
_9+="&backend_config="+encodeURIComponent(_3.config.ImageManager.backend_config);
_9+="&backend_config_hash="+encodeURIComponent(_3.config.ImageManager.backend_config_hash);
_9+="&backend_config_secret_key_location="+encodeURIComponent(_3.config.ImageManager.backend_config_secret_key_location);
}
if(_3.config.ImageManager.backend_data!=null){
for(var i in _3.config.ImageManager.backend_data){
_9+="&"+i+"="+encodeURIComponent(_3.config.ImageManager.backend_data[i]);
}
}
Dialog(_9,function(_b){
if(!_b){
return false;
}
var _c=_2;
if(!_c){
if(HTMLArea.is_ie){
var _d=_3._getSelection();
var _e=_3._createRange(_d);
_3._doc.execCommand("insertimage",false,_b.f_url);
_c=_e.parentElement();
if(_c.tagName.toLowerCase()!="img"){
_c=_c.previousSibling;
}
}else{
_c=document.createElement("img");
_c.src=_b.f_url;
_3.insertNodeAtSelection(_c);
}
}else{
_c.src=_b.f_url;
}
for(field in _b){
var _f=_b[field];
switch(field){
case "f_alt":
_c.alt=_f;
break;
case "f_border":
if(_f.length){
_c.style.borderWidth=/[^0-9]/.test(_f)?_f:(parseInt(_f)+"px");
if(_c.style.borderWidth&&!_c.style.borderStyle){
_c.style.borderStyle="solid";
}
}else{
_c.style.borderWidth="";
_c.style.borderStyle="";
}
break;
case "f_borderColor":
_c.style.borderColor=_f;
break;
case "f_backgroundColor":
_c.style.backgroundColor=_f;
break;
case "f_padding":
if(_f.length){
_c.style.padding=/[^0-9]/.test(_f)?_f:(parseInt(_f)+"px");
}else{
_c.style.padding="";
}
break;
case "f_margin":
if(_f.length){
_c.style.margin=/[^0-9]/.test(_f)?_f:(parseInt(_f)+"px");
}else{
_c.style.margin="";
}
break;
case "f_align":
_c.align=_f;
break;
case "f_width":
if(!isNaN(parseInt(_f))){
_c.width=parseInt(_f);
}else{
_c.width="";
}
break;
case "f_height":
if(!isNaN(parseInt(_f))){
_c.height=parseInt(_f);
}else{
_c.height="";
}
break;
}
}
},_4);
};

