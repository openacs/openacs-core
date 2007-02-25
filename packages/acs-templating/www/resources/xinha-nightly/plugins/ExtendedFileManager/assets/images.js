function i18n(_1){
return Xinha._lc(_1,"ExtendedFileManager");
}
function changeDir(_2){
showMessage("Loading");
var _3=window.top.document.getElementById("manager_mode").value;
var _4=window.top.document.getElementById("viewtype");
var _5=_4.options[_4.selectedIndex].value;
location.href=_backend_url+"__function=images&mode="+_3+"&dir="+_2+"&viewtype="+_5;
document.cookie="EFMStartDir"+_3+"="+_2;
}
function newFolder(_6,_7){
var _8=window.top.document.getElementById("manager_mode").value;
var _9=window.top.document.getElementById("viewtype");
var _a=_9.options[_9.selectedIndex].value;
location.href=_backend_url+"__function=images&mode="+_8+"&dir="+_6+"&newDir="+_7+"&viewtype="+_a;
}
function renameFile(_b){
var _c=_b.replace(/.*%2F/,"").replace(/\..*$/,"");
var _d=prompt(i18n("Please enter new name for this file..."),_c);
if(_d==""||_d==null||_d==_c){
alert(i18n("Cancelled rename."));
return false;
}
var _e=window.top.document.getElementById("manager_mode").value;
var _f=window.top.document.getElementById("dirPath");
var dir=_f.options[_f.selectedIndex].value;
_f=window.top.document.getElementById("viewtype");
var _11=_f.options[_f.selectedIndex].value;
location.href=_backend_url+"__function=images&mode="+_e+"&dir="+dir+"&rename="+_b+"&renameTo="+_d+"&viewtype="+_11;
}
function renameDir(_12){
var _13=prompt(i18n("Please enter new name for this folder..."),_12);
if(_13==""||_13==null||_13==_12){
alert(i18n("Cancelled rename."));
return false;
}
var _14=window.top.document.getElementById("manager_mode").value;
var _15=window.top.document.getElementById("dirPath");
var dir=_15.options[_15.selectedIndex].value;
_15=window.top.document.getElementById("viewtype");
var _17=_15.options[_15.selectedIndex].value;
location.href=_backend_url+"__function=images&mode="+_14+"&dir="+dir+"&rename="+_12+"&renameTo="+_13+"&viewtype="+_17;
}
function copyFile(_18,_19){
var _1a=window.top.document.getElementById("dirPath");
var dir=_1a.options[_1a.selectedIndex].value;
window.top.pasteButton({"dir":dir,"file":_18,"action":_19+"File"});
}
function copyDir(_1c,_1d){
var _1e=window.top.document.getElementById("dirPath");
var dir=_1e.options[_1e.selectedIndex].value;
window.top.pasteButton({"dir":dir,"file":_1c,"action":_1d+"Dir"});
}
function paste(_20){
var _21=window.top.document.getElementById("manager_mode").value;
var _22=window.top.document.getElementById("dirPath");
var dir=_22.options[_22.selectedIndex].value;
_22=window.top.document.getElementById("viewtype");
var _24=_22.options[_22.selectedIndex].value;
location.href=_backend_url+"__function=images&mode="+_21+"&dir="+dir+"&paste="+_20.action+"&srcdir="+_20.dir+"&file="+_20.file+"&viewtype="+_24;
}
function updateDir(_25){
var _26=window.top.document.getElementById("manager_mode").value;
document.cookie="EFMStartDir"+_26+"="+_25;
var _27=window.top.document.getElementById("dirPath");
if(_27){
for(var i=0;i<_27.length;i++){
var _29=_27.options[i].text;
if(_29==_25){
_27.selectedIndex=i;
showMessage("Loading");
break;
}
}
}
}
function emptyProperties(){
toggleImageProperties(false);
var _2a=window.top.document;
_2a.getElementById("f_url").value="";
_2a.getElementById("f_alt").value="";
_2a.getElementById("f_title").value="";
_2a.getElementById("f_width").value="";
_2a.getElementById("f_margin").value="";
_2a.getElementById("f_height").value="";
_2a.getElementById("f_padding").value="";
_2a.getElementById("f_border").value="";
_2a.getElementById("f_borderColor").value="";
_2a.getElementById("f_backgroundColor").value="";
}
function toggleImageProperties(val){
var _2c=window.top.document;
if(val==true){
_2c.getElementById("f_width").value="";
_2c.getElementById("f_margin").value="";
_2c.getElementById("f_height").value="";
_2c.getElementById("f_padding").value="";
_2c.getElementById("f_border").value="";
_2c.getElementById("f_borderColor").value="";
_2c.getElementById("f_backgroundColor").value="";
}
_2c.getElementById("f_width").disabled=val;
_2c.getElementById("f_margin").disabled=val;
_2c.getElementById("f_height").disabled=val;
_2c.getElementById("f_padding").disabled=val;
_2c.getElementById("f_align").disabled=val;
_2c.getElementById("f_border").disabled=val;
_2c.getElementById("f_borderColor").value="";
_2c.getElementById("f_backgroundColor").value="";
_2c.getElementById("constrain_prop").disabled=val;
}
function selectImage(_2d,alt,_2f,_30){
var _31=window.top.document;
if(_31.getElementById("manager_mode").value=="image"){
var obj=_31.getElementById("f_url");
obj.value=_2d;
obj=_31.getElementById("f_alt");
obj.value=alt;
obj=_31.getElementById("f_title");
obj.value=alt;
if(_2f==0&&_30==0){
toggleImageProperties(true);
}else{
toggleImageProperties(false);
var obj=_31.getElementById("f_width");
obj.value=_2f;
var obj=_31.getElementById("f_height");
obj.value=_30;
var obj=_31.getElementById("orginal_width");
obj.value=_2f;
var obj=_31.getElementById("orginal_height");
obj.value=_30;
update_selected();
}
}else{
if(_31.getElementById("manager_mode").value=="link"){
var obj=_31.getElementById("f_href");
obj.value=_2d;
var obj=_31.getElementById("f_title");
obj.value=alt;
}
}
return false;
}
var _current_selected=null;
function update_selected(){
var _33=window.top.document;
if(_current_selected){
_current_selected.className=_current_selected.className.replace(/(^| )active( |$)/,"$1$2");
_current_selected=null;
}
var _34=_33.getElementById("f_url").value;
var _35=_33.getElementById("dirPath");
var _36=_35.options[_35.selectedIndex].text;
var dRe=new RegExp("^("+_36.replace(/([\/\^$*+?.()|{}[\]])/g,"\\$1")+")([^/]*)$");
if(dRe.test(_34)){
var _38=document.getElementById("holder_"+asc2hex(RegExp.$2));
if(_38){
_current_selected=_38;
_38.className+=" active";
}
}
showPreview(_34);
}
function asc2hex(str){
var _3a="";
for(var i=0;i<str.length;i++){
var hex=(str.charCodeAt(i)).toString(16);
if(hex.length==1){
hex="0"+hex;
}
_3a+=hex;
}
return _3a;
}
function showMessage(_3d){
var _3e=window.top.document;
var _3f=_3e.getElementById("message");
var _40=_3e.getElementById("messages");
if(_3f&&_40){
if(_3f.firstChild){
_3f.removeChild(_3f.firstChild);
}
_3f.appendChild(_3e.createTextNode(i18n(_3d)));
_40.style.display="block";
}
}
function updateDiskMesg(_41){
var _42=window.top.document;
var _43=_42.getElementById("diskmesg");
if(_43){
if(_43.firstChild){
_43.removeChild(_43.firstChild);
}
_43.appendChild(_42.createTextNode(_41));
}
}
function addEvent(obj,_45,fn){
if(obj.addEventListener){
obj.addEventListener(_45,fn,true);
return true;
}else{
if(obj.attachEvent){
var r=obj.attachEvent("on"+_45,fn);
return r;
}else{
return false;
}
}
}
function confirmDeleteFile(_48){
if(confirm(i18n("Delete file \"$file="+_48+"$\"?"))){
return true;
}
return false;
}
function confirmDeleteDir(dir,_4a){
if(confirm(i18n("Delete folder \"$dir="+dir+"$\"?"))){
return true;
}
return false;
}
function showPreview(_4b){
window.parent.document.getElementById("f_preview").src=_4b?window.parent._backend_url+"__function=thumbs&img="+_4b:window.parent.opener._editor_url+"plugins/ExtendedFileManager/img/1x1_transparent.gif";
}
addEvent(window,"load",init);

