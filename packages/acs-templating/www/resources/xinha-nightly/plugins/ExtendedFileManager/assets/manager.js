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
var _e=window.dialogArguments.param;
if(manager_mode=="image"&&_e){
var _f=new RegExp("^https?://");
if(_e.f_url.length>0&&!_f.test(_e.f_url)&&typeof _e.baseHref=="string"){
_e.f_url=_e.baseHref+_e.f_url;
}
var _10=new RegExp("(https?://[^/]*)?"+base_url.replace(/\/$/,""));
_e.f_url=_e.f_url.replace(_10,"");
var rd=(_resized_dir)?_resized_dir.replace(Xinha.RE_Specials,"\\$1")+"/":"";
var rp=_resized_prefix.replace(Xinha.RE_Specials,"\\$1");
var _13=new RegExp("^(.*/)"+rd+rp+"_([0-9]+)x([0-9]+)_([^/]+)$");
var _14=_e.f_url.match(_13);
if(_13.test(_e.f_url)){
_e.f_url=RegExp.$1+RegExp.$4;
_e.f_width=RegExp.$2;
_e.f_height=RegExp.$3;
}
document.getElementById("f_url").value=_e["f_url"];
document.getElementById("f_alt").value=_e["f_alt"];
document.getElementById("f_title").value=_e["f_title"];
document.getElementById("f_border").value=_e["f_border"];
document.getElementById("f_width").value=_e["f_width"];
document.getElementById("f_height").value=_e["f_height"];
document.getElementById("f_margin").value=_e["f_margin"];
document.getElementById("f_padding").value=_e["f_padding"];
document.getElementById("f_borderColor").value=_e["f_borderColor"];
document.getElementById("f_backgroundColor").value=_e["f_backgroundColor"];
setAlign(_e["f_align"]);
document.getElementById("f_url").focus();
document.getElementById("orginal_width").value=_e["f_width"];
document.getElementById("orginal_height").value=_e["f_height"];
var _13=new RegExp("^(.*/)([^/]+)$");
if(_13.test(_e["f_url"])){
changeDir(RegExp.$1);
var _15=document.getElementById("dirPath");
for(var i=0;i<_15.options.length;i++){
if(_15.options[i].value==encodeURIComponent(RegExp.$1)){
_15.options[i].selected=true;
break;
}
}
}
document.getElementById("f_preview").src=_backend_url+"__function=thumbs&img="+_e.f_url;
}else{
if(manager_mode=="link"&&_e){
var _17=document.getElementById("f_target");
var _18=true;
var _f=new RegExp("^https?://");
if(_e.f_href.length>0&&!_f.test(_e.f_href)&&typeof _e.baseHref=="string"){
_e.f_href=_e.baseHref+_e.f_href;
}
var _19=new RegExp("(https?://[^/]*)?"+base_url.replace(/\/$/,""));
_e.f_href=_e.f_href.replace(_19,"");
var _1a;
var _13=new RegExp("^(.*/)([^/]+)$");
if(_13.test(_e["f_href"])){
_1a=RegExp.$1;
}else{
_1a=document.cookie.match(/EFMStartDirlink=(.*?)(;|$)/);
if(_1a){
_1a=_1a[1];
}
}
if(_1a){
changeDir(_1a);
var _15=document.getElementById("dirPath");
for(var i=0;i<_15.options.length;i++){
if(_15.options[i].value==encodeURIComponent(RegExp.$1)){
_15.options[i].selected=true;
break;
}
}
}
if(_e){
if(typeof _e["f_usetarget"]!="undefined"){
_18=_e["f_usetarget"];
}
if(typeof _e["f_href"]!="undefined"){
document.getElementById("f_href").value=_e["f_href"];
document.getElementById("f_title").value=_e["f_title"];
comboSelectValue(_17,_e["f_target"]);
if(_17.value!=_e.f_target){
var opt=document.createElement("option");
opt.value=_e.f_target;
opt.innerHTML=opt.value;
_17.appendChild(opt);
opt.selected=true;
}
}
}
if(!_18){
document.getElementById("f_target_label").style.visibility="hidden";
document.getElementById("f_target").style.visibility="hidden";
document.getElementById("f_other_target").style.visibility="hidden";
}
var opt=document.createElement("option");
opt.value="_other";
opt.innerHTML=i18n("Other");
_17.appendChild(opt);
_17.onchange=onTargetChanged;
document.getElementById("f_href").focus();
}else{
if(!_e){
var _1a=document.cookie.match(new RegExp("EFMStartDir"+manager_mode+"=(.*?)(;|$)"));
if(_1a){
_1a=_1a[1];
changeDir(_1a);
var _15=document.getElementById("dirPath");
for(var i=0;i<_15.options.length;i++){
if(_15.options[i].value==encodeURIComponent(_1a)){
_15.options[i].selected=true;
break;
}
}
}
}
}
}
if(manager_mode=="image"&&typeof Xinha.colorPicker!="undefined"&&document.getElementById("f_backgroundColor")){
var _1c={cellsize:_d.config.colorPickerCellSize,granularity:_d.config.colorPickerGranularity,websafe:_d.config.colorPickerWebSafe,savecolors:_d.config.colorPickerSaveColors};
new Xinha.colorPicker.InputBinding(document.getElementById("f_backgroundColor"),_1c);
new Xinha.colorPicker.InputBinding(document.getElementById("f_borderColor"),_1c);
}
};
function pasteButton(_1d){
var _1e=document.getElementById("pasteBtn");
if(!_1e.firstChild){
var a=document.createElement("a");
a.href="javascript:void(0);";
var img=document.createElement("img");
img.src=window.opener._editor_url+"plugins/ExtendedFileManager/img/edit_paste.gif";
img.alt=i18n("Paste");
a.appendChild(img);
_1e.appendChild(a);
}
_1e.onclick=function(){
if(typeof imgManager!="undefined"){
imgManager.paste(_1d);
}
if(_1d.action=="moveFile"||_1d.action=="moveDir"){
this.onclick=null;
this.removeChild(this.firstChild);
}
};
switch(_1d.action){
case "copyFile":
_1e.firstChild.title=i18n("Copy \"$file="+_1d.file+"$\" from \"$dir="+decodeURIComponent(_1d.dir)+"$\" here");
break;
case "copyDir":
_1e.firstChild.title=i18n("Copy folder \"$file="+_1d.file+"$\" from \"$dir="+decodeURIComponent(_1d.dir)+"$\" here");
break;
case "moveFile":
_1e.firstChild.title=i18n("Move \"$file="+_1d.file+"$\" from \"$dir="+decodeURIComponent(_1d.dir)+"$\" here");
break;
break;
case "moveDir":
_1e.firstChild.title=i18n("Move folder \"$file="+_1d.file+"$\" from \"$dir="+decodeURIComponent(_1d.dir)+"$\" here");
break;
}
}
function onCancel(){
__dlg_close(null);
return false;
}
function onOK(){
if(manager_mode=="image"){
var _21=["f_url","f_alt","f_title","f_align","f_border","f_margin","f_padding","f_height","f_width","f_borderColor","f_backgroundColor"];
var _22=new Object();
for(var i in _21){
var id=_21[i];
var el=document.getElementById(id);
if(id=="f_url"&&el.value.indexOf("://")<0&&el.value){
_22[id]=makeURL(base_url,el.value);
}else{
_22[id]=el.value;
}
}
var _26={w:document.getElementById("orginal_width").value,h:document.getElementById("orginal_height").value};
if((_26.w!=_22.f_width)||(_26.h!=_22.f_height)){
var _27=Xinha._geturlcontent(window.opener._editor_url+"plugins/ExtendedFileManager/"+_backend_url+"&__function=resizer&img="+encodeURIComponent(document.getElementById("f_url").value)+"&width="+_22.f_width+"&height="+_22.f_height);
_27=eval(_27);
if(_27){
_22.f_url=makeURL(base_url,_27);
}
}
__dlg_close(_22);
return false;
}else{
if(manager_mode=="link"){
var _28={};
for(var i in _28){
var el=document.getElementById(i);
if(!el.value){
alert(_28[i]);
el.focus();
return false;
}
}
var _21=["f_href","f_title","f_target"];
var _22=new Object();
for(var i in _21){
var id=_21[i];
var el=document.getElementById(id);
if(id=="f_href"&&el.value.indexOf("://")<0){
_22[id]=makeURL(base_url,el.value);
}else{
_22[id]=el.value;
}
}
if(_22.f_target=="_other"){
_22.f_target=document.getElementById("f_other_target").value;
}
__dlg_close(_22);
return false;
}
}
}
function makeURL(_29,_2a){
if(_29.substring(_29.length-1)!="/"){
_29+="/";
}
if(_2a.charAt(0)=="/"){
}
_2a=_2a.substring(1);
return _29+_2a;
}
function updateDir(_2b){
var _2c=_2b.options[_2b.selectedIndex].value;
changeDir(_2c);
}
function goUpDir(){
var _2d=document.getElementById("dirPath");
var _2e=_2d.options[_2d.selectedIndex].text;
if(_2e.length<2){
return false;
}
var _2f=_2e.split("/");
var _30="";
for(var i=0;i<_2f.length-2;i++){
_30+=_2f[i]+"/";
}
for(var i=0;i<_2d.length;i++){
var _32=_2d.options[i].text;
if(_32==_30){
_2d.selectedIndex=i;
var _33=_2d.options[i].value;
changeDir(_33);
break;
}
}
}
function changeDir(_34){
if(typeof imgManager!="undefined"){
imgManager.changeDir(_34);
}
}
function updateView(){
refresh();
}
function toggleConstrains(_35){
var _36=document.getElementById("imgLock");
var _35=document.getElementById("constrain_prop");
if(_35.checked){
_36.src="img/locked.gif";
checkConstrains("width");
}else{
_36.src="img/unlocked.gif";
}
}
function checkConstrains(_37){
var _38=document.getElementById("constrain_prop");
if(_38.checked){
var obj=document.getElementById("orginal_width");
var _3a=parseInt(obj.value);
var obj=document.getElementById("orginal_height");
var _3b=parseInt(obj.value);
var _3c=document.getElementById("f_width");
var _3d=document.getElementById("f_height");
var _3e=parseInt(_3c.value);
var _3f=parseInt(_3d.value);
if(_3a>0&&_3b>0){
if(_37=="width"&&_3e>0){
_3d.value=parseInt((_3e/_3a)*_3b);
}
if(_37=="height"&&_3f>0){
_3c.value=parseInt((_3f/_3b)*_3a);
}
}
}
}
function showMessage(_40){
var _41=document.getElementById("message");
var _42=document.getElementById("messages");
if(_41.firstChild){
_41.removeChild(_41.firstChild);
}
_41.appendChild(document.createTextNode(i18n(_40)));
_42.style.display="block";
}
function addEvent(obj,_44,fn){
if(obj.addEventListener){
obj.addEventListener(_44,fn,true);
return true;
}else{
if(obj.attachEvent){
var r=obj.attachEvent("on"+_44,fn);
return r;
}else{
return false;
}
}
}
function doUpload(){
var _47=document.getElementById("uploadForm");
if(_47){
showMessage("Uploading");
}
}
function refresh(){
var _48=document.getElementById("dirPath");
updateDir(_48);
}
function newFolder(){
function createFolder(_49){
var _4a=document.getElementById("dirPath");
var dir=_4a.options[_4a.selectedIndex].value;
if(_49==thumbdir){
alert(i18n("Invalid folder name, please choose another folder name."));
return false;
}
if(_49&&_49!=""&&typeof imgManager!="undefined"){
imgManager.newFolder(dir,encodeURI(_49));
}
}
if(Xinha.ie_version>6){
popupPrompt(i18n("Please enter name for new folder..."),i18n("Untitled"),createFolder,i18n("New Folder"));
}else{
var _4c=prompt(i18n("Please enter name for new folder..."),i18n("Untitled"));
createFolder(_4c);
}
}
function resize(){
var win=Xinha.viewportSize(window);
document.getElementById("imgManager").style.height=parseInt(win.y-130-offsetForInputs,10)+"px";
return true;
}
addEvent(window,"resize",resize);
addEvent(window,"load",init);

