// ===================================================================
// Author: Matt Kruse <matt@mattkruse.com>
// WWW: http://www.mattkruse.com/
//
// NOTICE: Matt kindly gave OpenACS permission to incorporate his code.
// Details are here: http://openacs.org/forums/message-view?message_id=284521
// I'm leaving in his original notice below.  AG.
//
// NOTICE: You may use this code for any purpose, commercial or
// private, without any further permission from the author. You may
// remove this notice from your final code if you wish, however it is
// appreciated by the author if at least my web site address is kept.
//
// You may *NOT* re-distribute this code in any way except through its
// use. That means, you can include it in your product, or your web
// site, or any other form where the code is actually being used. You
// may not put the plain javascript up on your site for download or
// include it in your javascript libraries for download. 
// If you wish to share this code with others, please just point them
// to the URL instead.
// Please DO NOT link directly to my .js files from your site. Copy
// the files to your server and use them there. Thank you.
// ===================================================================

// HISTORY
// ------------------------------------------------------------------
// December 9, 2003: Added script to the Javascript Toolbox
// December 10, 2003: Added the preProcessTrees variable to allow user
//      to turn off automatic conversion of UL's onLoad
// March 1, 2004: Changed it so if a <li> has a class already attached
//      to it, that class won't be erased when initialized. This allows
//      you to set the state of the tree when painting the page simply
//      by setting some <li>'s class name as being "liOpen" (see example)
// March 29, 2005: Added cookie-managed state (AG).
// May 16, 2005: don't register 'convertTrees' multiple times (GN)
/*
This code is inspired by and extended from Stuart Langridge's aqlist code:
		http://www.kryogenix.org/code/browser/aqlists/
		Stuart Langridge, November 2002
		sil@kryogenix.org
		Inspired by Aaron's labels.js (http://youngpup.net/demos/labels/) 
		and Dave Lindquist's menuDropDown.js (http://www.gazingus.org/dhtml/?id=109)
*/

// Automatically attach a listener to the window onload, to convert the trees
// Register the event only once. if registered multiple times, the items are rendered
// with multiple + or - signs....     -gustaf neumann

if (typeof mktree_registered == 'undefined') {
  addEvent(window,"load",convertTrees);
  var mktree_registered = 1;
}

if (typeof mktree_remember == 'undefined') {
    var mktree_remember = false;
}

// Utility function to add an event listener
function addEvent(o,e,f){
	if (o.addEventListener){ o.addEventListener(e,f,true); return true; }
	else if (o.attachEvent){ return o.attachEvent("on"+e,f); }
	else { return false; }
}

function removeEvent( obj, type, fn ) {
   if (obj.removeEventListener) {
      obj.removeEventListener( type, fn, false );
   } else if (obj.detachEvent) {
      obj.detachEvent( "on"+type, obj[type+fn] );
      obj[type+fn] = null;
      obj["e"+type+fn] = null;
   }
}


// utility function to set a global variable if it is not already set
function setDefault(name,val) {
	if (typeof(window[name])=="undefined" || window[name]==null) {
		window[name]=val;
	}
}

// Full expands a tree with a given ID
function expandTree(treeId) {
	var ul = document.getElementById(treeId);
	if (ul == null) { return false; }
	expandCollapseList(ul,nodeOpenClass);
}

// Fully collapses a tree with a given ID
function collapseTree(treeId) {
	var ul = document.getElementById(treeId);
	if (ul == null) { return false; }
	expandCollapseList(ul,nodeClosedClass);
}

// Expands enough nodes to expose an LI with a given ID
function expandToItem(treeId,itemId) {
	var ul = document.getElementById(treeId);
	if (ul == null) { return false; }
	var ret = expandCollapseList(ul,nodeOpenClass,itemId);
	if (ret) {
		var o = document.getElementById(itemId);
		if (o.scrollIntoView) {
			o.scrollIntoView(false);
		}
	}
}

// Performs 3 functions:
// a) Expand all nodes
// b) Collapse all nodes
// c) Expand all nodes to reach a certain ID
function expandCollapseList(ul,cName,itemId) {
	if (!ul.childNodes || ul.childNodes.length==0) { return false; }
	// Iterate LIs
	for (var itemi=0;itemi<ul.childNodes.length;itemi++) {
		var item = ul.childNodes[itemi];
		if (itemId!=null && item.id==itemId) { return true; }
		if (item.nodeName == "LI") {
			// Iterate things in this LI
			var subLists = false;
			for (var sitemi=0;sitemi<item.childNodes.length;sitemi++) {
				var sitem = item.childNodes[sitemi];
				if (sitem.nodeName=="UL") {
					subLists = true;
					var ret = expandCollapseList(sitem,cName,itemId);
					if (itemId!=null && ret) {
						item.className=cName;
						return true;
					}
				}
			}
			if (subLists && itemId==null) {
				item.className = cName;
			}
		}
	}
}

