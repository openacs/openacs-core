function Forms(_1){
this.editor=_1;
var _2=_1.config;
var bl=Forms.btnList;
var _4=this;
var _5=["linebreak"];
for(var i=0;i<bl.length;++i){
var _7=bl[i];
if(!_7){
_5.push("separator");
}else{
var id=_7[0];
if(i<3){
_2.registerButton(id,this._lc(_7[1]),_1.imgURL("ed_"+_7[0]+".gif","Forms"),false,function(_9,id){
_4.buttonPress(_9,id);
});
}else{
_2.registerButton(id,this._lc(_7[1]),_1.imgURL("ed_"+_7[0]+".gif","Forms"),false,function(_b,id){
_4.buttonPress(_b,id);
},"form");
}
_5.push(id);
}
}
_2.toolbar.push(_5);
}
Forms._pluginInfo={name:"Forms",origin:"version: 1.0, by Nelson Bright, BrightWork, Inc., http://www.brightworkweb.com",version:"2.0",developer:"Udo Schmal",developer_url:"",sponsor:"L.N.Schaffrath NeueMedien",sponsor_url:"http://www.schaffrath-neuemedien.de/",c_owner:"Udo Schmal & Schaffrath-NeueMedien",license:"htmlArea"};
Forms.btnList=[null,["form","Form"],null,["textarea","Textarea"],["select","Selection Field"],["checkbox","Checkbox"],["radio","Radio Button"],["text","Text Field"],["password","Password Field"],["file","File Field"],["button","Button"],["submit","Submit Button"],["reset","Reset Button"],["image","Image Button"],["hidden","Hidden Field"],["label","Label"],["fieldset","Field Set"]];
Forms.prototype._lc=function(_d){
return HTMLArea._lc(_d,"Forms");
};
Forms.prototype.onGenerate=function(){
var _e="Form-style";
var _f=this.editor._doc.getElementById(_e);
if(_f==null){
_f=this.editor._doc.createElement("link");
_f.id=_e;
_f.rel="stylesheet";
_f.href=_editor_url+"plugins/Forms/forms.css";
this.editor._doc.getElementsByTagName("HEAD")[0].appendChild(_f);
}
};
Forms.prototype.buttonPress=function(_10,_11,_12){
function optionValues(_13,_14){
this.text=_13;
this.value=_14;
}
var _15=new Object();
var _16=_11;
var sel=_10._getSelection();
var _18=_10._createRange(sel);
if(_11=="form"){
var pe=_10.getParentElement();
var frm=null;
while(pe&&(pe.nodeType==1)&&(pe.tagName.toLowerCase()!="body")){
if(pe.tagName.toLowerCase()=="form"){
frm=pe;
break;
}else{
pe=pe.parentNode;
}
}
if(frm){
_15.f_name=frm.name;
_15.f_action=frm.action;
_15.f_method=frm.method;
_15.f_enctype=frm.enctype;
_15.f_target=frm.target;
}else{
_15.f_name="";
_15.f_action="";
_15.f_method="";
_15.f_enctype="";
_15.f_target="";
}
_10._popupDialog("plugin://Forms/form",function(_1b){
if(_1b){
if(frm){
frm.name=_1b["f_name"];
frm.setAttribute("action",_1b["f_action"]);
frm.setAttribute("method",_1b["f_method"]);
frm.setAttribute("enctype",_1b["f_enctype"]);
frm.setAttribute("target",_1b["f_target"]);
}else{
frm="<form name=\""+_1b["f_name"]+"\"";
if(_1b["f_action"]!=""){
frm+=" action=\""+_1b["f_action"]+"\"";
}
if(_1b["f_method"]!=""){
frm+=" method=\""+_1b["f_method"]+"\"";
}
if(_1b["f_enctype"]!=""){
frm+=" enctype=\""+_1b["f_enctype"]+"\"";
}
if(_1b["f_target"]!=""){
frm+=" target=\""+_1b["f_target"]+"\"";
}
frm+=">";
_10.surroundHTML(frm,"&nbsp;</form>");
}
}
},_15);
}else{
var _1c="";
if(typeof _12=="undefined"){
_12=_10.getParentElement();
var tag=_12.tagName.toLowerCase();
if(_12&&(tag=="legend")){
_12=_12.parentElement;
tag=_12.tagName.toLowerCase();
}
if(_12&&!(tag=="textarea"||tag=="select"||tag=="input"||tag=="label"||tag=="fieldset")){
_12=null;
}
}
if(_12){
_16=_12.tagName.toLowerCase();
_15.f_name=_12.name;
_1c=_12.tagName;
if(_16=="input"){
_15.f_type=_12.type;
_16=_12.type;
}
switch(_16){
case "textarea":
_15.f_cols=_12.cols;
_15.f_rows=_12.rows;
_15.f_text=_12.innerHTML;
_15.f_wrap=_12.getAttribute("wrap");
_15.f_readOnly=_12.getAttribute("readOnly");
_15.f_disabled=_12.getAttribute("disabled");
_15.f_tabindex=_12.getAttribute("tabindex");
_15.f_accesskey=_12.getAttribute("accesskey");
break;
case "select":
_15.f_size=parseInt(_12.size);
_15.f_multiple=_12.getAttribute("multiple");
_15.f_disabled=_12.getAttribute("disabled");
_15.f_tabindex=_12.getAttribute("tabindex");
var _1e=new Array();
for(var i=0;i<=_12.options.length-1;i++){
_1e[i]=new optionValues(_12.options[i].text,_12.options[i].value);
}
_15.f_options=_1e;
break;
case "text":
case "password":
_15.f_value=_12.value;
_15.f_size=_12.size;
_15.f_maxLength=_12.maxLength;
_15.f_readOnly=_12.getAttribute("readOnly");
_15.f_disabled=_12.getAttribute("disabled");
_15.f_tabindex=_12.getAttribute("tabindex");
_15.f_accesskey=_12.getAttribute("accesskey");
break;
case "hidden":
_15.f_value=_12.value;
break;
case "submit":
case "reset":
_15.f_value=_12.value;
_15.f_disabled=_12.getAttribute("disabled");
_15.f_tabindex=_12.getAttribute("tabindex");
_15.f_accesskey=_12.getAttribute("accesskey");
break;
case "checkbox":
case "radio":
_15.f_value=_12.value;
_15.f_checked=_12.checked;
_15.f_disabled=_12.getAttribute("disabled");
_15.f_tabindex=_12.getAttribute("tabindex");
_15.f_accesskey=_12.getAttribute("accesskey");
break;
case "button":
_15.f_value=_12.value;
_15.f_onclick=_12.getAttribute("onclick");
_15.f_disabled=_12.getAttribute("disabled");
_15.f_tabindex=_12.getAttribute("tabindex");
_15.f_accesskey=_12.getAttribute("accesskey");
break;
case "image":
_15.f_value=_12.value;
_15.f_src=_12.src;
_15.f_disabled=_12.getAttribute("disabled");
_15.f_tabindex=_12.getAttribute("tabindex");
_15.f_accesskey=_12.getAttribute("accesskey");
break;
case "file":
_15.f_disabled=_12.getAttribute("disabled");
_15.f_tabindex=_12.getAttribute("tabindex");
_15.f_accesskey=_12.getAttribute("accesskey");
break;
case "label":
_15.f_text=_12.innerHTML;
_15.f_for=_12.getAttribute("for");
_15.f_accesskey=_12.getAttribute("accesskey");
break;
case "fieldset":
if(_12.firstChild.tagName.toLowerCase()=="legend"){
_15.f_text=_12.firstChild.innerHTML;
}else{
_15.f_text="";
}
break;
}
}else{
_15.f_name="";
switch(_11){
case "textarea":
case "select":
case "label":
case "fieldset":
_1c=_11;
break;
default:
_1c="input";
_15.f_type=_11;
break;
}
_15.f_options="";
_15.f_cols="20";
_15.f_rows="4";
_15.f_multiple="false";
_15.f_value="";
_15.f_size="";
_15.f_maxLength="";
_15.f_checked="";
_15.f_src="";
_15.f_onclick="";
_15.f_wrap="";
_15.f_readOnly="false";
_15.f_disabled="false";
_15.f_tabindex="";
_15.f_accesskey="";
_15.f_for="";
_15.f_text="";
_15.f_legend="";
}
_10._popupDialog("plugin://Forms/"+_1c+".html",function(_20){
if(_20){
if(_20["f_cols"]){
if(isNaN(parseInt(_20["f_cols"],10))||parseInt(_20["f_cols"],10)<=0){
_20["f_cols"]="";
}
}
if(_20["f_rows"]){
if(isNaN(parseInt(_20["f_rows"],10))||parseInt(_20["f_rows"],10)<=0){
_20["f_rows"]="";
}
}
if(_20["f_size"]){
if(isNaN(parseInt(_20["f_size"],10))||parseInt(_20["f_size"],10)<=0){
_20["f_size"]="";
}
}
if(_20["f_maxlength"]){
if(isNaN(parseInt(_20["f_maxLength"],10))||parseInt(_20["f_maxLength"],10)<=0){
_20["f_maxLength"]="";
}
}
if(_12){
for(field in _20){
if((field=="f_text")||(field=="f_options")||(field=="f_onclick")||(field=="f_checked")){
continue;
}
if(_20[field]!=""){
_12.setAttribute(field.substring(2,20),_20[field]);
}else{
_12.removeAttribute(field.substring(2,20));
}
}
if(_16=="textarea"){
_12.innerHTML=_20["f_text"];
}else{
if(_16=="select"){
_12.options.length=0;
var _21=_20["f_options"];
for(i=0;i<=_21.length-1;i++){
_12.options[i]=new Option(_21[i].text,_21[i].value);
}
}else{
if(_16=="label"){
_12.innerHTML=_20["f_text"];
}else{
if(_16=="fieldset"){
if(_15.f_text!=""){
if(_12.firstChild.tagName.toLowerCase()=="legend"){
_12.firstChild.innerHTML=_20["f_text"];
}
}else{
}
}else{
if((_16=="checkbox")||(_16=="radio")){
if(_20["f_checked"]!=""){
_12.checked=true;
}else{
_12.checked=false;
}
}else{
if(_20["f_onclick"]){
_12.onclick="";
if(_20["f_onclick"]!=""){
_12.onclick=_20["f_onclick"];
}
}
}
}
}
}
}
}else{
var _22="";
for(field in _20){
if(!_20[field]){
continue;
}
if((_20[field]=="")||(field=="f_text")||(field=="f_options")){
continue;
}
_22+=" "+field.substring(2,20)+"=\""+_20[field]+"\"";
}
if(_16=="textarea"){
_22="<textarea"+_22+">"+_20["f_text"]+"</textarea>";
}else{
if(_16=="select"){
_22="<select"+_22+">";
var _21=_20["f_options"];
for(i=0;i<=_21.length-1;i++){
_22+="<option value=\""+_21[i].value+"\">"+_21[i].text+"</option>";
}
_22+="</select>";
}else{
if(_16=="label"){
_22="<label"+_22+">"+_20["f_text"]+"</label>";
}else{
if(_16=="fieldset"){
_22="<fieldset"+_22+">";
if(_20["f_legend"]!=""){
_22+="<legend>"+_20["f_text"]+"</legend>";
}
_22+="</fieldset>";
}else{
_22="<input type=\""+_16+"\""+_22+">";
}
}
}
}
_10.insertHTML(_22);
}
}
},_15);
}
};

