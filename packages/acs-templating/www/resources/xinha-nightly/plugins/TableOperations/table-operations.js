function TableOperations(_1){
this.editor=_1;
var _2=_1.config;
var bl=TableOperations.btnList;
var _4=this;
_2.removeToolbarElement(" inserttable toggleborders ");
var _5=["linebreak","inserttable","toggleborders"];
for(var i=0;i<bl.length;++i){
var _7=bl[i];
if(!_7){
_5.push("separator");
}else{
var id="TO-"+_7[0];
_2.registerButton(id,HTMLArea._lc(_7[2],"TableOperations"),_1.imgURL(_7[0]+".gif","TableOperations"),false,function(_9,id){
_4.buttonPress(_9,id);
},_7[1]);
_5.push(id);
}
}
_2.toolbar.push(_5);
if(typeof PopupWin=="undefined"){
Xinha._loadback(_editor_url+"modules/Dialogs/popupwin.js");
}
}
TableOperations._pluginInfo={name:"TableOperations",version:"1.0",developer:"Mihai Bazon",developer_url:"http://dynarch.com/mishoo/",c_owner:"Mihai Bazon",sponsor:"Zapatec Inc.",sponsor_url:"http://www.bloki.com",license:"htmlArea"};
TableOperations.prototype._lc=function(_b){
return HTMLArea._lc(_b,"TableOperations");
};
TableOperations.prototype.getClosest=function(_c){
var _d=this.editor;
var _e=_d.getAllAncestors();
var _f=null;
_c=(""+_c).toLowerCase();
for(var i=0;i<_e.length;++i){
var el=_e[i];
if(el.tagName.toLowerCase()==_c){
_f=el;
break;
}
}
return _f;
};
TableOperations.prototype.dialogTableProperties=function(){
var _12=this.getClosest("table");
var _13=new PopupWin(this.editor,HTMLArea._lc("Table Properties","TableOperations"),function(_14,_15){
TableOperations.processStyle(_15,_12);
for(var i in _15){
if(typeof _15[i]=="function"){
continue;
}
var val=_15[i];
switch(i){
case "f_caption":
if(/\S/.test(val)){
var _18=_12.getElementsByTagName("caption")[0];
if(!_18){
_18=_14.editor._doc.createElement("caption");
_12.insertBefore(_18,_12.firstChild);
}
_18.innerHTML=val;
}else{
var _18=_12.getElementsByTagName("caption")[0];
if(_18){
_18.parentNode.removeChild(_18);
}
}
break;
case "f_summary":
_12.summary=val;
break;
case "f_width":
_12.style.width=(""+val)+_15.f_unit;
break;
case "f_align":
_12.align=val;
break;
case "f_spacing":
_12.cellSpacing=val;
break;
case "f_padding":
_12.cellPadding=val;
break;
case "f_borders":
_12.border=val;
break;
case "f_frames":
_12.frame=val;
break;
case "f_rules":
_12.rules=val;
break;
}
}
_14.editor.forceRedraw();
_14.editor.focusEditor();
_14.editor.updateToolbar();
var _19=_12.style.borderCollapse;
_12.style.borderCollapse="collapse";
_12.style.borderCollapse="separate";
_12.style.borderCollapse=_19;
},function(_1a){
var _1b="";
var _1c=_12.getElementsByTagName("caption")[0];
if(_1c){
_1b=_1c.innerHTML;
}
var _1d=_12.summary;
var _1e=parseInt(_12.style.width);
isNaN(_1e)&&(_1e="");
var _1f=/%/.test(_12.style.width)?"percent":"pixels";
var _20=_12.align;
var _21=_12.cellSpacing;
var _22=_12.cellPadding;
var _23=_12.border;
var _24=_12.frame;
var _25=_12.rules;
function selected(val){
return val?" selected":"";
}
_1a.content.style.width="400px";
_1a.content.innerHTML=" <div class='title'>"+HTMLArea._lc("Table Properties","TableOperations")+"</div> <table style='width:100%'>   <tr>     <td>       <fieldset><legend>"+HTMLArea._lc("Description","TableOperations")+"</legend>        <table style='width:100%'>         <tr>           <td class='label'>"+HTMLArea._lc("Caption","TableOperations")+":</td>           <td class='value'><input type='text' name='f_caption' value='"+_1b+"'/></td>         </tr><tr>           <td class='label'>"+HTMLArea._lc("Summary","TableOperations")+":</td>           <td class='value'><input type='text' name='f_summary' value='"+_1d+"'/></td>         </tr>        </table>       </fieldset>     </td>   </tr>   <tr><td id='--HA-layout'></td></tr>   <tr>     <td>       <fieldset><legend>"+HTMLArea._lc("Spacing and padding","TableOperations")+"</legend>        <table style='width:100%'> "+"        <tr>           <td class='label'>"+HTMLArea._lc("Spacing","TableOperations")+":</td>           <td><input type='text' name='f_spacing' size='5' value='"+_21+"' /> &nbsp;"+HTMLArea._lc("Padding","TableOperations")+":            <input type='text' name='f_padding' size='5' value='"+_22+"' /> &nbsp;&nbsp;"+HTMLArea._lc("pixels","TableOperations")+"          </td>         </tr>        </table>       </fieldset>     </td>   </tr>   <tr>     <td>       <fieldset><legend>"+HTMLArea._lc("Frame and borders","TableOperations")+"</legend>         <table width='100%'>           <tr>             <td class='label'>"+HTMLArea._lc("Borders","TableOperations")+":</td>             <td><input name='f_borders' type='text' size='5' value='"+_23+"' /> &nbsp;&nbsp;"+HTMLArea._lc("pixels","TableOperations")+"</td>           </tr>           <tr>             <td class='label'>"+HTMLArea._lc("Frames","TableOperations")+":</td>             <td>               <select name='f_frames'>                 <option value='void'"+selected(_24=="void")+">"+HTMLArea._lc("No sides","TableOperations")+"</option>                 <option value='above'"+selected(_24=="above")+">"+HTMLArea._lc("The top side only","TableOperations")+"</option>                 <option value='below'"+selected(_24=="below")+">"+HTMLArea._lc("The bottom side only","TableOperations")+"</option>                 <option value='hsides'"+selected(_24=="hsides")+">"+HTMLArea._lc("The top and bottom sides only","TableOperations")+"</option>                 <option value='vsides'"+selected(_24=="vsides")+">"+HTMLArea._lc("The right and left sides only","TableOperations")+"</option>                 <option value='lhs'"+selected(_24=="lhs")+">"+HTMLArea._lc("The left-hand side only","TableOperations")+"</option>                 <option value='rhs'"+selected(_24=="rhs")+">"+HTMLArea._lc("The right-hand side only","TableOperations")+"</option>                 <option value='box'"+selected(_24=="box")+">"+HTMLArea._lc("All four sides","TableOperations")+"</option>               </select>             </td>           </tr>           <tr>             <td class='label'>"+HTMLArea._lc("Rules","TableOperations")+":</td>             <td>               <select name='f_rules'>                 <option value='none'"+selected(_25=="none")+">"+HTMLArea._lc("No rules","TableOperations")+"</option>                 <option value='rows'"+selected(_25=="rows")+">"+HTMLArea._lc("Rules will appear between rows only","TableOperations")+"</option>                 <option value='cols'"+selected(_25=="cols")+">"+HTMLArea._lc("Rules will appear between columns only","TableOperations")+"</option>                 <option value='all'"+selected(_25=="all")+">"+HTMLArea._lc("Rules will appear between all rows and columns","TableOperations")+"</option>               </select>             </td>           </tr>         </table>       </fieldset>     </td>   </tr>   <tr>     <td id='--HA-style'></td>   </tr> </table> ";
var _27=TableOperations.createStyleFieldset(_1a.doc,_1a.editor,_12);
var p=_1a.doc.getElementById("--HA-style");
p.appendChild(_27);
var _29=TableOperations.createStyleLayoutFieldset(_1a.doc,_1a.editor,_12);
p=_1a.doc.getElementById("--HA-layout");
p.appendChild(_29);
_1a.modal=true;
_1a.addButtons("OK","Cancel");
_1a.showAtElement(_1a.editor._iframe,"c");
});
};
TableOperations.prototype.dialogRowCellProperties=function(_2a){
var _2b=this.getClosest(_2a?"td":"tr");
var _2c=this.getClosest("table");
var _2d=new PopupWin(this.editor,_2a?HTMLArea._lc("Cell Properties","TableOperations"):HTMLArea._lc("Row Properties","TableOperations"),function(_2e,_2f){
TableOperations.processStyle(_2f,_2b);
for(var i in _2f){
if(typeof _2f[i]=="function"){
continue;
}
var val=_2f[i];
switch(i){
case "f_align":
_2b.align=val;
break;
case "f_char":
_2b.ch=val;
break;
case "f_valign":
_2b.vAlign=val;
break;
}
}
_2e.editor.forceRedraw();
_2e.editor.focusEditor();
_2e.editor.updateToolbar();
var _32=_2c.style.borderCollapse;
_2c.style.borderCollapse="collapse";
_2c.style.borderCollapse="separate";
_2c.style.borderCollapse=_32;
},function(_33){
var _34=_2b.align;
var _35=_2b.vAlign;
var _36=_2b.ch;
function selected(val){
return val?" selected":"";
}
_33.content.style.width="400px";
_33.content.innerHTML=" <div class='title'>"+HTMLArea._lc(_2a?"Cell Properties":"Row Properties","TableOperations")+"</div> <table style='width:100%'>   <tr>     <td id='--HA-layout'> "+"    </td>   </tr>   <tr>     <td id='--HA-style'></td>   </tr> </table> ";
var _38=TableOperations.createStyleFieldset(_33.doc,_33.editor,_2b);
var p=_33.doc.getElementById("--HA-style");
p.appendChild(_38);
var _3a=TableOperations.createStyleLayoutFieldset(_33.doc,_33.editor,_2b);
p=_33.doc.getElementById("--HA-layout");
p.appendChild(_3a);
_33.modal=true;
_33.addButtons("OK","Cancel");
_33.showAtElement(_33.editor._iframe,"c");
});
};
TableOperations.prototype.buttonPress=function(_3b,_3c){
this.editor=_3b;
var _3d=HTMLArea.is_gecko?"<br />":"";
function clearRow(tr){
var tds=tr.getElementsByTagName("td");
for(var i=tds.length;--i>=0;){
var td=tds[i];
td.rowSpan=1;
td.innerHTML=_3d;
}
}
function splitRow(td){
var n=parseInt(""+td.rowSpan);
var nc=parseInt(""+td.colSpan);
td.rowSpan=1;
tr=td.parentNode;
var itr=tr.rowIndex;
var trs=tr.parentNode.rows;
var _47=td.cellIndex;
while(--n>0){
tr=trs[++itr];
var otd=_3b._doc.createElement("td");
otd.colSpan=td.colSpan;
otd.innerHTML=_3d;
tr.insertBefore(otd,tr.cells[_47]);
}
_3b.forceRedraw();
_3b.updateToolbar();
}
function splitCol(td){
var nc=parseInt(""+td.colSpan);
td.colSpan=1;
tr=td.parentNode;
var ref=td.nextSibling;
while(--nc>0){
var otd=_3b._doc.createElement("td");
otd.rowSpan=td.rowSpan;
otd.innerHTML=_3d;
tr.insertBefore(otd,ref);
}
_3b.forceRedraw();
_3b.updateToolbar();
}
function splitCell(td){
var nc=parseInt(""+td.colSpan);
splitCol(td);
var _4f=td.parentNode.cells;
var _50=td.cellIndex;
while(nc-->0){
splitRow(_4f[_50++]);
}
}
function selectNextNode(el){
var _52=el.nextSibling;
while(_52&&_52.nodeType!=1){
_52=_52.nextSibling;
}
if(!_52){
_52=el.previousSibling;
while(_52&&_52.nodeType!=1){
_52=_52.previousSibling;
}
}
if(!_52){
_52=el.parentNode;
}
_3b.selectNodeContents(_52);
}
switch(_3c){
case "TO-row-insert-above":
case "TO-row-insert-under":
var tr=this.getClosest("tr");
if(!tr){
break;
}
var otr=tr.cloneNode(true);
clearRow(otr);
tr.parentNode.insertBefore(otr,/under/.test(_3c)?tr.nextSibling:tr);
_3b.forceRedraw();
_3b.focusEditor();
break;
case "TO-row-delete":
var tr=this.getClosest("tr");
if(!tr){
break;
}
var par=tr.parentNode;
if(par.rows.length==1){
alert(HTMLArea._lc("HTMLArea cowardly refuses to delete the last row in table.","TableOperations"));
break;
}
selectNextNode(tr);
par.removeChild(tr);
_3b.forceRedraw();
_3b.focusEditor();
_3b.updateToolbar();
break;
case "TO-row-split":
var td=this.getClosest("td");
if(!td){
break;
}
splitRow(td);
break;
case "TO-col-insert-before":
case "TO-col-insert-after":
var td=this.getClosest("td");
if(!td){
break;
}
var _57=td.parentNode.parentNode.rows;
var _58=td.cellIndex;
var _59=(td.parentNode.cells.length==_58+1);
for(var i=_57.length;--i>=0;){
var tr=_57[i];
var otd=_3b._doc.createElement("td");
otd.innerHTML=_3d;
if(_59&&HTMLArea.is_ie){
tr.insertBefore(otd);
}else{
var ref=tr.cells[_58+(/after/.test(_3c)?1:0)];
tr.insertBefore(otd,ref);
}
}
_3b.focusEditor();
break;
case "TO-col-split":
var td=this.getClosest("td");
if(!td){
break;
}
splitCol(td);
break;
case "TO-col-delete":
var td=this.getClosest("td");
if(!td){
break;
}
var _58=td.cellIndex;
if(td.parentNode.cells.length==1){
alert(HTMLArea._lc("HTMLArea cowardly refuses to delete the last column in table.","TableOperations"));
break;
}
selectNextNode(td);
var _57=td.parentNode.parentNode.rows;
for(var i=_57.length;--i>=0;){
var tr=_57[i];
tr.removeChild(tr.cells[_58]);
}
_3b.forceRedraw();
_3b.focusEditor();
_3b.updateToolbar();
break;
case "TO-cell-split":
var td=this.getClosest("td");
if(!td){
break;
}
splitCell(td);
break;
case "TO-cell-insert-before":
case "TO-cell-insert-after":
var td=this.getClosest("td");
if(!td){
break;
}
var tr=td.parentNode;
var otd=_3b._doc.createElement("td");
otd.innerHTML=_3d;
tr.insertBefore(otd,/after/.test(_3c)?td.nextSibling:td);
_3b.forceRedraw();
_3b.focusEditor();
break;
case "TO-cell-delete":
var td=this.getClosest("td");
if(!td){
break;
}
if(td.parentNode.cells.length==1){
alert(HTMLArea._lc("HTMLArea cowardly refuses to delete the last cell in row.","TableOperations"));
break;
}
selectNextNode(td);
td.parentNode.removeChild(td);
_3b.forceRedraw();
_3b.updateToolbar();
break;
case "TO-cell-merge":
var sel=_3b._getSelection();
var _5e,i=0;
var _57=[];
var row=null;
var _60=null;
if(!HTMLArea.is_ie){
try{
if(sel.rangeCount<2){
alert(HTMLArea._lc("Please select the cells you want to merge.","TableOperations"));
break;
}
while(_5e=sel.getRangeAt(i++)){
var td=_5e.startContainer.childNodes[_5e.startOffset];
if(td.parentNode!=row){
row=td.parentNode;
(_60)&&_57.push(_60);
_60=[];
}
_60.push(td);
}
}
catch(e){
}
_57.push(_60);
}else{
var td=this.getClosest("td");
if(!td){
alert(HTMLArea._lc("Please click into some cell","TableOperations"));
break;
}
var tr=td.parentElement;
var _61=prompt(HTMLArea._lc("How many columns would you like to merge?","TableOperations"),2);
if(!_61){
break;
}
var _62=prompt(HTMLArea._lc("How many rows would you like to merge?","TableOperations"),2);
if(!_62){
break;
}
var _63=td.cellIndex;
while(_62-->0){
td=tr.cells[_63];
_60=[td];
for(var i=1;i<_61;++i){
td=td.nextSibling;
if(!td){
break;
}
_60.push(td);
}
_57.push(_60);
tr=tr.nextSibling;
if(!tr){
break;
}
}
}
var _64="";
for(i=0;i<_57.length;++i){
var _60=_57[i];
for(var j=0;j<_60.length;++j){
var _66=_60[j];
_64+=_66.innerHTML;
(i||j)&&(_66.parentNode.removeChild(_66));
}
}
var td=_57[0][0];
td.innerHTML=_64;
td.rowSpan=_57.length;
td.colSpan=_57[0].length;
_3b.selectNodeContents(td);
_3b.forceRedraw();
_3b.focusEditor();
break;
case "TO-table-prop":
this.dialogTableProperties();
break;
case "TO-row-prop":
this.dialogRowCellProperties(false);
break;
case "TO-cell-prop":
this.dialogRowCellProperties(true);
break;
default:
alert("Button ["+_3c+"] not yet implemented");
}
};
TableOperations.btnList=[["table-prop","table","Table properties"],null,["row-prop","tr","Row properties"],["row-insert-above","tr","Insert row before"],["row-insert-under","tr","Insert row after"],["row-delete","tr","Delete row"],["row-split","td[rowSpan!=1]","Split row"],null,["col-insert-before","td","Insert column before"],["col-insert-after","td","Insert column after"],["col-delete","td","Delete column"],["col-split","td[colSpan!=1]","Split column"],null,["cell-prop","td","Cell properties"],["cell-insert-before","td","Insert cell before"],["cell-insert-after","td","Insert cell after"],["cell-delete","td","Delete cell"],["cell-merge","tr","Merge cells"],["cell-split","td[colSpan!=1,rowSpan!=1]","Split cell"]];
TableOperations.getLength=function(_67){
var len=parseInt(_67);
if(isNaN(len)){
len="";
}
return len;
};
TableOperations.processStyle=function(_69,_6a){
var _6b=_6a.style;
for(var i in _69){
if(typeof _69[i]=="function"){
continue;
}
var val=_69[i];
switch(i){
case "f_st_backgroundColor":
_6b.backgroundColor=val;
break;
case "f_st_color":
_6b.color=val;
break;
case "f_st_backgroundImage":
if(/\S/.test(val)){
_6b.backgroundImage="url("+val+")";
}else{
_6b.backgroundImage="none";
}
break;
case "f_st_borderWidth":
_6b.borderWidth=val;
break;
case "f_st_borderStyle":
_6b.borderStyle=val;
break;
case "f_st_borderColor":
_6b.borderColor=val;
break;
case "f_st_borderCollapse":
_6b.borderCollapse=val?"collapse":"";
break;
case "f_st_width":
if(/\S/.test(val)){
_6b.width=val+_69["f_st_widthUnit"];
}else{
_6b.width="";
}
break;
case "f_st_height":
if(/\S/.test(val)){
_6b.height=val+_69["f_st_heightUnit"];
}else{
_6b.height="";
}
break;
case "f_st_textAlign":
if(val=="char"){
var ch=_69["f_st_textAlignChar"];
if(ch=="\""){
ch="\\\"";
}
_6b.textAlign="\""+ch+"\"";
}else{
if(val=="-"){
_6b.textAlign="";
}else{
_6b.textAlign=val;
}
}
break;
case "f_st_verticalAlign":
_6a.vAlign="";
if(val=="-"){
_6b.verticalAlign="";
}else{
_6b.verticalAlign=val;
}
break;
case "f_st_float":
_6b.cssFloat=val;
break;
}
}
};
TableOperations.createColorButton=function(doc,_70,_71,_72){
if(!_71){
_71="";
}else{
if(!/#/.test(_71)){
_71=HTMLArea._colorToRgb(_71);
}
}
var df=doc.createElement("span");
var _74=doc.createElement("input");
_74.type="hidden";
df.appendChild(_74);
_74.name="f_st_"+_72;
_74.value=_71;
var _75=doc.createElement("span");
_75.className="buttonColor";
df.appendChild(_75);
var _76=doc.createElement("span");
_76.className="chooser";
_76.style.backgroundColor=_71;
_75.appendChild(_76);
_75.onmouseover=function(){
if(!this.disabled){
this.className+=" buttonColor-hilite";
}
};
_75.onmouseout=function(){
if(!this.disabled){
this.className="buttonColor";
}
};
_76.onclick=function(){
if(this.parentNode.disabled){
return false;
}
_70._popupDialog("select_color.html",function(_77){
if(_77){
_76.style.backgroundColor="#"+_77;
_74.value="#"+_77;
}
},_71);
};
var _78=doc.createElement("span");
_78.innerHTML="&#x00d7;";
_78.className="nocolor";
_78.title=HTMLArea._lc("Unset color","TableOperations");
_75.appendChild(_78);
_78.onmouseover=function(){
if(!this.parentNode.disabled){
this.className+=" nocolor-hilite";
}
};
_78.onmouseout=function(){
if(!this.parentNode.disabled){
this.className="nocolor";
}
};
_78.onclick=function(){
_76.style.backgroundColor="";
_74.value="";
};
return df;
};
TableOperations.createStyleLayoutFieldset=function(doc,_7a,el){
var _7c=doc.createElement("fieldset");
var _7d=doc.createElement("legend");
_7c.appendChild(_7d);
_7d.innerHTML=HTMLArea._lc("Layout","TableOperations");
var _7e=doc.createElement("table");
_7c.appendChild(_7e);
_7e.style.width="100%";
var _7f=doc.createElement("tbody");
_7e.appendChild(_7f);
var _80=el.tagName.toLowerCase();
var tr,td,input,select,option,options,i;
if(_80!="td"&&_80!="tr"&&_80!="th"){
tr=doc.createElement("tr");
_7f.appendChild(tr);
td=doc.createElement("td");
td.className="label";
tr.appendChild(td);
td.innerHTML=HTMLArea._lc("Float","TableOperations")+":";
td=doc.createElement("td");
tr.appendChild(td);
select=doc.createElement("select");
td.appendChild(select);
select.name="f_st_float";
options=["None","Left","Right"];
for(var i=0;i<options.length;++i){
var Val=options[i];
var val=options[i].toLowerCase();
option=doc.createElement("option");
option.innerHTML=HTMLArea._lc(Val,"TableOperations");
option.value=val;
option.selected=((""+el.style.cssFloat).toLowerCase()==val);
select.appendChild(option);
}
}
tr=doc.createElement("tr");
_7f.appendChild(tr);
td=doc.createElement("td");
td.className="label";
tr.appendChild(td);
td.innerHTML=HTMLArea._lc("Width","TableOperations")+":";
td=doc.createElement("td");
tr.appendChild(td);
input=doc.createElement("input");
input.type="text";
input.value=TableOperations.getLength(el.style.width);
input.size="5";
input.name="f_st_width";
input.style.marginRight="0.5em";
td.appendChild(input);
select=doc.createElement("select");
select.name="f_st_widthUnit";
option=doc.createElement("option");
option.innerHTML=HTMLArea._lc("percent","TableOperations");
option.value="%";
option.selected=/%/.test(el.style.width);
select.appendChild(option);
option=doc.createElement("option");
option.innerHTML=HTMLArea._lc("pixels","TableOperations");
option.value="px";
option.selected=/px/.test(el.style.width);
select.appendChild(option);
td.appendChild(select);
select.style.marginRight="0.5em";
td.appendChild(doc.createTextNode(HTMLArea._lc("Text align","TableOperations")+":"));
select=doc.createElement("select");
select.style.marginLeft=select.style.marginRight="0.5em";
td.appendChild(select);
select.name="f_st_textAlign";
options=["Left","Center","Right","Justify","-"];
if(_80=="td"){
options.push("Char");
}
input=doc.createElement("input");
input.name="f_st_textAlignChar";
input.size="1";
input.style.fontFamily="monospace";
td.appendChild(input);
for(var i=0;i<options.length;++i){
var Val=options[i];
var val=Val.toLowerCase();
option=doc.createElement("option");
option.value=val;
option.innerHTML=HTMLArea._lc(Val,"TableOperations");
option.selected=((el.style.textAlign.toLowerCase()==val)||(el.style.textAlign==""&&Val=="-"));
select.appendChild(option);
}
function setCharVisibility(_85){
input.style.visibility=_85?"visible":"hidden";
if(_85){
input.focus();
input.select();
}
}
select.onchange=function(){
setCharVisibility(this.value=="char");
};
setCharVisibility(select.value=="char");
tr=doc.createElement("tr");
_7f.appendChild(tr);
td=doc.createElement("td");
td.className="label";
tr.appendChild(td);
td.innerHTML=HTMLArea._lc("Height","TableOperations")+":";
td=doc.createElement("td");
tr.appendChild(td);
input=doc.createElement("input");
input.type="text";
input.value=TableOperations.getLength(el.style.height);
input.size="5";
input.name="f_st_height";
input.style.marginRight="0.5em";
td.appendChild(input);
select=doc.createElement("select");
select.name="f_st_heightUnit";
option=doc.createElement("option");
option.innerHTML=HTMLArea._lc("percent","TableOperations");
option.value="%";
option.selected=/%/.test(el.style.height);
select.appendChild(option);
option=doc.createElement("option");
option.innerHTML=HTMLArea._lc("pixels","TableOperations");
option.value="px";
option.selected=/px/.test(el.style.height);
select.appendChild(option);
td.appendChild(select);
select.style.marginRight="0.5em";
td.appendChild(doc.createTextNode(HTMLArea._lc("Vertical align","TableOperations")+":"));
select=doc.createElement("select");
select.name="f_st_verticalAlign";
select.style.marginLeft="0.5em";
td.appendChild(select);
options=["Top","Middle","Bottom","Baseline","-"];
for(var i=0;i<options.length;++i){
var Val=options[i];
var val=Val.toLowerCase();
option=doc.createElement("option");
option.value=val;
option.innerHTML=HTMLArea._lc(Val,"TableOperations");
option.selected=((el.style.verticalAlign.toLowerCase()==val)||(el.style.verticalAlign==""&&Val=="-"));
select.appendChild(option);
}
return _7c;
};
TableOperations.createStyleFieldset=function(doc,_87,el){
var _89=doc.createElement("fieldset");
var _8a=doc.createElement("legend");
_89.appendChild(_8a);
_8a.innerHTML=HTMLArea._lc("CSS Style","TableOperations");
var _8b=doc.createElement("table");
_89.appendChild(_8b);
_8b.style.width="100%";
var _8c=doc.createElement("tbody");
_8b.appendChild(_8c);
var tr,td,input,select,option,options,i;
tr=doc.createElement("tr");
_8c.appendChild(tr);
td=doc.createElement("td");
tr.appendChild(td);
td.className="label";
td.innerHTML=HTMLArea._lc("Background","TableOperations")+":";
td=doc.createElement("td");
tr.appendChild(td);
var df=TableOperations.createColorButton(doc,_87,el.style.backgroundColor,"backgroundColor");
df.firstChild.nextSibling.style.marginRight="0.5em";
td.appendChild(df);
td.appendChild(doc.createTextNode(HTMLArea._lc("Image URL","TableOperations")+": "));
input=doc.createElement("input");
input.type="text";
input.name="f_st_backgroundImage";
if(el.style.backgroundImage.match(/url\(\s*(.*?)\s*\)/)){
input.value=RegExp.$1;
}
td.appendChild(input);
tr=doc.createElement("tr");
_8c.appendChild(tr);
td=doc.createElement("td");
tr.appendChild(td);
td.className="label";
td.innerHTML=HTMLArea._lc("FG Color","TableOperations")+":";
td=doc.createElement("td");
tr.appendChild(td);
td.appendChild(TableOperations.createColorButton(doc,_87,el.style.color,"color"));
input=doc.createElement("input");
input.style.visibility="hidden";
input.type="text";
td.appendChild(input);
tr=doc.createElement("tr");
_8c.appendChild(tr);
td=doc.createElement("td");
tr.appendChild(td);
td.className="label";
td.innerHTML=HTMLArea._lc("Border","TableOperations")+":";
td=doc.createElement("td");
tr.appendChild(td);
var _8f=TableOperations.createColorButton(doc,_87,el.style.borderColor,"borderColor");
var btn=_8f.firstChild.nextSibling;
td.appendChild(_8f);
btn.style.marginRight="0.5em";
select=doc.createElement("select");
var _91=[];
td.appendChild(select);
select.name="f_st_borderStyle";
options=["none","dotted","dashed","solid","double","groove","ridge","inset","outset"];
var _92=el.style.borderStyle;
(_92.match(/([^\s]*)\s/))&&(_92=RegExp.$1);
for(var i in options){
if(typeof options[i]=="function"){
continue;
}
var val=options[i];
option=doc.createElement("option");
option.value=val;
option.innerHTML=val;
(val==_92)&&(option.selected=true);
select.appendChild(option);
}
select.style.marginRight="0.5em";
function setBorderFieldsStatus(_95){
for(var i=0;i<_91.length;++i){
var el=_91[i];
el.style.visibility=_95?"hidden":"visible";
if(!_95&&(el.tagName.toLowerCase()=="input")){
el.focus();
el.select();
}
}
}
select.onchange=function(){
setBorderFieldsStatus(this.value=="none");
};
input=doc.createElement("input");
_91.push(input);
input.type="text";
input.name="f_st_borderWidth";
input.value=TableOperations.getLength(el.style.borderWidth);
input.size="5";
td.appendChild(input);
input.style.marginRight="0.5em";
var _98=doc.createElement("span");
_98.innerHTML=HTMLArea._lc("pixels","TableOperations");
td.appendChild(_98);
_91.push(_98);
setBorderFieldsStatus(select.value=="none");
if(el.tagName.toLowerCase()=="table"){
tr=doc.createElement("tr");
_8c.appendChild(tr);
td=doc.createElement("td");
td.className="label";
tr.appendChild(td);
input=doc.createElement("input");
input.type="checkbox";
input.name="f_st_borderCollapse";
input.id="f_st_borderCollapse";
var val=(/collapse/i.test(el.style.borderCollapse));
input.checked=val?1:0;
td.appendChild(input);
td=doc.createElement("td");
tr.appendChild(td);
var _99=doc.createElement("label");
_99.htmlFor="f_st_borderCollapse";
_99.innerHTML=HTMLArea._lc("Collapsed borders","TableOperations");
td.appendChild(_99);
}
return _89;
};

