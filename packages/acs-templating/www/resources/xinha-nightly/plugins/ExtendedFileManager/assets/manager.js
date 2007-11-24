/* This compressed file is part of Xinha. For uncomressed sources, forum, and bug reports, go to xinha.org */
function comboSelectValue(c,_2){
var _3=c.getElementsByTagName("option");
for(var i=_3.length;--i>=0;){
var op=_3[i];
op.selected=(op.value==_2);
}
c.value=_2;
}
function i18n(_6){
return Xinha._lc(_6,"ExtendedFileManager");
}
function setAlign(_7){
var _8=document.getElementById("f_align");
for(var i=0;i<_8.length;i++){
if(_8.options[i].value==_7){
_8.selectedIndex=i;
break;
}
}
}
function onTargetChanged(){
var f=document.getElementById("f_other_target");
if(this.value=="_other"){
f.style.visibility="visible";
f.select();
f.focus();
}else{
f.style.visibility="hidden";
}
}
if(manager_mode=="link"){
var offsetForInputs=(Xinha.is_ie)?165:150;
}else{
var offsetForInputs=(Xinha.is_ie)?230:210;
}
var h=100+250+offsetForInputs;
var win_dim={width:650,height:h};
window.resizeTo(win_dim.width,win_dim.height);
if(!Xinha.is_ie){
var x=opener.screenX+(opener.outerWidth-win_dim.width)/2;
var y=opener.screenY+(opener.outerHeight-win_dim.height)/2;
}else{
var x=(self.screen.availWidth-win_dim.width)/2;
var y=(self.screen.availHeight-win_dim.height)/2;
}
window.moveTo(x,y);
init=function(){
__dlg_init(null,{width:650,height:h});
__dlg_translate("ExtendedFileManager");
var _b=document.getElementById("uploadForm");
if(_b){
_b.target="imgManager";
}
var _c=window.dialogArguments.editor;
var _d=window.dialogArguments.param;
if(manager_mode=="image"&&_d){
var _e=new RegExp("^https?://");
if(_d.f_url.length>0&&!_e.test(_d.f_url)&&typeof _d.baseHref=="string"){
_d.f_url=_d.baseHref+_d.f_url;
}
var _f=new RegExp("(https?://[^/]*)?"+base_url.replace(/\/$/,""));
_d.f_url=_d.f_url.replace(_f,"");
var rd=(_resized_dir)?_resized_dir.replace(Xinha.RE_Specials,"\\$1")+"/":"";
var rp=_resized_prefix.replace(Xinha.RE_Specials,"\\$1");
var _12=new RegExp("^(.*/)"+rd+rp+"_([0-9]+)x([0-9]+)_([^/]+)$");
var _13=_d.f_url.match(_12);
if(_12.test(_d.f_url)){
_d.f_url=RegExp.$1+RegExp.$4;
_d.f_width=RegExp.$2;
_d.f_height=RegExp.$3;
}
document.getElementById("f_url").value=_d["f_url"];
document.getElementById("f_alt").value=_d["f_alt"];
document.getElementById("f_title").value=_d["f_title"];
document.getElementById("f_border").value=_d["f_border"];
document.getElementById("f_width").value=_d["f_width"];
document.getElementById("f_height").value=_d["f_height"];
document.getElementById("f_margin").value=_d["f_margin"];
document.getElementById("f_padding").value=_d["f_padding"];
document.getElementById("f_borderColor").value=_d["f_borderColor"];
document.getElementById("f_backgroundColor").value=_d["f_backgroundColor"];
setAlign(_d["f_align"]);
document.getElementById("f_url").focus();
document.getElementById("orginal_width").value=_d["f_width"];
document.getElementById("orginal_height").value=_d["f_height"];
var _12=new RegExp("^(.*/)([^/]+)$");
if(_12.test(_d["f_url"])){
changeDir(RegExp.$1);
var _14=document.getElementById("dirPath");
for(var i=0;i<_14.options.length;i++){
if(_14.options[i].value==encodeURIComponent(RegExp.$1)){
_14.options[i].selected=true;
break;
}
}
}
document.getElementById("f_preview").src=_backend_url+"__function=thumbs&img="+_d.f_url;
}else{
if(manager_mode=="link"&&_d){
var _16=document.getElementById("f_target");
var _17=true;
var _e=new RegExp("^https?://");
if(_d.f_href.length>0&&!_e.test(_d.f_href)&&typeof _d.baseHref=="string"){
_d.f_href=_d.baseHref+_d.f_href;
}
var _18=new RegExp("(https?://[^/]*)?"+base_url.replace(/\/$/,""));
_d.f_href=_d.f_href.replace(_18,"");
var _19;
var _12=new RegExp("^(.*/)([^/]+)$");
if(_12.test(_d["f_href"])){
_19=RegExp.$1;
}else{
_19=document.cookie.match(/EFMStartDirlink=(.*?)(;|$)/);
if(_19){
_19=_19[1];
}
}
if(_19){
changeDir(_19);
var _14=document.getElementById("dirPath");
for(var i=0;i<_14.options.length;i++){
if(_14.options[i].value==encodeURIComponent(RegExp.$1)){
_14.options[i].selected=true;
break;
}
}
}
if(_d){
if(typeof _d["f_usetarget"]!="undefined"){
_17=_d["f_usetarget"];
}
if(typeof _d["f_href"]!="undefined"){
document.getElementById("f_href").value=_d["f_href"];
document.getElementById("f_title").value=_d["f_title"];
comboSelectValue(_16,_d["f_target"]);
if(_16.value!=_d.f_target){
var opt=document.createElement("option");
opt.value=_d.f_target;
opt.innerHTML=opt.value;
_16.appendChild(opt);
opt.selected=true;
}
}
}
if(!_17){
document.getElementById("f_target_label").style.visibility="hidden";
document.getElementById("f_target").style.visibility="hidden";
document.getElementById("f_other_target").style.visibility="hidden";
}
var opt=document.createElement("option");
opt.value="_other";
opt.innerHTML=i18n("Other");
_16.appendChild(opt);
_16.onchange=onTargetChanged;
document.getElementById("f_href").focus();
}else{
if(!_d){
var _19=document.cookie.match(new RegExp("EFMStartDir"+manager_mode+"=(.*?)(;|$)"));
if(_19){
_19=_19[1];
changeDir(_19);
var _14=document.getElementById("dirPath");
for(var i=0;i<_14.options.length;i++){
if(_14.options[i].value==encodeURIComponent(_19)){
_14.options[i].selected=true;
break;
}
}
}
}
}
}
if(manager_mode=="image"&&typeof Xinha.colorPicker!="undefined"&&document.getElementById("f_backgroundColor")&&document.getElementById("f_backgroundColor").type=="text"){
var _1b={cellsize:_c.config.colorPickerCellSize,granularity:_c.config.colorPickerGranularity,websafe:_c.config.colorPickerWebSafe,savecolors:_c.config.colorPickerSaveColors};
new Xinha.colorPicker.InputBinding(document.getElementById("f_backgroundColor"),_1b);
new Xinha.colorPicker.InputBinding(document.getElementById("f_borderColor"),_1b);
}
};
function pasteButton(_1c){
var _1d=document.getElementById("pasteBtn");
if(!_1d.firstChild){
var a=document.createElement("a");
a.href="javascript:void(0);";
var img=document.createElement("img");
img.src=window.opener._editor_url+"plugins/ExtendedFileManager/img/edit_paste.gif";
img.alt=i18n("Paste");
a.appendChild(img);
_1d.appendChild(a);
}
_1d.onclick=function(){
if(typeof imgManager!="undefined"){
imgManager.paste(_1c);
}
if(_1c.action=="moveFile"||_1c.action=="moveDir"){
this.onclick=null;
this.removeChild(this.firstChild);
}
};
switch(_1c.action){
case "copyFile":
_1d.firstChild.title=i18n("Copy \"$file="+_1c.file+"$\" from \"$dir="+decodeURIComponent(_1c.dir)+"$\" here");
break;
case "copyDir":
_1d.firstChild.title=i18n("Copy folder \"$file="+_1c.file+"$\" from \"$dir="+decodeURIComponent(_1c.dir)+"$\" here");
break;
case "moveFile":
_1d.firstChild.title=i18n("Move \"$file="+_1c.file+"$\" from \"$dir="+decodeURIComponent(_1c.dir)+"$\" here");
break;
break;
case "moveDir":
_1d.firstChild.title=i18n("Move folder \"$file="+_1c.file+"$\" from \"$dir="+decodeURIComponent(_1c.dir)+"$\" here");
break;
}
}
function onCancel(){
__dlg_close(null);
return false;
}
function onOK(){
if(manager_mode=="image"){
var _20=["f_url","f_alt","f_title","f_align","f_border","f_margin","f_padding","f_height","f_width","f_borderColor","f_backgroundColor"];
var _21=new Object();
for(var i in _20){
var id=_20[i];
var el=document.getElementById(id);
if(id=="f_url"&&el.value.indexOf("://")<0&&el.value){
_21[id]=makeURL(base_url,el.value);
}else{
_21[id]=el.value;
}
}
var _25={w:document.getElementById("orginal_width").value,h:document.getElementById("orginal_height").value};
if((_25.w!=_21.f_width)||(_25.h!=_21.f_height)){
var _26=Xinha._geturlcontent(window.opener._editor_url+"plugins/ExtendedFileManager/"+_backend_url+"&__function=resizer&img="+encodeURIComponent(document.getElementById("f_url").value)+"&width="+_21.f_width+"&height="+_21.f_height);
_26=eval(_26);
if(_26){
_21.f_url=makeURL(base_url,_26);
}
}
__dlg_close(_21);
return false;
}else{
if(manager_mode=="link"){
var _27={};
for(var i in _27){
var el=document.getElementById(i);
if(!el.value){
alert(_27[i]);
el.focus();
return false;
}
}
var _20=["f_href","f_title","f_target"];
var _21=new Object();
for(var i in _20){
var id=_20[i];
var el=document.getElementById(id);
if(id=="f_href"&&el.value.indexOf("://")<0){
_21[id]=makeURL(base_url,el.value);
}else{
_21[id]=el.value;
}
}
if(_21.f_target=="_other"){
_21.f_target=document.getElementById("f_other_target").value;
}
__dlg_close(_21);
return false;
}
}
}
function makeURL(_28,_29){
if(_28.substring(_28.length-1)!="/"){
_28+="/";
}
if(_29.charAt(0)=="/"){
}
_29=_29.substring(1);
return _28+_29;
}
function updateDir(_2a){
var _2b=_2a.options[_2a.selectedIndex].value;
changeDir(_2b);
}
function goUpDir(){
var _2c=document.getElementById("dirPath");
var _2d=_2c.options[_2c.selectedIndex].text;
if(_2d.length<2){
return false;
}
var _2e=_2d.split("/");
var _2f="";
for(var i=0;i<_2e.length-2;i++){
_2f+=_2e[i]+"/";
}
for(var i=0;i<_2c.length;i++){
var _31=_2c.options[i].text;
if(_31==_2f){
_2c.selectedIndex=i;
var _32=_2c.options[i].value;
changeDir(_32);
break;
}
}
}
function changeDir(_33){
if(typeof imgManager!="undefined"){
imgManager.changeDir(_33);
}
}
function updateView(){
refresh();
}
function toggleConstrains(_34){
var _35=document.getElementById("imgLock");
var _34=document.getElementById("constrain_prop");
if(_34.checked){
_35.src="img/locked.gif";
checkConstrains("width");
}else{
_35.src="img/unlocked.gif";
}
}
function checkConstrains(_36){
var _37=document.getElementById("constrain_prop");
if(_37.checked){
var obj=document.getElementById("orginal_width");
var _39=parseInt(obj.value);
var obj=document.getElementById("orginal_height");
var _3a=parseInt(obj.value);
var _3b=document.getElementById("f_width");
var _3c=document.getElementById("f_height");
var _3d=parseInt(_3b.value);
var _3e=parseInt(_3c.value);
if(_39>0&&_3a>0){
if(_36=="width"&&_3d>0){
_3c.value=parseInt((_3d/_39)*_3a);
}
if(_36=="height"&&_3e>0){
_3b.value=parseInt((_3e/_3a)*_39);
}
}
}
}
function showMessage(_3f){
var _40=document.getElementById("message");
var _41=document.getElementById("messages");
if(_40.firstChild){
_40.removeChild(_40.firstChild);
}
_40.appendChild(document.createTextNode(i18n(_3f)));
_41.style.display="block";
}
function addEvent(obj,_43,fn){
if(obj.addEventListener){
obj.addEventListener(_43,fn,true);
return true;
}else{
if(obj.attachEvent){
var r=obj.attachEvent("on"+_43,fn);
return r;
}else{
return false;
}
}
}
function doUpload(){
var _46=document.getElementById("uploadForm");
if(_46){
showMessage("Uploading");
}
}
function refresh(){
var _47=document.getElementById("dirPath");
updateDir(_47);
}
function newFolder(){
function createFolder(_48){
var _49=document.getElementById("dirPath");
var dir=_49.options[_49.selectedIndex].value;
if(_48==thumbdir){
alert(i18n("Invalid folder name, please choose another folder name."));
return false;
}
if(_48&&_48!=""&&typeof imgManager!="undefined"){
imgManager.newFolder(dir,encodeURI(_48));
}
}
if(Xinha.ie_version>6){
popupPrompt(i18n("Please enter name for new folder..."),i18n("Untitled"),createFolder,i18n("New Folder"));
}else{
var _4b=prompt(i18n("Please enter name for new folder..."),i18n("Untitled"));
createFolder(_4b);
}
}
function resize(){
var win=Xinha.viewportSize(window);
document.getElementById("imgManager").style.height=parseInt(win.y-130-offsetForInputs,10)+"px";
return true;
}
addEvent(window,"resize",resize);
if(Xinha.is_gecko){
document.addEventListener("DOMContentLoaded",init,false);
}else{
addEvent(window,"load",init);
}

