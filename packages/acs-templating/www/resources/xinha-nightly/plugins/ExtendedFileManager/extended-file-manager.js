function ExtendedFileManager(_1){
this.editor=_1;
var _2=_1.config;
var _3=_2.toolbar;
var _4=this;
if(_2.ExtendedFileManager.use_linker){
_2.registerButton({id:"linkfile",tooltip:Xinha._lc("Insert File Link","ExtendedFileManager"),image:_editor_url+"plugins/ExtendedFileManager/img/ed_linkfile.gif",textMode:false,action:function(_5){
_5._linkFile();
}});
_2.addToolbarElement("linkfile","createlink",1);
}
}
ExtendedFileManager._pluginInfo={name:"ExtendedFileManager",version:"1.1.1",developer:"Afru, Krzysztof Kotowicz",developer_url:"http://www.afrusoft.com/htmlarea/",license:"htmlArea"};
Xinha.Config.prototype.ExtendedFileManager={"use_linker":true,"backend":_editor_url+"plugins/ExtendedFileManager/backend.php?__plugin=ExtendedFileManager&","backend_data":null,"backend_config":null,"backend_config_hash":null,"backend_config_secret_key_location":"Xinha:ImageManager"};
Xinha.prototype._insertImage=function(_6){
var _7=this;
var _8={"editor":this,param:null};
if(typeof _6=="undefined"){
_6=this.getParentElement();
if(_6&&!/^img$/i.test(_6.tagName)){
_6=null;
}
}
if(_6){
_8.param={f_url:Xinha.is_ie?_6.src:_6.getAttribute("src"),f_alt:_6.alt,f_title:_6.title,f_border:_6.style.borderWidth?_6.style.borderWidth:_6.border,f_align:_6.align,f_width:_6.width,f_height:_6.height,f_padding:_6.style.padding,f_margin:_6.style.margin,f_backgroundColor:_6.style.backgroundColor,f_borderColor:_6.style.borderColor,baseHref:_7.config.baseHref};
_8.param.f_border=shortSize(_8.param.f_border);
_8.param.f_padding=shortSize(_8.param.f_padding);
_8.param.f_margin=shortSize(_8.param.f_margin);
_8.param.f_backgroundColor=convertToHex(_8.param.f_backgroundColor);
_8.param.f_borderColor=convertToHex(_8.param.f_borderColor);
}
var _9=_7.config.ExtendedFileManager.backend+"__function=manager";
if(_7.config.ExtendedFileManager.backend_config!=null){
_9+="&backend_config="+encodeURIComponent(_7.config.ExtendedFileManager.backend_config);
_9+="&backend_config_hash="+encodeURIComponent(_7.config.ExtendedFileManager.backend_config_hash);
_9+="&backend_config_secret_key_location="+encodeURIComponent(_7.config.ExtendedFileManager.backend_config_secret_key_location);
}
if(_7.config.ExtendedFileManager.backend_data!=null){
for(var i in _7.config.ExtendedFileManager.backend_data){
_9+="&"+i+"="+encodeURIComponent(_7.config.ExtendedFileManager.backend_data[i]);
}
}
Dialog(_9,function(_b){
if(!_b){
return false;
}
var _c=_6;
if(!_c){
if(!_b.f_url){
return false;
}
if(Xinha.is_ie){
var _d=_7.getSelection();
var _e=_7.createRange(_d);
_7._doc.execCommand("insertimage",false,_b.f_url);
_c=_e.parentElement();
if(_c.tagName.toLowerCase()!="img"){
_c=_c.previousSibling;
}
}else{
_c=document.createElement("img");
_c.src=_b.f_url;
_7.insertNodeAtSelection(_c);
}
}else{
if(!_b.f_url){
_c.parentNode.removeChild(_c);
_7.updateToolbar();
return false;
}else{
_c.src=_b.f_url;
}
}
_c.alt=_c.alt?_c.alt:"";
for(field in _b){
var _f=_b[field];
switch(field){
case "f_alt":
_c.alt=_f;
break;
case "f_title":
_c.title=_f;
break;
case "f_border":
if(_f){
_c.style.borderWidth=/[^0-9]/.test(_f)?_f:(_f!="")?(parseInt(_f)+"px"):"";
if(_c.style.borderWidth&&!_c.style.borderStyle){
_c.style.borderStyle="solid";
}else{
if(!_c.style.borderWidth){
_c.style.border="";
}
}
}
break;
case "f_borderColor":
_c.style.borderColor=_f;
break;
case "f_backgroundColor":
_c.style.backgroundColor=_f;
break;
case "f_align":
_c.align=_f;
break;
case "f_width":
_c.width=parseInt(_f||"0");
break;
case "f_height":
_c.height=parseInt(_f||"0");
break;
case "f_padding":
_c.style.padding=/[^0-9]/.test(_f)?_f:(_f!="")?(parseInt(_f)+"px"):"";
break;
case "f_margin":
_c.style.margin=/[^0-9]/.test(_f)?_f:(_f!="")?(parseInt(_f)+"px"):"";
break;
}
}
},_8);
};
Xinha.prototype._linkFile=function(_10){
var _11=this;
var _12={"editor":this,param:null};
if(typeof _10=="undefined"){
_10=this.getParentElement();
if(_10){
if(/^img$/i.test(_10.tagName)){
_10=_10.parentNode;
}
if(!/^a$/i.test(_10.tagName)){
_10=null;
}
}
}
if(!_10){
var sel=_11.getSelection();
var _14=_11.createRange(sel);
var _15=0;
if(Xinha.is_ie){
if(sel.type=="Control"){
_15=_14.length;
}else{
_15=_14.compareEndPoints("StartToEnd",_14);
}
}else{
_15=_14.compareBoundaryPoints(_14.START_TO_END,_14);
}
if(_15==0){
alert(Xinha._lc("You must select some text before making a new link.","ExtendedFileManager"));
return;
}
_12.param={f_href:"",f_title:"",f_target:"",f_usetarget:_11.config.makeLinkShowsTarget,baseHref:_11.config.baseHref};
}else{
_12.param={f_href:Xinha.is_ie?_10.href:_10.getAttribute("href"),f_title:_10.title,f_target:_10.target,f_usetarget:_11.config.makeLinkShowsTarget,baseHref:_11.config.baseHref};
}
var _16=_editor_url+"plugins/ExtendedFileManager/manager.php?mode=link";
if(_11.config.ExtendedFileManager.backend_config!=null){
_16+="&backend_config="+encodeURIComponent(_11.config.ExtendedFileManager.backend_config);
_16+="&backend_config_hash="+encodeURIComponent(_11.config.ExtendedFileManager.backend_config_hash);
_16+="&backend_config_secret_key_location="+encodeURIComponent(_11.config.ExtendedFileManager.backend_config_secret_key_location);
}
if(_11.config.ExtendedFileManager.backend_data!=null){
for(var i in _11.config.ExtendedFileManager.backend_data){
_16+="&"+i+"="+encodeURIComponent(_11.config.ExtendedFileManager.backend_data[i]);
}
}
Dialog(_16,function(_18){
if(!_18){
return false;
}
var a=_10;
if(!a){
try{
_11._doc.execCommand("createlink",false,_18.f_href);
a=_11.getParentElement();
var sel=_11.getSelection();
var _1b=_11.createRange(sel);
if(!Xinha.is_ie){
a=_1b.startContainer;
if(!/^a$/i.test(a.tagName)){
a=a.nextSibling;
if(a==null){
a=_1b.startContainer.parentNode;
}
}
}
}
catch(e){
}
}else{
var _1c=_18.f_href.trim();
_11.selectNodeContents(a);
if(_1c==""){
_11._doc.execCommand("unlink",false,null);
_11.updateToolbar();
return false;
}else{
a.href=_1c;
}
}
if(!(a&&/^a$/i.test(a.tagName))){
return false;
}
a.target=_18.f_target.trim();
a.title=_18.f_title.trim();
_11.selectNodeContents(a);
_11.updateToolbar();
},_12);
};
function shortSize(_1d){
if(/ /.test(_1d)){
var _1e=_1d.split(" ");
var _1f=true;
for(var i=1;i<_1e.length;i++){
if(_1e[0]!=_1e[i]){
_1f=false;
break;
}
}
if(_1f){
_1d=_1e[0];
}
}
return _1d;
}
function convertToHex(_21){
if(typeof _21=="string"&&/, /.test.color){
_21=_21.replace(/, /,",");
}
if(typeof _21=="string"&&/ /.test.color){
var _22=_21.split(" ");
var _23="";
for(var i=0;i<_22.length;i++){
_23+=Xinha._colorToRgb(_22[i]);
if(i+1<_22.length){
_23+=" ";
}
}
return _23;
}
return Xinha._colorToRgb(_21);
}

