function Dialog(_1,_2,_3){
if(typeof _3=="undefined"){
_3=window;
}
Dialog._geckoOpenModal(_1,_2,_3);
}
Dialog._parentEvent=function(ev){
setTimeout(function(){
if(Dialog._modal&&!Dialog._modal.closed){
Dialog._modal.focus();
}
},50);
if(Dialog._modal&&!Dialog._modal.closed){
Dialog._stopEvent(ev);
}
};
Dialog._return=null;
Dialog._modal=null;
Dialog._arguments=null;
Dialog._geckoOpenModal=function(_5,_6,_7){
var _8="hadialog"+_5;
var _9=/\W/g;
_8=_8.replace(_9,"_");
var _a=window.open(_5,_8,"toolbar=no,menubar=no,personalbar=no,width=10,height=10,"+"scrollbars=no,resizable=yes,modal=yes,dependable=yes");
Dialog._modal=_a;
Dialog._arguments=_7;
function capwin(w){
Dialog._addEvent(w,"click",Dialog._parentEvent);
Dialog._addEvent(w,"mousedown",Dialog._parentEvent);
Dialog._addEvent(w,"focus",Dialog._parentEvent);
}
function relwin(w){
Dialog._removeEvent(w,"click",Dialog._parentEvent);
Dialog._removeEvent(w,"mousedown",Dialog._parentEvent);
Dialog._removeEvent(w,"focus",Dialog._parentEvent);
}
capwin(window);
for(var i=0;i<window.frames.length;capwin(window.frames[i++])){
}
Dialog._return=function(_e){
if(_e&&_6){
_6(_e);
}
relwin(window);
for(var i=0;i<window.frames.length;relwin(window.frames[i++])){
}
Dialog._modal=null;
};
};
Dialog._addEvent=function(el,_11,_12){
if(Dialog.is_ie){
el.attachEvent("on"+_11,_12);
}else{
el.addEventListener(_11,_12,true);
}
};
Dialog._removeEvent=function(el,_14,_15){
if(Dialog.is_ie){
el.detachEvent("on"+_14,_15);
}else{
el.removeEventListener(_14,_15,true);
}
};
Dialog._stopEvent=function(ev){
if(Dialog.is_ie){
ev.cancelBubble=true;
ev.returnValue=false;
}else{
ev.preventDefault();
ev.stopPropagation();
}
};
Dialog.agt=navigator.userAgent.toLowerCase();
Dialog.is_ie=((Dialog.agt.indexOf("msie")!=-1)&&(Dialog.agt.indexOf("opera")==-1));

