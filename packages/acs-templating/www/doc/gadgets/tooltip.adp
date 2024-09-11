<master>
  <property name="context">{/doc/acs-templating/ {ACS Templating}} {/doc/acs-templating/gadgets {Gadgets}} Tooltip</property>
  <property name="doc(title)">Tooltip</property>

  <link rel="stylesheet" href="/resources/acs-templating/tooltip.css">
  <script src="/resources/acs-templating/tooltip.js"></script>

  <h1>Tooltip</h1>

  <h2>Concept</h2>
  <p>The tooltip, also known as infotip or hint, is a common graphical user interface (GUI) element in which, when hovering over a screen element or component, a text box displays information about that element, such as a description of a button's function, or other such information.</p>

  <p>Normally, a browser will display the "title" attribute as a tooltip. This will however normally not be displayed upon pressing on mobile devices. Another difference is, the way the tooltip is rendered cannot be styled.</p>

  <p>OpenACS provides a tooltip implementation designed to not require external dependencies.</p>

  <h2>Usage</h2>

  <p>First of all, add the css and js files to the page.</p>
  <pre>
    &lt;link rel="stylesheet" href="/resources/acs-templating/tooltip.css"&gt;
    &lt;script src="/resources/acs-templating/tooltip.js"&gt;&lt;/script&gt;
  </pre>

  <p>If you plan to create tooltip elements dynamically on the page, also remember to invoke the tooltip function on the new element(s):</p>
  <pre>
    &lt;script&gt;
       acsTooltip('#my-new-element-selector');
    &lt;/script&gt;
  </pre>
  <p>acsTooltip accepts a multi-items query selector as argument. For elements present on the page at page load, invoking the function is not necessary.</p>

  <h3>Default tooltip</h3>
  <p>The default tooltip orientation is below the parent element.</p>
  <pre>
    &lt;div class="acs-tooltip"&gt;Default Tooltip&lt;span class="acs-tooltip-text"&gt;I default to the bottom.&lt;/span&gt;&lt;/div&gt;
  </pre>
  <p><h4>Example:</h4></p>
  <center><div class="acs-tooltip">Default Tooltip<span class="acs-tooltip-text">I default to the bottom.</span></div></center>

  <h3>Bottom-oriented tooltip</h3>
  <p>The bottom orientation can also be specified explicitly.</p>
  <pre>
    &lt;div class="acs-tooltip bottom"&gt;Bottom&lt;span class="acs-tooltip-text"&gt;Bottom Tooltip&lt;/span&gt;&lt;/div&gt;
  </pre>
  <p><h4>Example:</h4></p>
  <center><div class="acs-tooltip bottom">Bottom<span class="acs-tooltip-text">Bottom Tooltip</span></div></center>

  <h3>Top-oriented tooltip</h3>
  <pre>
    &lt;div class="acs-tooltip top"&gt;Top&lt;span class="acs-tooltip-text"&gt;Top Tooltip&lt;/span&gt;&lt;/div&gt;
  </pre>
  <p><h4>Example:</h4></p>
  <center><div class="acs-tooltip top">Top<span class="acs-tooltip-text">Top Tooltip</span></div></center>

  <h3>Left-oriented tooltip</h3>
  <pre>
    &lt;div class="acs-tooltip left"&gt;Left&lt;span class="acs-tooltip-text"&gt;Left Tooltip&lt;/span&gt;&lt;/div&gt;
  </pre>
  <p><h4>Example:</h4></p>
  <center><div class="acs-tooltip left">Left<span class="acs-tooltip-text">Left Tooltip</span></div></center>

  <h3>Right-oriented tooltip</h3>
  <pre>
    &lt;div class="acs-tooltip right"&gt;Right&lt;span class="acs-tooltip-text"&gt;Right Tooltip&lt;/span&gt;&lt;/div&gt;
  </pre>
  <p><h4>Example:</h4></p>
  <center><div class="acs-tooltip right">Right<span class="acs-tooltip-text">Right Tooltip</span></div></center>

  <h3>Enhance the vanilla title behavior</h3>
  <p>One can also specify the tooltip using the title attribute. This will support HTML as well. Note that the original title attribute will be removed from the item.<p>
  <pre>
    &lt;div class="acs-tooltip" title="Tooltip via the &lt;b&gt;title&lt;/b&gt; attribute"&gt;Title&lt;/div&gt;
  </pre>
  <p><h4>Example:</h4></p>
  <center><div class="acs-tooltip" title="Tooltip via the <b>title</b> attribute">Title</div></center>

  <h3>Tooltip visibility</h3>
  <p>If the tooltip orientation would bring the element to be displayed outside the page viewport, it will fallback to the bottom one.<p>
  <pre>
    &lt;div class="acs-tooltip left"&gt;Long text with righ-side tooltip
       &lt;span class="acs-tooltip-text"&gt;
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
          eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
          enim ad minim veniam, quis nostrud exercitation ullamco laboris
          nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
          reprehenderit in voluptate velit esse cillum dolore eu fugiat
          nulla pariatur. Excepteur sint occaecat cupidatat non proident,
          sunt in culpa qui officia deserunt mollit anim id est laborum.
       &lt;/span&gt;
    &lt;/div&gt;
  </pre>
  <p><h4>Example:</h4></p>
  <p>
    <div id="test" class="acs-tooltip left">Long text with left-side tooltip
      <span class="acs-tooltip-text">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
        eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
        enim ad minim veniam, quis nostrud exercitation ullamco laboris
        nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor
        in reprehenderit in voluptate velit esse cillum dolore eu fugiat
        nulla pariatur. Excepteur sint occaecat cupidatat non proident,
        sunt in culpa qui officia deserunt mollit anim id est laborum.
      </span>
    </div>
  </p>
