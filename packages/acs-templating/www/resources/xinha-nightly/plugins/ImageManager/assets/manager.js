function i18n(_1){
return HTMLArea._lc(_1,"ImageManager");
}
function setAlign(_2){
var _3=document.getElementById("f_align");
for(var i=0;i<_3.length;i++){
if(_3.options[i].value==_2){
_3.selectedIndex=i;
break;
}
}
}
init=function(){
__dlg_init(null,{width:600,height:460});
__dlg_translate("ImageManager");
document.getElementById("f_align").selectedIndex=1;
document.getElementById("f_align").selectedIndex=0;
var _5=document.getElementById("bgCol_pick");
var _6=document.getElementById("f_backgroundColor");
var _7=new Xinha.colorPicker({cellsize:"5px",callback:function(_8){
_6.value=_8;
}});
_5.onclick=function(){
_7.open("top,right",_6);
};
var _9=document.getElementById("bdCol_pick");
var _a=document.getElementById("f_borderColor");
var _b=new Xinha.colorPicker({cellsize:"5px",callback:function(_c){
_a.value=_c;
}});
_9.onclick=function(){
_b.open("top,right",_a);
};
var _d=document.getElementById("uploadForm");
if(_d){
_d.target="imgManager";
}
var _e=window.dialogArguments;
if(_e){
var _f=new RegExp("(https?://[^/]*)?"+base_url.replace(/\/$/,""));
_e.f_url=_e.f_url.replace(_f,"");
var rd=(_resized_dir)?_resized_dir.replace(Xinha.RE_Specials,"\\$1")+"/":"";
var rp=_resized_prefix.replace(Xinha.RE_Specials,"\\$1");
var _12=new RegExp("^(.*/)"+rd+rp+"_([0-9]+)x([0-9]+)_([^/]+)$");
if(_12.test(_e.f_url)){
_e.f_url=RegExp.$1+RegExp.$4;
_e.f_width=RegExp.$2;
_e.f_height=RegExp.$3;
}
for(var id in _e){
if(id=="f_align"){
continue;
}
if(document.getElementById(id)){
document.getElementById(id).value=_e[id];
}
}
document.getElementById("orginal_width").value=_e["f_width"];
document.getElementById("orginal_height").value=_e["f_height"];
setAlign(_e["f_align"]);
var _12=new RegExp("^(.*/)([^/]+)$");
if(_12.test(_e["f_url"])){
changeDir(RegExp.$1);
var _14=document.getElementById("dirPath");
for(var i=0;i<_14.options.length;i++){
if(_14.options[i].value==encodeURIComponent(RegExp.$1)){
_14.options[i].selected=true;
break;
}
}
}
document.getElementById("f_preview").src=_backend_url+"__function=thumbs&img="+_e.f_url;
}
document.getElementById("f_alt").focus();
};
function onCancel(){
__dlg_close(null);
return false;
}
function onOK(){
var _16=["f_url","f_alt","f_align","f_width","f_height","f_padding","f_margin","f_border","f_borderColor","f_backgroundColor"];
var _17=new Object();
for(var i in _16){
var id=_16[i];
var el=document.getElementById(id);
if(id=="f_url"&&el.value.indexOf("://")<0){
if(el.value==""){
alert(i18n("No Image selected."));
return (false);
}
_17[id]=makeURL(base_url,el.value);
}else{
if(el){
_17[id]=el.value;
}else{
alert("Missing "+_16[i]);
}
}
}
var _1b={w:document.getElementById("orginal_width").value,h:document.getElementById("orginal_height").value};
if((_1b.w!=_17.f_width)||(_1b.h!=_17.f_height)){
var _1c=HTMLArea._geturlcontent(_backend_url+"&__function=resizer&img="+encodeURIComponent(document.getElementById("f_url").value)+"&width="+_17.f_width+"&height="+_17.f_height);
_1c=eval(_1c);
if(_1c){
_17.f_url=makeURL(base_url,_1c);
}
}
__dlg_close(_17);
return false;
}
function makeURL(_1d,_1e){
if(_1d.substring(_1d.length-1)!="/"){
_1d+="/";
}
if(_1e.charAt(0)=="/"){
}
_1e=_1e.substring(1);
return _1d+_1e;
}
function updateDir(_1f){
var _20=_1f.options[_1f.selectedIndex].value;
changeDir(_20);
}
function goUpDir(){
var _21=document.getElementById("dirPath");
var _22=_21.options[_21.selectedIndex].text;
if(_22.length<2){
return false;
}
var _23=_22.split("/");
var _24="";
for(var i=0;i<_23.length-2;i++){
_24+=_23[i]+"/";
}
for(var i=0;i<_21.length;i++){
var _26=_21.options[i].text;
if(_26==_24){
_21.selectedIndex=i;
var _27=_21.options[i].value;
changeDir(_27);
break;
}
}
}
function changeDir(_28){
if(typeof imgManager!="undefined"){
imgManager.changeDir(_28);
}
}
function toggleConstrains(_29){
var _2a=document.getElementById("imgLock");
var _29=document.getElementById("constrain_prop");
if(_29.checked){
_2a.src="img/locked.gif";
checkConstrains("width");
}else{
_2a.src="img/unlocked.gif";
}
}
function checkConstrains(_2b){
var _2c=document.getElementById("constrain_prop");
if(_2c.checked){
var obj=document.getElementById("orginal_width");
var _2e=parseInt(obj.value);
var obj=document.getElementById("orginal_height");
var _2f=parseInt(obj.value);
var _30=document.getElementById("f_width");
var _31=document.getElementById("f_height");
var _32=parseInt(_30.value);
var _33=parseInt(_31.value);
if(_2e>0&&_2f>0){
if(_2b=="width"&&_32>0){
_31.value=parseInt((_32/_2e)*_2f);
}
if(_2b=="height"&&_33>0){
_30.value=parseInt((_33/_2f)*_2e);
}
}
}
}
function showMessage(_34){
var _35=document.getElementById("message");
var _36=document.getElementById("messages");
if(_35.firstChild){
_35.removeChild(_35.firstChild);
}
_35.appendChild(document.createTextNode(i18n(_34)));
_36.style.display="";
}
function addEvent(obj,_38,fn){
if(obj.addEventListener){
obj.addEventListener(_38,fn,true);
return true;
}else{
if(obj.attachEvent){
var r=obj.attachEvent("on"+_38,fn);
return r;
}else{
return false;
}
}
}
function doUpload(){
var _3b=document.getElementById("uploadForm");
if(_3b){
showMessage("Uploading");
}
}
function refresh(){
var _3c=document.getElementById("dirPath");
updateDir(_3c);
}
function newFolder(){
var _3d=prompt(i18n("Please enter name for new folder..."),i18n("Untitled"));
var _3e=document.getElementById("dirPath");
var dir=_3e.options[_3e.selectedIndex].value;
if(_3d==thumbdir){
alert(i18n("Invalid folder name, please choose another folder name."));
return false;
}
if(_3d&&_3d!=""&&typeof imgManager!="undefined"){
imgManager.newFolder(dir,encodeURI(_3d));
}
}
addEvent(window,"load",init);

