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
init=function(){
var h=100+250+offsetForInputs;
__dlg_init(null,{width:650,height:h});
__dlg_translate("ExtendedFileManager");
var _c=document.getElementById("uploadForm");
if(_c){
_c.target="imgManager";
}
var _d=window.dialogArguments.editor;
if(manager_mode=="image"&&typeof Xinha.colorPicker!="undefined"&&document.getElementById("bgCol_pick")){
var _e={cellsize:_d.config.colorPickerCellSize,granularity:_d.config.colorPickerGranularity,websafe:_d.config.colorPickerWebSafe,savecolors:_d.config.colorPickerSaveColors};
var _f=document.getElementById("bgCol_pick");
var _10=document.getElementById("f_backgroundColor");
_e.callback=function(_11){
_10.value=_11;
};
var _12=new Xinha.colorPicker(_e);
_f.onclick=function(){
_12.open("top,right",_10);
};
var _13=document.getElementById("bdCol_pick");
var _14=document.getElementById("f_borderColor");
_e.callback=function(_15){
_14.value=_15;
};
var _16=new Xinha.colorPicker(_e);
_13.onclick=function(){
_16.open("top,right",_14);
};
}
var _17=window.dialogArguments.param;
if(manager_mode=="image"&&_17){
var _18=new RegExp("^https?://");
if(_17.f_url.length>0&&!_18.test(_17.f_url)&&typeof _17.baseHref=="string"){
_17.f_url=_17.baseHref+_17.f_url;
}
var _19=new RegExp("(https?://[^/]*)?"+base_url.replace(/\/$/,""));
_17.f_url=_17.f_url.replace(_19,"");
var rd=(_resized_dir)?_resized_dir.replace(Xinha.RE_Specials,"\\$1")+"/":"";
var rp=_resized_prefix.replace(Xinha.RE_Specials,"\\$1");
var _1c=new RegExp("^(.*/)"+rd+rp+"_([0-9]+)x([0-9]+)_([^/]+)$");
var _1d=_17.f_url.match(_1c);
if(_1c.test(_17.f_url)){
_17.f_url=RegExp.$1+RegExp.$4;
_17.f_width=RegExp.$2;
_17.f_height=RegExp.$3;
}
document.getElementById("f_url").value=_17["f_url"];
document.getElementById("f_alt").value=_17["f_alt"];
document.getElementById("f_title").value=_17["f_title"];
document.getElementById("f_border").value=_17["f_border"];
document.getElementById("f_width").value=_17["f_width"];
document.getElementById("f_height").value=_17["f_height"];
document.getElementById("f_margin").value=_17["f_margin"];
document.getElementById("f_padding").value=_17["f_padding"];
document.getElementById("f_borderColor").value=_17["f_borderColor"];
document.getElementById("f_backgroundColor").value=_17["f_backgroundColor"];
setAlign(_17["f_align"]);
document.getElementById("f_url").focus();
document.getElementById("orginal_width").value=_17["f_width"];
document.getElementById("orginal_height").value=_17["f_height"];
var _1c=new RegExp("^(.*/)([^/]+)$");
if(_1c.test(_17["f_url"])){
changeDir(RegExp.$1);
var _1e=document.getElementById("dirPath");
for(var i=0;i<_1e.options.length;i++){
if(_1e.options[i].value==encodeURIComponent(RegExp.$1)){
_1e.options[i].selected=true;
break;
}
}
}
document.getElementById("f_preview").src=_backend_url+"__function=thumbs&img="+_17.f_url;
}else{
if(manager_mode=="link"&&_17){
var _20=document.getElementById("f_target");
var _21=true;
var _18=new RegExp("^https?://");
if(_17.f_href.length>0&&!_18.test(_17.f_href)&&typeof _17.baseHref=="string"){
_17.f_href=_17.baseHref+_17.f_href;
}
var _22=new RegExp("(https?://[^/]*)?"+base_url.replace(/\/$/,""));
_17.f_href=_17.f_href.replace(_22,"");
var _23;
var _1c=new RegExp("^(.*/)([^/]+)$");
if(_1c.test(_17["f_href"])){
_23=RegExp.$1;
}else{
_23=document.cookie.match(/EFMStartDirlink=(.*?)(;|$)/);
if(_23){
_23=_23[1];
}
}
if(_23){
changeDir(_23);
var _1e=document.getElementById("dirPath");
for(var i=0;i<_1e.options.length;i++){
if(_1e.options[i].value==encodeURIComponent(RegExp.$1)){
_1e.options[i].selected=true;
break;
}
}
}
if(_17){
if(typeof _17["f_usetarget"]!="undefined"){
_21=_17["f_usetarget"];
}
if(typeof _17["f_href"]!="undefined"){
document.getElementById("f_href").value=_17["f_href"];
document.getElementById("f_title").value=_17["f_title"];
comboSelectValue(_20,_17["f_target"]);
if(_20.value!=_17.f_target){
var opt=document.createElement("option");
opt.value=_17.f_target;
opt.innerHTML=opt.value;
_20.appendChild(opt);
opt.selected=true;
}
}
}
if(!_21){
document.getElementById("f_target_label").style.visibility="hidden";
document.getElementById("f_target").style.visibility="hidden";
document.getElementById("f_other_target").style.visibility="hidden";
}
var opt=document.createElement("option");
opt.value="_other";
opt.innerHTML=i18n("Other");
_20.appendChild(opt);
_20.onchange=onTargetChanged;
document.getElementById("f_href").focus();
}else{
if(!_17){
var _23=document.cookie.match(new RegExp("EFMStartDir"+manager_mode+"=(.*?)(;|$)"));
if(_23){
_23=_23[1];
changeDir(_23);
var _1e=document.getElementById("dirPath");
for(var i=0;i<_1e.options.length;i++){
if(_1e.options[i].value==encodeURIComponent(_23)){
_1e.options[i].selected=true;
break;
}
}
}
}
}
}
};
function pasteButton(_25){
var _26=document.getElementById("pasteBtn");
if(!_26.firstChild){
var a=document.createElement("a");
a.href="javascript:void(0);";
var img=document.createElement("img");
img.src=window.opener._editor_url+"plugins/ExtendedFileManager/img/edit_paste.gif";
img.alt=i18n("Paste");
a.appendChild(img);
_26.appendChild(a);
}
_26.onclick=function(){
if(typeof imgManager!="undefined"){
imgManager.paste(_25);
}
if(_25.action=="moveFile"||_25.action=="moveDir"){
this.onclick=null;
this.removeChild(this.firstChild);
}
};
switch(_25.action){
case "copyFile":
_26.firstChild.title=i18n("Copy \"$file="+_25.file+"$\" from \"$dir="+decodeURIComponent(_25.dir)+"$\" here");
break;
case "copyDir":
_26.firstChild.title=i18n("Copy folder \"$file="+_25.file+"$\" from \"$dir="+decodeURIComponent(_25.dir)+"$\" here");
break;
case "moveFile":
_26.firstChild.title=i18n("Move \"$file="+_25.file+"$\" from \"$dir="+decodeURIComponent(_25.dir)+"$\" here");
break;
break;
case "moveDir":
_26.firstChild.title=i18n("Move folder \"$file="+_25.file+"$\" from \"$dir="+decodeURIComponent(_25.dir)+"$\" here");
break;
}
}
function onCancel(){
__dlg_close(null);
return false;
}
function onOK(){
if(manager_mode=="image"){
var _29=["f_url","f_alt","f_title","f_align","f_border","f_margin","f_padding","f_height","f_width","f_borderColor","f_backgroundColor"];
var _2a=new Object();
for(var i in _29){
var id=_29[i];
var el=document.getElementById(id);
if(id=="f_url"&&el.value.indexOf("://")<0&&el.value){
_2a[id]=makeURL(base_url,el.value);
}else{
_2a[id]=el.value;
}
}
var _2e={w:document.getElementById("orginal_width").value,h:document.getElementById("orginal_height").value};
if((_2e.w!=_2a.f_width)||(_2e.h!=_2a.f_height)){
var _2f=Xinha._geturlcontent(window.opener._editor_url+"plugins/ExtendedFileManager/"+_backend_url+"&__function=resizer&img="+encodeURIComponent(document.getElementById("f_url").value)+"&width="+_2a.f_width+"&height="+_2a.f_height);
_2f=eval(_2f);
if(_2f){
_2a.f_url=makeURL(base_url,_2f);
}
}
__dlg_close(_2a);
return false;
}else{
if(manager_mode=="link"){
var _30={};
for(var i in _30){
var el=document.getElementById(i);
if(!el.value){
alert(_30[i]);
el.focus();
return false;
}
}
var _29=["f_href","f_title","f_target"];
var _2a=new Object();
for(var i in _29){
var id=_29[i];
var el=document.getElementById(id);
if(id=="f_href"&&el.value.indexOf("://")<0){
_2a[id]=makeURL(base_url,el.value);
}else{
_2a[id]=el.value;
}
}
if(_2a.f_target=="_other"){
_2a.f_target=document.getElementById("f_other_target").value;
}
__dlg_close(_2a);
return false;
}
}
}
function makeURL(_31,_32){
if(_31.substring(_31.length-1)!="/"){
_31+="/";
}
if(_32.charAt(0)=="/"){
}
_32=_32.substring(1);
return _31+_32;
}
function updateDir(_33){
var _34=_33.options[_33.selectedIndex].value;
changeDir(_34);
}
function goUpDir(){
var _35=document.getElementById("dirPath");
var _36=_35.options[_35.selectedIndex].text;
if(_36.length<2){
return false;
}
var _37=_36.split("/");
var _38="";
for(var i=0;i<_37.length-2;i++){
_38+=_37[i]+"/";
}
for(var i=0;i<_35.length;i++){
var _3a=_35.options[i].text;
if(_3a==_38){
_35.selectedIndex=i;
var _3b=_35.options[i].value;
changeDir(_3b);
break;
}
}
}
function changeDir(_3c){
if(typeof imgManager!="undefined"){
imgManager.changeDir(_3c);
}
}
function updateView(){
refresh();
}
function toggleConstrains(_3d){
var _3e=document.getElementById("imgLock");
var _3d=document.getElementById("constrain_prop");
if(_3d.checked){
_3e.src="img/locked.gif";
checkConstrains("width");
}else{
_3e.src="img/unlocked.gif";
}
}
function checkConstrains(_3f){
var _40=document.getElementById("constrain_prop");
if(_40.checked){
var obj=document.getElementById("orginal_width");
var _42=parseInt(obj.value);
var obj=document.getElementById("orginal_height");
var _43=parseInt(obj.value);
var _44=document.getElementById("f_width");
var _45=document.getElementById("f_height");
var _46=parseInt(_44.value);
var _47=parseInt(_45.value);
if(_42>0&&_43>0){
if(_3f=="width"&&_46>0){
_45.value=parseInt((_46/_42)*_43);
}
if(_3f=="height"&&_47>0){
_44.value=parseInt((_47/_43)*_42);
}
}
}
}
function showMessage(_48){
var _49=document.getElementById("message");
var _4a=document.getElementById("messages");
if(_49.firstChild){
_49.removeChild(_49.firstChild);
}
_49.appendChild(document.createTextNode(i18n(_48)));
_4a.style.display="block";
}
function addEvent(obj,_4c,fn){
if(obj.addEventListener){
obj.addEventListener(_4c,fn,true);
return true;
}else{
if(obj.attachEvent){
var r=obj.attachEvent("on"+_4c,fn);
return r;
}else{
return false;
}
}
}
function doUpload(){
var _4f=document.getElementById("uploadForm");
if(_4f){
showMessage("Uploading");
}
}
function refresh(){
var _50=document.getElementById("dirPath");
updateDir(_50);
}
function newFolder(){
var _51=prompt(i18n("Please enter name for new folder..."),i18n("Untitled"));
var _52=document.getElementById("dirPath");
var dir=_52.options[_52.selectedIndex].value;
if(_51==thumbdir){
alert(i18n("Invalid folder name, please choose another folder name."));
return false;
}
if(_51&&_51!=""&&typeof imgManager!="undefined"){
imgManager.newFolder(dir,encodeURI(_51));
}
}
function resize(){
var win=Xinha.viewportSize(window);
document.getElementById("imgManager").style.height=parseInt(win.y-130-offsetForInputs,10)+"px";
return true;
}
addEvent(window,"resize",resize);
addEvent(window,"load",init);

