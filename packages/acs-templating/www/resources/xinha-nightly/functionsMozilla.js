
  /*--------------------------------------:noTabs=true:tabSize=2:indentSize=2:--
    --  Xinha (is not htmlArea) - http://xinha.gogo.co.nz/
    --
    --  Use of Xinha is granted by the terms of the htmlArea License (based on
    --  BSD license)  please read license.txt in this package for details.
    --
    --  Xinha was originally based on work by Mihai Bazon which is:
    --      Copyright (c) 2003-2004 dynarch.com.
    --      Copyright (c) 2002-2003 interactivetools.com, inc.
    --      This copyright notice MUST stay intact for use.
    --
    -- This is the Gecko compatability plugin, part of the Xinha core.
    --
    --  The file is loaded as a special plugin by the Xinha Core when
    --  Xinha is being run under a Gecko based browser with the Midas
    --  editing API.
    --
    --  It provides implementation and specialisation for various methods
    --  in the core where different approaches per browser are required.
    --
    --  Design Notes::
    --   Most methods here will simply be overriding Xinha.prototype.<method>
    --   and should be called that, but methods specific to Gecko should 
    --   be a part of the Gecko.prototype, we won't trample on namespace
    --   that way.
    --
    --  $HeadURL: http://svn.xinha.python-hosting.com/trunk/functionsMozilla.js $
    --  $LastChangedDate: 2007-01-22 15:29:11 +1300 (Mon, 22 Jan 2007) $
    --  $LastChangedRevision: 682 $
    --  $LastChangedBy: ray $
    --------------------------------------------------------------------------*/
                                                    
Gecko._pluginInfo = {
  name          : "Gecko",
  origin        : "Xinha Core",
  version       : "$LastChangedRevision: 682 $".replace(/^[^:]*: (.*) \$$/, '$1'),
  developer     : "The Xinha Core Developer Team",
  developer_url : "$HeadURL: http://svn.xinha.python-hosting.com/trunk/functionsMozilla.js $".replace(/^[^:]*: (.*) \$$/, '$1'),
  license       : "htmlArea"
};

function Gecko(editor) {
  this.editor = editor;  
  editor.Gecko = this;
}

/** Allow Gecko to handle some key events in a special way.
 */
  
