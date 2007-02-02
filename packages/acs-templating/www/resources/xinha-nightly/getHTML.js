
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
    --  This is the standard implementation of the method for rendering HTML code from the DOM
    --
    --  The file is loaded by the Xinha Core when no alternative method (plugin) is loaded.
    --
    --
    --  $HeadURL: http://svn.xinha.python-hosting.com/trunk/getHTML.js $
    --  $LastChangedDate: 2007-01-22 10:15:13 +1300 (Mon, 22 Jan 2007) $
    --  $LastChangedRevision: 678 $
    --  $LastChangedBy: ray $
    --------------------------------------------------------------------------*/

// Retrieves the HTML code from the given node.	 This is a replacement for
// getting innerHTML, using standard DOM calls.
// Wrapper catch a Mozilla-Exception with non well formed html source code
Xinha.getHTML = function(root, outputRoot, editor)
{
  try
  {
    return Xinha.getHTMLWrapper(root,outputRoot,editor);
  }
  catch(ex)
  {   
    alert(Xinha._lc('Your Document is not well formed. Check JavaScript console for details.'));
    return editor._iframe.contentWindow.document.body.innerHTML;
  }
};

Xinha.getHTMLWrapper = function(root, outputRoot, editor, indent)
{
  var html = "";
  if ( !indent )
  {
    indent = '';
  }

  switch ( root.nodeType )
  {
    case 10:// Node.DOCUMENT_TYPE_NODE
    case 6: // Node.ENTITY_NODE
    case 12:// Node.NOTATION_NODE
      // this all are for the document type, probably not necessary
    break;

    case 2: // Node.ATTRIBUTE_NODE
      // Never get here, this has to be handled in the ELEMENT case because
      // of IE crapness requring that some attributes are grabbed directly from
      // the attribute (nodeValue doesn't return correct values), see
      //http://groups.google.com/groups?hl=en&lr=&ie=UTF-8&oe=UTF-8&safe=off&selm=3porgu4mc4ofcoa1uqkf7u8kvv064kjjb4%404ax.com
      // for information
    break;

    case 4: // Node.CDATA_SECTION_NODE
      // Mozilla seems to convert CDATA into a comment when going into wysiwyg mode,
      //  don't know about IE
      html += (Xinha.is_ie ? ('\n' + indent) : '') + '<![CDATA[' + root.data + ']]>' ;
    break;

    case 5: // Node.ENTITY_REFERENCE_NODE
      html += '&' + root.nodeValue + ';';
    break;

    case 7: // Node.PROCESSING_INSTRUCTION_NODE
      // PI's don't seem to survive going into the wysiwyg mode, (at least in moz)
      // so this is purely academic
      html += (Xinha.is_ie ? ('\n' + indent) : '') + '<?' + root.target + ' ' + root.data + ' ?>';
    break;

    case 1: // Node.ELEMENT_NODE
    case 11: // Node.DOCUMENT_FRAGMENT_NODE
    case 9: // Node.DOCUMENT_NODE
      var closed;
      var i;
      var root_tag = (root.nodeType == 1) ? root.tagName.toLowerCase() : '';
      if ( ( root_tag == "script" || root_tag == "noscript" ) && editor.config.stripScripts )
      {
        break;
      }
      if ( outputRoot )
      {
        outputRoot = !(editor.config.htmlRemoveTags && editor.config.htmlRemoveTags.test(root_tag));
      }
      if ( Xinha.is_ie && root_tag == "head" )
      {
        if ( outputRoot )
        {
          html += (Xinha.is_ie ? ('\n' + indent) : '') + "<head>";
        }
        // lowercasize
        var save_multiline = RegExp.multiline;
        RegExp.multiline = true;
        var txt = root.innerHTML.replace(Xinha.RE_tagName, function(str, p1, p2) { return p1 + p2.toLowerCase(); });
        RegExp.multiline = save_multiline;
        html += txt + '\n';
        if ( outputRoot )
        {
          html += (Xinha.is_ie ? ('\n' + indent) : '') + "</head>";
        }
        break;
      }
      else if ( outputRoot )
      {
        closed = (!(root.hasChildNodes() || Xinha.needsClosingTag(root)));
        html += (Xinha.is_ie && Xinha.isBlockElement(root) ? ('\n' + indent) : '') + "<" + root.tagName.toLowerCase();
        var attrs = root.attributes;
        
        for ( i = 0; i < attrs.length; ++i )
        {
          var a = attrs.item(i);
          if ( !a.specified 
            // IE claims these are !a.specified even though they are.  Perhaps others too?
            && !(root.tagName.toLowerCase().match(/input|option/) && a.nodeName == 'value')                
            && !(root.tagName.toLowerCase().match(/area/) && a.nodeName.match(/shape|coords/i)) 
          )
          {
            continue;
          }
          var name = a.nodeName.toLowerCase();
          if ( /_moz_editor_bogus_node/.test(name) )
          {
            html = "";
            break;
          }
          if ( /(_moz)|(contenteditable)|(_msh)/.test(name) )
          {
            // avoid certain attributes
            continue;
          }
          var value;
          if ( name != "style" )
          {
            // IE5.5 reports 25 when cellSpacing is
            // 1; other values might be doomed too.
            // For this reason we extract the
            // values directly from the root node.
            // I'm starting to HATE JavaScript
            // development.  Browser differences
            // suck.
            //
            // Using Gecko the values of href and src are converted to absolute links
            // unless we get them using nodeValue()
            if ( typeof root[a.nodeName] != "undefined" && name != "href" && name != "src" && !(/^on/.test(name)) )
            {
              value = root[a.nodeName];
            }
            else
            {
              value = a.nodeValue;
              // IE seems not willing to return the original values - it converts to absolute
              // links using a.nodeValue, a.value, a.stringValue, root.getAttribute("href")
              // So we have to strip the baseurl manually :-/
              if ( Xinha.is_ie && (name == "href" || name == "src") )
              {
                value = editor.stripBaseURL(value);
              }

              // High-ascii (8bit) characters in links seem to cause problems for some sites,
              // while this seems to be consistent with RFC 3986 Section 2.4
              // because these are not "reserved" characters, it does seem to
              // cause links to international resources not to work.  See ticket:167

              // IE always returns high-ascii characters un-encoded in links even if they
              // were supplied as % codes (it unescapes them when we pul the value from the link).

              // Hmmm, very strange if we use encodeURI here, or encodeURIComponent in place
              // of escape below, then the encoding is wrong.  I mean, completely.
              // Nothing like it should be at all.  Using escape seems to work though.
              // It's in both browsers too, so either I'm doing something wrong, or
              // something else is going on?

              if ( editor.config.only7BitPrintablesInURLs && ( name == "href" || name == "src" ) )
              {
                value = value.replace(/([^!-~]+)/g, function(match) { return escape(match); });
              }
            }
          }
          else
          {
            // IE fails to put style in attributes list
            // FIXME: cssText reported by IE is UPPERCASE
            value = root.style.cssText;
          }
          if ( /^(_moz)?$/.test(value) )
          {
            // Mozilla reports some special tags
            // here; we don't need them.
            continue;
          }
          html += " " + name + '="' + Xinha.htmlEncode(value) + '"';
        }
        if ( html !== "" )
        {
          if ( closed && root_tag=="p" )
          {
            //never use <p /> as empty paragraphs won't be visible
            html += ">&nbsp;</p>";
          }
          else if ( closed )
          {
            html += " />";
          }
          else
          {
            html += ">";
          }
        }
      }
      var containsBlock = false;
      if ( root_tag == "script" || root_tag == "noscript" )
      {
        if ( !editor.config.stripScripts )
        {
          if (Xinha.is_ie)
          {
            var innerText = "\n" + root.innerHTML.replace(/^[\n\r]*/,'').replace(/\s+$/,'') + '\n' + indent;
          }
          else
          {
            var innerText = (root.hasChildNodes()) ? root.firstChild.nodeValue : '';
          }
          html += innerText + '</'+root_tag+'>' + ((Xinha.is_ie) ? '\n' : '');
        }
      }
      else
      {
        for ( i = root.firstChild; i; i = i.nextSibling )
        {
          if ( !containsBlock && i.nodeType == 1 && Xinha.isBlockElement(i) )
          {
            containsBlock = true;
          }
          html += Xinha.getHTMLWrapper(i, true, editor, indent + '  ');
        }
        if ( outputRoot && !closed )
        {
          html += (Xinha.is_ie && Xinha.isBlockElement(root) && containsBlock ? ('\n' + indent) : '') + "</" + root.tagName.toLowerCase() + ">";
        }
      }
    break;

    case 3: // Node.TEXT_NODE
      html = /^script|noscript|style$/i.test(root.parentNode.tagName) ? root.data : Xinha.htmlEncode(root.data);
    break;

    case 8: // Node.COMMENT_NODE
      html = "<!--" + root.data + "-->";
    break;
  }
  return html;
};

/** @see getHTMLWrapper (search for "value = a.nodeValue;") */