// Search the document for UL elements with the correct CLASS name, then process them
function convertTrees() {
  // this is a check in opera to avoid multiple renderings
    if (typeof window.treeClass != 'undefined') {
	  return;
	}
	setDefault("treeClass","mktree");
	setDefault("nodeClosedClass","liClosed");
	setDefault("nodeOpenClass","liOpen");
	setDefault("nodeBulletClass","liBullet");
	setDefault("nodeLinkClass","bullet");
	setDefault("preProcessTrees",true);
	if (preProcessTrees) {
		if (!document.createElement) { return; } // Without createElement, we can't do anything
		uls = document.getElementsByTagName("ul");
		for (var uli=0;uli<uls.length;uli++) {
			var ul=uls[uli];
			if (ul.nodeName=="UL" && ul.className==treeClass) {
				processList(ul);
			}
		}
	}
}

// Process a UL tag and all its children, to convert to a tree
function processList(ul) {
	if (!ul.childNodes || ul.childNodes.length==0) { return; }
	// Iterate LIs
	for (var itemi=0;itemi<ul.childNodes.length;itemi++) {
		var item = ul.childNodes[itemi];
		if (item.nodeName == "LI") {
			// Iterate things in this LI
			var subLists = false;
			for (var sitemi=0;sitemi<item.childNodes.length;sitemi++) {
				var sitem = item.childNodes[sitemi];
				if (sitem.nodeName=="UL") {
					subLists = true;
					processList(sitem);
				}
			}
			var s= document.createElement("SPAN");
			var t= '\u00A0'; // &nbsp;
			s.className = nodeLinkClass;
			if (subLists) {
				// This LI has UL's in it, so it's a +/- node
				if (item.className==null || item.className=="") {
                    if (rememberCookieP(item) &&
                      getCookie("mktree-" + item.getAttribute("id"))) {
                        item.className = getCookie("mktree-" + item.getAttribute("id"));
                    } else {
                        item.className = nodeClosedClass;
                    }
				}
				// If it's just text, make the text work as the link also
				if (item.firstChild.nodeName=="#text") {
					t = t+item.firstChild.nodeValue;
					item.removeChild(item.firstChild);
				}
				s.onclick = function () {
					this.parentNode.className = (this.parentNode.className==nodeOpenClass) ? nodeClosedClass : nodeOpenClass;
                    if (rememberCookieP(this.parentNode)) {
                       var today = new Date();
                       var expire = new Date();
                       expire.setTime(today.getTime() + 3600000*24*3650);
                       setCookie(
                         "mktree-" + this.parentNode.getAttribute("id"),
                         this.parentNode.className,
                         expire
                       );
                    }
					return false;
				}
			}
			else {
				// No sublists, so it's just a bullet node
				item.className = nodeBulletClass;
				s.onclick = function () { return false; }
			}
			s.appendChild(document.createTextNode(t));
			item.insertBefore(s,item.firstChild);
		}
	}
}

//These cookie functions are by AG

function rememberCookieP(node) {

    var treeId = node.getAttribute("id");

    if ( treeId && mktree_remember ) {
        return ( document.getElementById(treeId) != null );
    } else {
        return false;
    }

}


//These cookie functions are from 
//http://www.webreference.com/js/column8/functions.html

/*
   name - name of the cookie
   value - value of the cookie
   [expires] - expiration date of the cookie
     (defaults to end of current session)
   [path] - path for which the cookie is valid
     (defaults to path of calling document)
   [domain] - domain for which the cookie is valid
     (defaults to domain of calling document)
   [secure] - Boolean value indicating if the cookie transmission requires
     a secure transmission
   * an argument defaults when it is assigned null as a placeholder
   * a null placeholder is not required for trailing omitted arguments
*/

function setCookie(name, value, expires, path, domain, secure) {
  var curCookie = name + "=" + escape(value) +
      ((expires) ? "; expires=" + expires.toGMTString() : "") +
      ((path) ? "; path=" + path : "") +
      ((domain) ? "; domain=" + domain : "") +
      ((secure) ? "; secure" : "");
  document.cookie = curCookie;
}


/*
  name - name of the desired cookie
  return string containing value of specified cookie or null
  if cookie does not exist
*/

function getCookie(name) {
  var dc = document.cookie;
  var prefix = name + "=";
  var begin = dc.indexOf("; " + prefix);
  if (begin == -1) {
    begin = dc.indexOf(prefix);
    if (begin != 0) return null;
  } else
    begin += 2;
  var end = document.cookie.indexOf(";", begin);
  if (end == -1)
    end = dc.length;
  return unescape(dc.substring(begin + prefix.length, end));
}