Gecko.prototype.onKeyPress = function(ev)
{
  var editor = this.editor;
  var s = editor.getSelection();
  
  // Handle shortcuts
  if(editor.isShortCut(ev))
  {
    switch(editor.getKey(ev).toLowerCase())
    {
      case 'z':
      {
        if(editor._unLink && editor._unlinkOnUndo)
        {
          Xinha._stopEvent(ev);
          editor._unLink();
          editor.updateToolbar();
          return true;
        }
      }
      break;
      
      case 'a':
      {
        // KEY select all
        sel = editor.getSelection();
        sel.removeAllRanges();
        range = editor.createRange();
        range.selectNodeContents(editor._doc.body);
        sel.addRange(range);
        Xinha._stopEvent(ev);
        return true;
      }
      break;
      
      case 'v':
      {
        // If we are not using htmlareaPaste, don't let Xinha try and be fancy but let the 
        // event be handled normally by the browser (don't stopEvent it)
        if(!editor.config.htmlareaPaste)
        {          
          return true;
        }
      }
      break;
    }
  }
  
  // Handle normal characters
  switch(editor.getKey(ev))
  {
    // Space, see if the text just typed looks like a URL, or email address
    // and link it appropriatly
    case ' ':
    {      
      var autoWrap = function (textNode, tag)
      {
        var rightText = textNode.nextSibling;
        if ( typeof tag == 'string')
        {
          tag = editor._doc.createElement(tag);
        }
        var a = textNode.parentNode.insertBefore(tag, rightText);
        Xinha.removeFromParent(textNode);
        a.appendChild(textNode);
        rightText.data = ' ' + rightText.data;
    
        s.collapse(rightText, 1);
    
        editor._unLink = function()
        {
          var t = a.firstChild;
          a.removeChild(t);
          a.parentNode.insertBefore(t, a);
          Xinha.removeFromParent(a);
          editor._unLink = null;
          editor._unlinkOnUndo = false;
        };
        editor._unlinkOnUndo = true;
    
        return a;
      };
  
      if ( editor.config.convertUrlsToLinks && s && s.isCollapsed && s.anchorNode.nodeType == 3 && s.anchorNode.data.length > 3 && s.anchorNode.data.indexOf('.') >= 0 )
      {
        var midStart = s.anchorNode.data.substring(0,s.anchorOffset).search(/\S{4,}$/);
        if ( midStart == -1 )
        {
          break;
        }

        if ( editor._getFirstAncestor(s, 'a') )
        {
          break; // already in an anchor
        }

        var matchData = s.anchorNode.data.substring(0,s.anchorOffset).replace(/^.*?(\S*)$/, '$1');

        var mEmail = matchData.match(Xinha.RE_email);
        if ( mEmail )
        {
          var leftTextEmail  = s.anchorNode;
          var rightTextEmail = leftTextEmail.splitText(s.anchorOffset);
          var midTextEmail   = leftTextEmail.splitText(midStart);

          autoWrap(midTextEmail, 'a').href = 'mailto:' + mEmail[0];
          break;
        }

        RE_date = /([0-9]+\.)+/; //could be date or ip or something else ...
        RE_ip = /(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/;
        var mUrl = matchData.match(Xinha.RE_url);
        if ( mUrl )
        {
          if (RE_date.test(matchData))
          {
            if (!RE_ip.test(matchData)) 
            {
              break;
            }
          } 
          var leftTextUrl  = s.anchorNode;
          var rightTextUrl = leftTextUrl.splitText(s.anchorOffset);
          var midTextUrl   = leftTextUrl.splitText(midStart);
          autoWrap(midTextUrl, 'a').href = (mUrl[1] ? mUrl[1] : 'http://') + mUrl[2];
          break;
        }
      }
    }
    break;    
  }
  
  // Handle special keys
  switch ( ev.keyCode )
  {    
    case 13: // ENTER
      if( !ev.shiftKey && editor.config.mozParaHandler == 'dirty' )
      {
        this.dom_checkInsertP();
        Xinha._stopEvent(ev);
      }
    break;

    case 27: // ESCAPE
    {
      if ( editor._unLink )
      {
        editor._unLink();
        Xinha._stopEvent(ev);
      }
      break;
    }
    break;
    
    case 8: // KEY backspace
    case 46: // KEY delete
    {
      // We handle the mozilla backspace directly??
      if ( !ev.shiftKey && this.handleBackspace() )
      {
        Xinha._stopEvent(ev);
      }
    }
    
    default:
    {
        editor._unlinkOnUndo = false;

        // Handle the "auto-linking", specifically this bit of code sets up a handler on
        // an self-titled anchor (eg <a href="http://www.gogo.co.nz/">www.gogo.co.nz</a>)
        // when the text content is edited, such that it will update the href on the anchor
        
        if ( s.anchorNode && s.anchorNode.nodeType == 3 )
        {
          // See if we might be changing a link
          var a = editor._getFirstAncestor(s, 'a');
          // @todo: we probably need here to inform the setTimeout below that we not changing a link and not start another setTimeout
          if ( !a )
          {
            break; // not an anchor
          } 
          
          if ( !a._updateAnchTimeout )
          {
            if ( s.anchorNode.data.match(Xinha.RE_email) && a.href.match('mailto:' + s.anchorNode.data.trim()) )
            {
              var textNode = s.anchorNode;
              var fnAnchor = function()
              {
                a.href = 'mailto:' + textNode.data.trim();
                // @fixme: why the hell do another timeout is started ?
                //         This lead to never ending timer if we dont remove this line
                //         But when removed, the email is not correctly updated
                //
                // - to fix this we should make fnAnchor check to see if textNode.data has
                //   stopped changing for say 5 seconds and if so we do not make this setTimeout 
                a._updateAnchTimeout = setTimeout(fnAnchor, 250);
              };
              a._updateAnchTimeout = setTimeout(fnAnchor, 1000);
              break;
            }

            var m = s.anchorNode.data.match(Xinha.RE_url);
            if ( m && a.href.match(s.anchorNode.data.trim()) )
            {
              var txtNode = s.anchorNode;
              var fnUrl = function()
              {
                // Sometimes m is undefined becase the url is not an url anymore (was www.url.com and become for example www.url)
                m = txtNode.data.match(Xinha.RE_url);
                if(m)
                {
                  a.href = (m[1] ? m[1] : 'http://') + m[2];
                }
                
                // @fixme: why the hell do another timeout is started ?
                //         This lead to never ending timer if we dont remove this line
                //         But when removed, the url is not correctly updated
                //
                // - to fix this we should make fnUrl check to see if textNode.data has
                //   stopped changing for say 5 seconds and if so we do not make this setTimeout
                a._updateAnchTimeout = setTimeout(fnUrl, 250);
              };
              a._updateAnchTimeout = setTimeout(fnUrl, 1000);
            }
          }        
        }                
    }
    break;
  }

  return false; // Let other plugins etc continue from here.
}

/** When backspace is hit, the Gecko onKeyPress will execute this method.
 *  I don't remember what the exact purpose of this is though :-(
 */
 
Gecko.prototype.handleBackspace = function()
{
  var editor = this.editor;
  setTimeout(
    function()
    {
      var sel   = editor.getSelection();
      var range = editor.createRange(sel);
      var SC = range.startContainer;
      var SO = range.startOffset;
      var EC = range.endContainer;
      var EO = range.endOffset;
      var newr = SC.nextSibling;
      if ( SC.nodeType == 3 )
      {
        SC = SC.parentNode;
      }
      if ( ! ( /\S/.test(SC.tagName) ) )
      {
        var p = document.createElement("p");
        while ( SC.firstChild )
        {
          p.appendChild(SC.firstChild);
        }
        SC.parentNode.insertBefore(p, SC);
        Xinha.removeFromParent(SC);
        var r = range.cloneRange();
        r.setStartBefore(newr);
        r.setEndAfter(newr);
        r.extractContents();
        sel.removeAllRanges();
        sel.addRange(r);
      }
    },
    10);
};
/** The idea here is
 * 1. See if we are in a block element
 * 2. If we are not, then wrap the current "block" of text into a paragraph
 * 3. Now that we have a block element, select all the text between the insertion point
 *    and just AFTER the end of the block
 *    eg <p>The quick |brown fox jumped over the lazy dog.</p>|
 *                     ---------------------------------------
 * 4. Extract that from the document, making
 *       <p>The quick </p>
 *    and a document fragment with
 *       <p>brown fox jumped over the lazy dog.</p>
 * 5. Reinsert it just after the block element
 *       <p>The quick </p><p>brown fox jumped over the lazy dog.</p>
 *
 * Along the way, allow inserting blank paragraphs, which will look like <p><br/></p>
 */

Gecko.prototype.dom_checkInsertP = function()
{
  var editor = this.editor;
  var p, body;
  // Get the insertion point, we'll scrub any highlighted text the user wants rid of while we are there.
  var sel = editor.getSelection();
  var range = editor.createRange(sel);
  if ( !range.collapsed )
  {
    range.deleteContents();
  }
  editor.deactivateEditor();
  //sel.removeAllRanges();
  //sel.addRange(range);

  var SC = range.startContainer;
  var SO = range.startOffset;
  var EC = range.endContainer;
  var EO = range.endOffset;

  // If the insertion point is character 0 of the
  // document, then insert a space character that we will wrap into a paragraph
  // in a bit.
  if ( SC == EC && SC == body && !SO && !EO )
  {
    p = editor._doc.createTextNode(" ");
    body.insertBefore(p, body.firstChild);
    range.selectNodeContents(p);
    SC = range.startContainer;
    SO = range.startOffset;
    EC = range.endContainer;
    EO = range.endOffset;
  }

  // See if we are in a block element, if so, great.
  p = editor.getAllAncestors();

  var block = null;
  body = editor._doc.body;
  for ( var i = 0; i < p.length; ++i )
  {
    if ( Xinha.isParaContainer(p[i]) )
    {
      break;
    }
    else if ( Xinha.isBlockElement(p[i]) && ! ( /body|html/i.test(p[i].tagName) ) )
    {
      block = p[i];
      break;
    }
  }

  // If not in a block element, we'll have to turn some stuff into a paragraph
  if ( !block )
  {
    // We want to wrap as much stuff as possible into the paragraph in both directions
    // from the insertion point.  We start with the start container and walk back up to the
    // node just before any of the paragraph containers.
    var wrap = range.startContainer;
    while ( wrap.parentNode && !Xinha.isParaContainer(wrap.parentNode) )
    {
      wrap = wrap.parentNode;
    }
    var start = wrap;
    var end   = wrap;

    // Now we walk up the sibling list until we hit the top of the document
    // or an element that we shouldn't put in a p (eg other p, div, ul, ol, table)
    while ( start.previousSibling )
    {
      if ( start.previousSibling.tagName )
      {
        if ( !Xinha.isBlockElement(start.previousSibling) )
        {
          start = start.previousSibling;
        }
        else
        {
          break;
        }
      }
      else
      {
        start = start.previousSibling;
      }
    }

    // Same down the list
    while ( end.nextSibling )
    {
      if ( end.nextSibling.tagName )
      {
        if ( !Xinha.isBlockElement(end.nextSibling) )
        {
          end = end.nextSibling;
        }
        else
        {
          break;
        }
      }
      else
      {
        end = end.nextSibling;
      }
    }

    // Select the entire block
    range.setStartBefore(start);
    range.setEndAfter(end);

    // Make it a paragraph
    range.surroundContents(editor._doc.createElement('p'));

    // Which becomes the block element
    block = range.startContainer.firstChild;

    // And finally reset the insertion point to where it was originally
    range.setStart(SC, SO);
  }

  // The start point is the insertion point, so just move the end point to immediatly
  // after the block
  range.setEndAfter(block);

  // Extract the range, to split the block
  // If we just did range.extractContents() then Mozilla does wierd stuff
  // with selections, but if we clone, then remove the original range and extract
  // the clone, it's quite happy.
  var r2 = range.cloneRange();
  sel.removeRange(range);
  var df = r2.extractContents();

  if ( df.childNodes.length === 0 )
  {
    df.appendChild(editor._doc.createElement('p'));
    df.firstChild.appendChild(editor._doc.createElement('br'));
  }

  if ( df.childNodes.length > 1 )
  {
    var nb = editor._doc.createElement('p');
    while ( df.firstChild )
    {
      var s = df.firstChild;
      df.removeChild(s);
      nb.appendChild(s);
    }
    df.appendChild(nb);
  }

  // If the original block is empty, put a &nsbp; in it.
  // @fixme: why using a regex instead of : if (block.innerHTML.trim() == '') ?
  if ( ! ( /\S/.test(block.innerHTML) ) )
  {
    block.innerHTML = "&nbsp;";
  }

  p = df.firstChild;
  // @fixme: why using a regex instead of : if (p.innerHTML.trim() == '') ?
  if ( ! ( /\S/.test(p.innerHTML) ) )
  {
    p.innerHTML = "<br />";
  }

  // If the new block is empty and it's a heading, make it a paragraph
  // note, the new block is empty when you are hitting enter at the end of the existing block
  if ( ( /^\s*<br\s*\/?>\s*$/.test(p.innerHTML) ) && ( /^h[1-6]$/i.test(p.tagName) ) )
  {
    df.appendChild(editor.convertNode(p, "p"));
    df.removeChild(p);
  }

  var newblock = block.parentNode.insertBefore(df.firstChild, block.nextSibling);

  // Select the range (to set the insertion)
  // collapse to the start of the new block
  //  (remember the block might be <p><br/></p>, so if we collapsed to the end the <br/> would be noticable)

  //range.selectNode(newblock.firstChild);
  //range.collapse(true);

  editor.activateEditor();

  sel = editor.getSelection();
  sel.removeAllRanges();
  sel.collapse(newblock,0);

  // scroll into view
  editor.scrollToElement(newblock);

  //editor.forceRedraw();

};

Gecko.prototype.inwardHtml = function(html)
{
   // Midas uses b and i internally instead of strong and em
   // Xinha will use strong and em externally (see Xinha.prototype.outwardHtml)   
   html = html.replace(/<(\/?)strong(\s|>|\/)/ig, "<$1b$2");
   html = html.replace(/<(\/?)em(\s|>|\/)/ig, "<$1i$2");    
   
   // Both IE and Gecko use strike internally instead of del (#523)
   // Xinha will present del externally (see Xinha.prototype.outwardHtml
   html = html.replace(/<(\/?)del(\s|>|\/)/ig, "<$1strike$2");
   
   return html;
}

Gecko.prototype.outwardHtml = function(html)
{
  // ticket:56, the "greesemonkey" plugin for Firefox adds this junk,
  // so we strip it out.  Original submitter gave a plugin, but that's
  // a bit much just for this IMHO - james
  html = html.replace(/<script[\s]*src[\s]*=[\s]*['"]chrome:\/\/.*?["']>[\s]*<\/script>/ig, '');

  return html;
}

Gecko.prototype.onExecCommand = function(cmdID, UI, param)
{   
  try
  {
    // useCSS deprecated & replaced by styleWithCSS
    this.editor._doc.execCommand('useCSS', false, true); //switch useCSS off (true=off)
    this.editor._doc.execCommand('styleWithCSS', false, false); //switch styleWithCSS off     
  } catch (ex) {}
    
  switch(cmdID)
  {
    case 'paste':
    {
      alert(Xinha._lc("The Paste button does not work in Mozilla based web browsers (technical security reasons). Press CTRL-V on your keyboard to paste directly."));
      return true; // Indicate paste is done, stop command being issued to browser by Xinha.prototype.execCommand
    }
  }
  
  return false;
}


/*--------------------------------------------------------------------------*/
/*------- IMPLEMENTATION OF THE ABSTRACT "Xinha.prototype" METHODS ---------*/
/*--------------------------------------------------------------------------*/

/** Insert a node at the current selection point. 
 * @param toBeInserted DomNode
 */

Xinha.prototype.insertNodeAtSelection = function(toBeInserted)
{
  var sel = this.getSelection();
  var range = this.createRange(sel);
  // remove the current selection
  sel.removeAllRanges();
  range.deleteContents();
  var node = range.startContainer;
  var pos = range.startOffset;
  var selnode = toBeInserted;
  switch ( node.nodeType )
  {
    case 3: // Node.TEXT_NODE
      // we have to split it at the caret position.
      if ( toBeInserted.nodeType == 3 )
      {
        // do optimized insertion
        node.insertData(pos, toBeInserted.data);
        range = this.createRange();
        range.setEnd(node, pos + toBeInserted.length);
        range.setStart(node, pos + toBeInserted.length);
        sel.addRange(range);
      }
      else
      {
        node = node.splitText(pos);
        if ( toBeInserted.nodeType == 11 /* Node.DOCUMENT_FRAGMENT_NODE */ )
        {
          selnode = selnode.firstChild;
        }
        node.parentNode.insertBefore(toBeInserted, node);
        this.selectNodeContents(selnode);
        this.updateToolbar();
      }
    break;
    case 1: // Node.ELEMENT_NODE
      if ( toBeInserted.nodeType == 11 /* Node.DOCUMENT_FRAGMENT_NODE */ )
      {
        selnode = selnode.firstChild;
      }
      node.insertBefore(toBeInserted, node.childNodes[pos]);
      this.selectNodeContents(selnode);
      this.updateToolbar();
    break;
  }
};
  
/** Get the parent element of the supplied or current selection. 
 *  @param   sel optional selection as returned by getSelection
 *  @returns DomNode
 */
 
Xinha.prototype.getParentElement = function(sel)
{
  if ( typeof sel == 'undefined' )
  {
    sel = this.getSelection();
  }
  var range = this.createRange(sel);
  try
  {
    var p = range.commonAncestorContainer;
    if ( !range.collapsed && range.startContainer == range.endContainer &&
        range.startOffset - range.endOffset <= 1 && range.startContainer.hasChildNodes() )
    {
      p = range.startContainer.childNodes[range.startOffset];
    }

    while ( p.nodeType == 3 )
    {
      p = p.parentNode;
    }
    return p;
  }
  catch (ex)
  {
    return null;
  }
};

/**
 * Returns the selected element, if any.  That is,
 * the element that you have last selected in the "path"
 * at the bottom of the editor, or a "control" (eg image)
 *
 * @returns null | DomNode
 */

Xinha.prototype.activeElement = function(sel)
{
  if ( ( sel === null ) || this.selectionEmpty(sel) )
  {
    return null;
  }

  // For Mozilla we just see if the selection is not collapsed (something is selected)
  // and that the anchor (start of selection) is an element.  This might not be totally
  // correct, we possibly should do a simlar check to IE?
  if ( !sel.isCollapsed )
  {      
    if ( sel.anchorNode.childNodes.length > sel.anchorOffset && sel.anchorNode.childNodes[sel.anchorOffset].nodeType == 1 )
    {
      return sel.anchorNode.childNodes[sel.anchorOffset];
    }
    else if ( sel.anchorNode.nodeType == 1 )
    {
      return sel.anchorNode;
    }
    else
    {
      return null; // return sel.anchorNode.parentNode;
    }
  }
  return null;
};

/** 
 * Determines if the given selection is empty (collapsed).
 * @param selection Selection object as returned by getSelection
 * @returns true|false
 */
 
Xinha.prototype.selectionEmpty = function(sel)
{
  if ( !sel )
  {
    return true;
  }

  if ( typeof sel.isCollapsed != 'undefined' )
  {      
    return sel.isCollapsed;
  }

  return true;
};


/**
 * Selects the contents of the given node.  If the node is a "control" type element, (image, form input, table)
 * the node itself is selected for manipulation.
 *
 * @param node DomNode 
 * @param pos  Set to a numeric position inside the node to collapse the cursor here if possible. 
 */
 
Xinha.prototype.selectNodeContents = function(node, pos)
{
  this.focusEditor();
  this.forceRedraw();
  var range;
  var collapsed = typeof pos == "undefined" ? true : false;
  var sel = this.getSelection();
  range = this._doc.createRange();
  // Tables and Images get selected as "objects" rather than the text contents
  if ( collapsed && node.tagName && node.tagName.toLowerCase().match(/table|img|input|textarea|select/) )
  {
    range.selectNode(node);
  }
  else
  {
    range.selectNodeContents(node);
    //(collapsed) && range.collapse(pos);
  }
  sel.removeAllRanges();
  sel.addRange(range);
};
  
/** Insert HTML at the current position, deleting the selection if any. 
 *  
 *  @param html string
 */
 
Xinha.prototype.insertHTML = function(html)
{
  var sel = this.getSelection();
  var range = this.createRange(sel);
  this.focusEditor();
  // construct a new document fragment with the given HTML
  var fragment = this._doc.createDocumentFragment();
  var div = this._doc.createElement("div");
  div.innerHTML = html;
  while ( div.firstChild )
  {
    // the following call also removes the node from div
    fragment.appendChild(div.firstChild);
  }
  // this also removes the selection
  var node = this.insertNodeAtSelection(fragment);
};

/** Get the HTML of the current selection.  HTML returned has not been passed through outwardHTML.
 *
 * @returns string
 */
 
Xinha.prototype.getSelectedHTML = function()
{
  var sel = this.getSelection();
  var range = this.createRange(sel);
  return Xinha.getHTML(range.cloneContents(), false, this);
};
  

/** Get a Selection object of the current selection.  Note that selection objects are browser specific.
 *
 * @returns Selection
 */
 
Xinha.prototype.getSelection = function()
{
  return this._iframe.contentWindow.getSelection();
};
  
/** Create a Range object from the given selection.  Note that range objects are browser specific.
 *
 *  @param sel Selection object (see getSelection)
 *  @returns Range
 */
 
Xinha.prototype.createRange = function(sel)
{
  this.activateEditor();
  if ( typeof sel != "undefined" )
  {
    try
    {
      return sel.getRangeAt(0);
    }
    catch(ex)
    {
      return this._doc.createRange();
    }
  }
  else
  {
    return this._doc.createRange();
  }
};

/** Determine if the given event object is a keydown/press event.
 *
 *  @param event Event 
 *  @returns true|false
 */
 
Xinha.prototype.isKeyEvent = function(event)
{
  return event.type == "keypress";
}

/** Return the character (as a string) of a keyEvent  - ie, press the 'a' key and
 *  this method will return 'a', press SHIFT-a and it will return 'A'.
 * 
 *  @param   keyEvent
 *  @returns string
 */
                                   
Xinha.prototype.getKey = function(keyEvent)
{
  return String.fromCharCode(keyEvent.charCode);
}

/** Return the HTML string of the given Element, including the Element.
 * 
 * @param element HTML Element DomNode
 * @returns string
 */
 
Xinha.getOuterHTML = function(element)
{
  return (new XMLSerializer()).serializeToString(element);
};

/*--------------------------------------------------------------------------*/
/*------------ EXTEND SOME STANDARD "Xinha.prototype" METHODS --------------*/
/*--------------------------------------------------------------------------*/

Xinha.prototype._standardToggleBorders = Xinha.prototype._toggleBorders;
Xinha.prototype._toggleBorders = function()
{
  var result = Xinha.prototype._standardToggleBorders();
  
  // flashing the display forces moz to listen (JB:18-04-2005) - #102
  var tables = this._doc.getElementByTagName('TABLE');
  for(var i = 0; i < tables.length; i++)
  {
    tables[i].style.display="none";
    tables[i].style.display="table";
  }
  
  return result;
}