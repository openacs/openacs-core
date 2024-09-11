<master>
  <property name="context">{/doc/acs-templating/ {ACS Templating}} {/doc/acs-templating/gadgets {Gadgets}} Modal</property>
  <property name="doc(title)">Modal</property>

  <link rel="stylesheet" href="/resources/acs-templating/modal.css">
  <script src="/resources/acs-templating/modal.js"></script>

  <h1>Modal</h1>

  <h2>Concept</h2>
  <p>A modal window is a graphical control element subordinate to an application's main window.</p>

  <p>A modal window creates a mode that disables user interaction with the main window but keeps it visible, with the modal window as a child window in front of it. Users must interact with the modal window before they can return to the parent window. This avoids interrupting the workflow on the main window..</p>

  <p>OpenACS provides a modal implementation designed to not require external dependencies.</p>

  <h2>Usage</h2>

  <p>First of all, add the css and js files to the page.</p>
  <pre>
    &lt;link rel="stylesheet" href="/resources/acs-templating/modal.css"&gt;
    &lt;script src="/resources/acs-templating/modal.js"&gt;&lt;/script&gt;
  </pre>

  <p>If you plan to create modal dialogs dynamically on the page, also remember to invoke the modal function on the new element(s):</p>
  <pre>
    &lt;script&gt;
       acsModal('#my-new-element-selector');
    &lt;/script&gt;
  </pre>
  <p>acsModal accepts a multi-items query selector as argument. For elements present on the page at page load, invoking the function is not necessary.</p>

  <h3>Creating a modal</h3>
  <p>There are 4 relevant CSS classes for the modal: <b>acs-modal</b>, <b>acs-modal-content</b>, <b>acs-modal-open</b> and <b>acs-modal-close</b>.</p>
  <p><b>acs-modal</b> is the class wrapping the whole modal window. One <b>acs-modal-content</b> must be a child of the window element and is where your content goes.</p>
  <p><b>acs-modal-open</b> and <b>acs-modal-close</b> are two convenience classes: elements bearing this class will respectively open and close the modal. A close button must be placed inside the modal in order to work.</p>

  <h3>Targeting the right modal</h3>
  <p>In order to open a modal, this has to be "assigned" to a UI element. To do so, add the class <b>acs-modal-open</b> to it.</p>
  <p>The default target of a modal UI is the first element of class <b>acs-modal</b>. This is fine when there is only one modal on the page, or if your code reuses the same modal, e.g. via JavaScript. To address a specific modal, use the data-target attribute to provide a querySelector. The first instance of this selector will be the target modal.</p>

  <pre>
    &lt;div id="modal-number-1" class="acs-modal"&gt;
      &lt;div class="acs-modal-content"&gt;
        &lt;div&gt;I am modal number 1!&lt;/div&gt;
        &lt;button class="acs-modal-close"&gt;Close&lt;/button&gt;
      &lt;/div&gt;
    &lt;/div&gt;

    &lt;button class="acs-modal-open" data-target="#modal-number-1"&gt;I target modal number 1&lt;/button&gt;
  </pre>

  <p><h4>Example:</h4></p>

  <div id="modal-number-1" class="acs-modal">
    <div class="acs-modal-content">
      <div>I am modal number 1!</div>
      <button class="acs-modal-close">Close</button>
    </div>
  </div>
  <p>
    <button class="acs-modal-open" data-target="#modal-number-1">I target modal number 1</button>
  </p>

  <h3>Clicking outside the modal</h3>
  <p>A close button is not mandatory. Click anywhere outside the modal to close it.</p>

  <pre>
    &lt;div id="modal-number-2" class="acs-modal"&gt;
      &lt;div class="acs-modal-content"&gt;
        &lt;div&gt;I am modal number 2 and I do not have a close button. Just click outside!&lt;/div&gt;
      &lt;/div&gt;
    &lt;/div&gt;

    &lt;button class="acs-modal-open" data-target="#modal-number-2"&gt;I target modal number 2&lt;/button&gt;
  </pre>

  <p><h4>Example:</h4></p>

  <div id="modal-number-2" class="acs-modal">
    <div class="acs-modal-content">
      <div>I am modal number 2 and I do not have a close button. Just click outside!</div>
    </div>
  </div>
  <p>
    <button class="acs-modal-open" data-target="#modal-number-2">I target modal number 2</button>
  </p>

  <h3>Modals and long text</h3>
  <p>A modal dialog will introduce scrolling automatically.</p>

  <pre>
    &lt;div id="modal-number-3" class="acs-modal"&gt;
      &lt;div class="acs-modal-content"&gt;
        &lt;div&gt;
          &lt;button class="acs-modal-close"&gt;TL;DR, close now!&lt;/button&gt;
          &lt;p&gt;Lorem ipsum dolor sit amet, consectetur adipiscing elit...&lt;/p&gt&lt;/div&gt;
      &lt;/div&gt;
    &lt;/div&gt;

    &lt;button class="acs-modal-open" data-target="#modal-number-3"&gt;I target modal number 3. I am large!&lt;/button&gt;
  </pre>

  <p><h4>Example:</h4></p>

  <div id="modal-number-3" class="acs-modal">
    <div class="acs-modal-content">
      <div>
        <button class="acs-modal-close">TL;DR, close now!</button>
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Tristique senectus et netus et malesuada fames. Nisl nisi scelerisque eu ultrices vitae auctor eu augue ut. Nunc mi ipsum faucibus vitae. Dis parturient montes nascetur ridiculous mus mauris. Tellus orci ac auctor augue mauris augue neque gravida in. Purus semper eget duis at tellus at urna condimentum. Dolor purus non enim praesent elementum facilisis leo vel. Posuere urna nec tincidunt praesent semper feugiat nibh. Potenti nullam ac tortor vitae purus faucibus ornare. Pharetra massa massa ultricies mi. Ultrices gravida dictum fusce ut placerat. Ac tortor vitae purus faucibus ornare suspendisse sed nisi lacus. Nam aliquam sem et tortor consequat. Auctor eu augue ut lectus arcu bibendum. Blandit cursus risus at ultrices mi. Cursus eget nunc scelerisque viverra. Fermentum et sollicitudin ac orci phasellus egestas tellus rutrum.</p>

<p>Hac habitasse platea dictumst vestibulum rhoncus est. Vel eros donec ac odio. Orci eu lobortis elementum nibh tellus molestie nunc. Elit eget gravida cum sociis natoque. Pellentesque id nibh tortor id aliquet lectus proin. Dolor purus non enim praesent elementum facilisis leo vel fringilla. Sit amet aliquam id diam maecenas ultricies mi. Diam donec adipiscing tristique risus nec feugiat in. Non consectetur a erat nam at. Cursus in hac habitasse platea dictumst. Cras sed felis eget velit aliquet sagittis id. Pellentesque sit amet porttitor eget. Senectus et netus et malesuada fames.</p>

<p>Arcu risus quis varius quam quisque id diam. At erat pellentesque adipiscing commodo elit at. Metus vulputate eu scelerisque felis imperdiet proin fermentum leo vel. Vestibulum morbi blandit cursus risus. Arcu cursus euismod quis viverra nibh cras pulvinar mattis nunc. In nisl nisi scelerisque eu ultrices vitae auctor eu augue. Est lorem ipsum dolor sit amet consectetur adipiscing elit. Cras adipiscing enim eu turpis egestas pretium aenean pharetra. Amet consectetur adipiscing elit ut aliquam purus. Diam ut venenatis tellus in metus vulputate eu scelerisque. Nullam ac tortor vitae purus faucibus ornare suspendisse sed nisi. Vitae suscipit tellus mauris a diam maecenas sed enim. Et netus et malesuada fames ac turpis. Lorem ipsum dolor sit amet consectetur adipiscing elit pellentesque habitant. Suspendisse sed nisi lacus sed viverra tellus in. Lectus proin nibh nisl condimentum id venenatis a. Leo vel fringilla est ullamcorper eget. Ut sem viverra aliquet eget.</p>

<p>Velit laoreet id donec ultrices. Tempor orci dapibus ultrices in. Nullam non nisi est sit amet facilisis magna etiam tempor. Elementum facilisis leo vel fringilla. Mattis ullamcorper velit sed ullamcorper. Id aliquet risus feugiat in ante metus dictum at. Tortor pretium viverra suspendisse potenti nullam ac tortor vitae. Purus in massa tempor nec feugiat nisl pretium. Euismod nisi porta lorem mollis aliquam ut porttitor leo. Vitae semper quis lectus nulla at volutpat diam ut venenatis.</p>

<p>Donec ultrices tincidunt arcu non sodales neque sodales ut etiam. Interdum velit laoreet id donec ultrices tincidunt arcu non sodales. Sed libero enim sed faucibus turpis in eu mi bibendum. Aliquet nec ullamcorper sit amet risus nullam eget felis. Ullamcorper a lacus vestibulum sed arcu non odio euismod. Porttitor leo a diam sollicitudin tempor id. Accumsan sit amet nulla facilisi morbi tempus iaculis urna. Est ante in nibh mauris cursus mattis molestie a. Fringilla urna porttitor rhoncus dolor purus non enim praesent elementum. Turpis massa sed elementum tempus egestas sed. Consequat nisl vel pretium lectus quam id leo. Proin nibh nisl condimentum id. Odio euismod lacinia at quis risus. At quis risus sed vulputate odio. Enim nunc faucibus a pellentesque sit amet porttitor eget. Sit amet volutpat consequat mauris nunc. At auctor urna nunc id cursus. Proin gravida hendrerit lectus a.</p>

<p>Tortor at risus viverra adipiscing at. Pellentesque dignissim enim sit amet venenatis urna cursus eget. Scelerisque mauris pellentesque pulvinar pellentesque habitant morbi tristique. Eu non diam phasellus vestibulum lorem sed risus ultricies. At tellus at urna condimentum mattis pellentesque id. Dictum sit amet justo donec enim diam. Nunc id cursus metus aliquam eleifend mi in. Massa sed elementum tempus egestas sed sed risus pretium quam. Accumsan sit amet nulla facilisi morbi tempus. Ullamcorper dignissim cras tincidunt lobortis feugiat vivamus at augue eget. Nisi scelerisque eu ultrices vitae auctor eu. Nullam eget felis eget nunc lobortis mattis. Massa sed elementum tempus egestas sed sed risus pretium quam. Ultricies mi eget mauris pharetra et. Suspendisse faucibus interdum posuere lorem ipsum dolor sit.</p>

<p>Vitae tortor condimentum lacinia quis vel eros donec. Volutpat odio facilisis mauris sit amet massa vitae. Diam vulputate ut pharetra sit amet aliquam. Purus sit amet volutpat consequat mauris. Sit amet facilisis magna etiam tempor orci eu lobortis. Semper feugiat nibh sed pulvinar proin gravida hendrerit. Placerat vestibulum lectus mauris ultrices eros in cursus turpis. Velit euismod in pellentesque massa placerat duis. Blandit massa enim nec dui nunc. Commodo sed egestas egestas fringilla phasellus faucibus scelerisque eleifend. Orci nulla pellentesque dignissim enim sit amet venenatis urna.</p>

<p>Dui faucibus in ornare quam viverra. Ac turpis egestas sed tempus urna. Pellentesque adipiscing commodo elit at imperdiet dui accumsan sit. Malesuada fames ac turpis egestas sed. Id velit ut tortor pretium viverra. Integer malesuada nunc vel risus commodo viverra maecenas accumsan lacus. Netus et malesuada fames ac turpis egestas integer eget. Velit scelerisque in dictum non consectetur a. Integer quis auctor elit sed vulputate mi sit. Vel elit scelerisque mauris pellentesque pulvinar. Mauris vitae ultricies leo integer malesuada nunc vel risus commodo. Purus sit amet volutpat consequat mauris nunc congue nisi. Pretium aenean pharetra magna ac placerat vestibulum lectus mauris. Ut consequat semper viverra nam libero justo laoreet sit.</p>

<p>Convallis posuere morbi leo urna molestie at. Velit ut tortor pretium viverra suspendisse potenti nullam ac tortor. Malesuada nunc vel risus commodo viverra. Elit sed vulputate mi sit amet mauris. Faucibus interdum posuere lorem ipsum. Eu facilisis sed odio morbi. Cursus turpis massa tincidunt dui ut ornare. Maecenas ultricies mi eget mauris pharetra et ultrices. Sollicitudin tempor id eu nisl nunc mi ipsum faucibus vitae. Vivamus at augue eget arcu dictum varius duis. Amet mattis vulputate enim nulla aliquet. Id velit ut tortor pretium viverra suspendisse potenti nullam. Sed augue lacus viverra vitae congue eu consequat.</p>

<p>In pellentesque massa placerat duis ultricies lacus sed turpis. Porttitor massa id neque aliquam vestibulum morbi blandit. Quis risus sed vulputate odio ut enim blandit volutpat maecenas. Eleifend donec pretium vulputate sapien nec sagittis. Odio morbi quis commodo odio aenean sed adipiscing diam donec. Quis eleifend quam adipiscing vitae proin sagittis nisl rhoncus mattis. Enim neque volutpat ac tincidunt vitae semper quis lectus. Eget duis at tellus at urna condimentum mattis. Turpis nunc eget lorem dolor sed viverra. Rutrum tellus pellentesque eu tincidunt tortor aliquam nulla. Nibh tellus molestie nunc non blandit massa enim nec. Urna porttitor rhoncus dolor purus non enim praesent elementum. Malesuada nunc vel risus commodo viverra maecenas accumsan. Porta nibh venenatis cras sed. Enim ut sem viverra aliquet eget sit amet.</p>

<p>Purus gravida quis blandit turpis. Mauris sit amet massa vitae tortor condimentum. Rutrum quisque non tellus orci. Id porta nibh venenatis cras sed felis eget. Semper quis lectus nulla at volutpat. At auctor urna nunc id cursus metus aliquam eleifend mi. In nibh mauris cursus mattis molestie a iaculis at erat. Magna sit amet purus gravida. Sed arcu non odio euismod lacinia. Urna et pharetra pharetra massa. Volutpat diam ut venenatis tellus. Sit amet purus gravida quis blandit turpis cursus in hac. Maecenas pharetra convallis posuere morbi leo. Praesent tristique magna sit amet purus gravida. Pharetra magna ac placerat vestibulum lectus mauris ultrices eros in.</p>

<p>Condimentum mattis pellentesque id nibh tortor id aliquet lectus. Auctor eu augue ut lectus arcu bibendum at varius vel. Tristique senectus et netus et malesuada. Nunc eget lorem dolor sed viverra ipsum nunc. Diam vulputate ut pharetra sit amet aliquam id diam maecenas. Ac placerat vestibulum lectus mauris ultrices eros in cursus turpis. Lectus proin nibh nisl condimentum id venenatis a condimentum. Volutpat lacus laoreet non curabitur gravida. Pellentesque dignissim enim sit amet venenatis urna cursus eget nunc. Maecenas pharetra convallis posuere morbi leo urna molestie at elementum. Eleifend mi in nulla posuere sollicitudin aliquam. Amet cursus sit amet dictum.</p>

<p>A diam maecenas sed enim. Suspendisse ultrices gravida dictum fusce ut placerat. Amet dictum sit amet justo donec enim. Nibh nisl condimentum id venenatis a. Lobortis elementum nibh tellus molestie nunc non blandit massa. Nisi porta lorem mollis aliquam ut porttitor leo. Mauris pellentesque pulvinar pellentesque habitant morbi tristique. Vulputate odio ut enim blandit volutpat maecenas. Turpis cursus in hac habitasse platea. Sit amet consectetur adipiscing elit pellentesque habitant morbi tristique senectus. Porttitor rhoncus dolor purus non enim praesent elementum facilisis leo. Ac feugiat sed lectus vestibulum mattis ullamcorper. Ut aliquam purus sit amet.</p>

<p>Elementum nibh tellus molestie nunc non blandit massa enim nec. Diam donec adipiscing tristique risus nec feugiat. Sed risus ultricies tristique nulla aliquet. Arcu non odio euismod lacinia. Ut sem viverra aliquet eget sit amet. Neque ornare aenean euismod elementum. Mauris vitae ultricies leo integer malesuada. Scelerisque in dictum non consectetur a. Montes nascetur ridiculus mus mauris vitae ultricies leo. Mauris commodo quis imperdiet massa tincidunt nunc. Nullam eget felis eget nunc lobortis mattis aliquam faucibus. Tellus integer feugiat scelerisque varius morbi. Et tortor consequat id porta nibh venenatis cras sed felis. Nisl purus in mollis nunc sed id semper risus. Amet tellus cras adipiscing enim. Sit amet cursus sit amet dictum sit. Blandit massa enim nec dui. Tellus cras adipiscing enim eu turpis egestas. Nisl vel pretium lectus quam id.</p>

<p>Et pharetra pharetra massa massa ultricies mi quis hendrerit dolor. Vel turpis nunc eget lorem dolor sed viverra. Elit sed vulputate mi sit. Suscipit tellus mauris a diam maecenas sed. Semper auctor neque vitae tempus quam pellentesque nec nam aliquam. Nisi lacus sed viverra tellus in hac habitasse. Nunc vel risus commodo viverra maecenas. Nunc sed augue lacus viverra vitae congue eu consequat. Diam quis enim lobortis scelerisque fermentum dui faucibus. Orci porta non pulvinar neque laoreet suspendisse interdum. Malesuada proin libero nunc consequat interdum varius sit amet. Odio aenean sed adipiscing diam donec adipiscing tristique risus. Mauris augue neque gravida in fermentum et. Ac auctor augue mauris augue neque gravida in. Maecenas accumsan lacus vel facilisis volutpat est. Vitae justo eget magna fermentum iaculis eu non diam.</p>

<p>Eu nisl nunc mi ipsum. In aliquam sem fringilla ut morbi tincidunt augue interdum. Nulla pellentesque dignissim enim sit amet venenatis urna. Ut sem nulla pharetra diam. Nec feugiat nisl pretium fusce. Pharetra magna ac placerat vestibulum lectus. Interdum consectetur libero id faucibus nisl tincidunt eget nullam. Urna condimentum mattis pellentesque id nibh tortor id aliquet lectus. Tincidunt lobortis feugiat vivamus at augue eget arcu dictum. Lorem mollis aliquam ut porttitor leo a. Risus feugiat in ante metus dictum at tempor commodo ullamcorper. Dictumst quisque sagittis purus sit amet volutpat consequat. Purus sit amet volutpat consequat mauris nunc congue nisi vitae. Turpis egestas sed tempus urna et pharetra pharetra massa. Urna et pharetra pharetra massa. Interdum varius sit amet mattis.</p>

<p>Sed faucibus turpis in eu mi bibendum neque egestas. Tristique senectus et netus et. Et sollicitudin ac orci phasellus egestas tellus. Aliquam ultrices sagittis orci a scelerisque purus semper eget. Enim nulla aliquet porttitor lacus luctus accumsan tortor posuere. Velit sed ullamcorper morbi tincidunt ornare massa eget egestas purus. Pharetra massa massa ultricies mi quis. Fermentum leo vel orci porta non pulvinar. Non pulvinar neque laoreet suspendisse interdum consectetur libero. Id nibh tortor id aliquet lectus proin nibh nisl condimentum. Enim sit amet venenatis urna. Quis eleifend quam adipiscing vitae proin sagittis nisl. Pulvinar pellentesque habitant morbi tristique senectus et netus et malesuada. Elit pellentesque habitant morbi tristique senectus et netus et malesuada. Sed lectus vestibulum mattis ullamcorper velit. Sit amet justo donec enim diam vulputate ut. Tortor condimentum lacinia quis vel eros. Velit scelerisque in dictum non consectetur a erat nam. Consequat ac felis donec et odio pellentesque diam.</p>

<p>Sit amet purus gravida quis blandit turpis cursus in hac. Iaculis urna id volutpat lacus laoreet non curabitur gravida arcu. Condimentum lacinia quis vel eros donec ac odio tempor. Massa placerat duis ultricies lacus sed turpis tincidunt. Sed egestas egestas fringilla phasellus faucibus scelerisque eleifend donec. Convallis a cras semper auctor neque. Ipsum a arcu cursus vitae congue mauris. Iaculis at erat pellentesque adipiscing commodo elit. Justo eget magna fermentum iaculis eu non diam phasellus. Tellus in metus vulputate eu scelerisque. Nec nam aliquam sem et. Enim praesent elementum facilisis leo vel. Amet aliquam id diam maecenas ultricies. Blandit cursus risus at ultrices mi. Facilisis leo vel fringilla est ullamcorper eget nulla facilisi. Nibh ipsum consequat nisl vel pretium lectus quam id. Elementum nibh tellus molestie nunc non blandit. Orci eu lobortis elementum nibh tellus molestie.</p>

<p>Amet luctus venenatis lectus magna fringilla. Nulla pellentesque dignissim enim sit amet. Malesuada pellentesque elit eget gravida cum sociis natoque penatibus. Aliquam sem et tortor consequat id. Risus feugiat in ante metus dictum. Pretium vulputate sapien nec sagittis aliquam. Risus sed vulputate odio ut. At quis risus sed vulputate odio ut enim. Blandit turpis cursus in hac habitasse platea dictumst quisque sagittis. Imperdiet dui accumsan sit amet nulla facilisi morbi tempus.</p>

<p>Id donec ultrices tincidunt arcu non sodales neque sodales ut. Risus at ultrices mi tempus imperdiet nulla malesuada pellentesque. Turpis in eu mi bibendum neque egestas congue quisque. Ultrices in iaculis nunc sed augue lacus viverra vitae congue. Id leo in vitae turpis massa. Augue eget arcu dictum varius duis at. Non sodales neque sodales ut etiam sit amet nisl. Ante in nibh mauris cursus. Donec adipiscing tristique risus nec feugiat in fermentum posuere urna. Est ultricies integer quis auctor elit. Dictum non consectetur a erat nam at lectus. Dictumst quisque sagittis purus sit amet volutpat consequat mauris nunc. Lacinia quis vel eros donec ac odio. Integer feugiat scelerisque varius morbi enim nunc faucibus. A erat nam at lectus. Vitae aliquet nec ullamcorper sit. Lectus vestibulum mattis ullamcorper velit sed ullamcorper morbi tincidunt.</p>

<p>Pulvinar etiam non quam lacus suspendisse faucibus interdum posuere lorem. Et sollicitudin ac orci phasellus. Porttitor massa id neque aliquam vestibulum morbi blandit. Sit amet mattis vulputate enim nulla. Et magnis dis parturient montes nascetur ridiculus. Tristique senectus et netus et malesuada fames ac turpis. Etiam tempor orci eu lobortis elementum nibh tellus molestie nunc. Id eu nisl nunc mi ipsum faucibus. Auctor urna nunc id cursus metus. Id consectetur purus ut faucibus pulvinar elementum integer enim. Erat velit scelerisque in dictum non consectetur a erat. Sed tempus urna et pharetra pharetra massa massa ultricies mi. Aenean et tortor at risus. Diam maecenas ultricies mi eget mauris. Feugiat nibh sed pulvinar proin gravida hendrerit lectus a. Velit sed ullamcorper morbi tincidunt ornare massa eget egestas. Integer quis auctor elit sed vulputate mi sit amet.</p>

<p>Faucibus ornare suspendisse sed nisi lacus. Feugiat scelerisque varius morbi enim. Enim sit amet venenatis urna cursus. Risus commodo viverra maecenas accumsan lacus vel facilisis. Purus viverra accumsan in nisl nisi scelerisque eu. Nunc mi ipsum faucibus vitae aliquet nec. Morbi tristique senectus et netus. Sem viverra aliquet eget sit. Felis bibendum ut tristique et egestas quis ipsum. Placerat in egestas erat imperdiet sed euismod nisi porta lorem. Pretium fusce id velit ut tortor pretium. Leo vel orci porta non pulvinar. Egestas egestas fringilla phasellus faucibus. Commodo ullamcorper a lacus vestibulum sed arcu non. Arcu bibendum at varius vel. Nunc consequat interdum varius sit. In iaculis nunc sed augue lacus viverra vitae. Urna condimentum mattis pellentesque id nibh tortor. Penatibus et magnis dis parturient montes nascetur ridiculus mus. Facilisis leo vel fringilla est ullamcorper eget nulla facilisi etiam.</p>

<p>Commodo elit at imperdiet dui accumsan sit amet. Gravida quis blandit turpis cursus in. Suscipit tellus mauris a diam maecenas sed enim ut sem. Fusce ut placerat orci nulla pellentesque dignissim enim sit amet. Felis eget velit aliquet sagittis id consectetur purus ut. Tempus quam pellentesque nec nam aliquam sem et tortor consequat. Nibh tortor id aliquet lectus proin nibh nisl. Libero nunc consequat interdum varius sit amet mattis vulputate. Id aliquet lectus proin nibh nisl. Mauris in aliquam sem fringilla ut morbi tincidunt augue interdum. Cursus metus aliquam eleifend mi in. Gravida arcu ac tortor dignissim. Augue lacus viverra vitae congue eu consequat ac felis donec. Feugiat sed lectus vestibulum mattis ullamcorper velit sed. Lectus arcu bibendum at varius vel pharetra. Arcu dui vivamus arcu felis bibendum ut. Feugiat vivamus at augue eget arcu dictum varius duis. Quis imperdiet massa tincidunt nunc. Et leo duis ut diam quam nulla porttitor massa. Commodo nulla facilisi nullam vehicula ipsum a.</p>

<p>Dui vivamus arcu felis bibendum ut tristique et egestas quis. Tristique senectus et netus et malesuada fames ac turpis. Quisque id diam vel quam elementum pulvinar. Quam viverra orci sagittis eu. Cras adipiscing enim eu turpis. Tellus mauris a diam maecenas sed enim ut sem. Dui ut ornare lectus sit amet est. Ut venenatis tellus in metus vulputate eu scelerisque. Aliquet eget sit amet tellus. Risus nec feugiat in fermentum posuere urna nec tincidunt. Pharetra et ultrices neque ornare aenean euismod elementum nisi. Egestas erat imperdiet sed euismod nisi porta lorem. Amet consectetur adipiscing elit ut aliquam purus. Sodales neque sodales ut etiam. Mi sit amet mauris commodo quis imperdiet massa tincidunt nunc. Eleifend mi in nulla posuere sollicitudin aliquam ultrices sagittis. Ut lectus arcu bibendum at varius.</p>

<p>Proin libero nunc consequat interdum varius sit. Diam vel quam elementum pulvinar. Habitant morbi tristique senectus et. Egestas maecenas pharetra convallis posuere morbi leo. Felis eget velit aliquet sagittis id. Ultrices gravida dictum fusce ut placerat orci nulla pellentesque. Mattis ullamcorper velit sed ullamcorper morbi tincidunt. Tincidunt dui ut ornare lectus sit amet est. Blandit cursus risus at ultrices mi. Ipsum nunc aliquet bibendum enim facilisis.</p>

<p>Donec ultrices tincidunt arcu non sodales. Rhoncus dolor purus non enim praesent elementum. Egestas purus viverra accumsan in nisl nisi scelerisque eu. Vitae purus faucibus ornare suspendisse sed nisi lacus sed. Neque viverra justo nec ultrices dui sapien. Dapibus ultrices in iaculis nunc sed augue lacus viverra vitae. Non blandit massa enim nec. Vitae ultricies leo integer malesuada nunc vel risus commodo viverra. Fringilla est ullamcorper eget nulla. Adipiscing enim eu turpis egestas pretium aenean. Gravida quis blandit turpis cursus in hac habitasse. Malesuada fames ac turpis egestas maecenas pharetra. Ultrices eros in cursus turpis massa tincidunt dui ut ornare. Leo duis ut diam quam nulla porttitor massa id neque. Imperdiet dui accumsan sit amet nulla facilisi morbi tempus. Urna neque viverra justo nec ultrices dui sapien. Amet porttitor eget dolor morbi non arcu risus. Proin libero nunc consequat interdum varius. Morbi tincidunt augue interdum velit euismod. Ac orci phasellus egestas tellus.</p>

<p>Dolor sit amet consectetur adipiscing elit pellentesque habitant. Feugiat in ante metus dictum at tempor commodo ullamcorper. Condimentum mattis pellentesque id nibh. Est ullamcorper eget nulla facilisi etiam dignissim diam. Commodo nulla facilisi nullam vehicula ipsum. Turpis massa sed elementum tempus egestas sed sed risus pretium. Pellentesque elit eget gravida cum sociis natoque penatibus et magnis. Fermentum dui faucibus in ornare quam. Consequat semper viverra nam libero justo laoreet sit amet. Platea dictumst vestibulum rhoncus est pellentesque elit ullamcorper dignissim. Integer enim neque volutpat ac. Et magnis dis parturient montes nascetur ridiculus mus mauris. Quisque egestas diam in arcu. Purus in massa tempor nec. Vitae tempus quam pellentesque nec nam aliquam sem et. Eu scelerisque felis imperdiet proin fermentum. Cras tincidunt lobortis feugiat vivamus at augue eget arcu dictum.</p>

<p>Egestas congue quisque egestas diam in arcu. Vitae suscipit tellus mauris a. Vestibulum lorem sed risus ultricies tristique nulla aliquet enim. Adipiscing commodo elit at imperdiet. Congue nisi vitae suscipit tellus mauris. Sit amet facilisis magna etiam. Luctus venenatis lectus magna fringilla. Etiam erat velit scelerisque in. Porta lorem mollis aliquam ut porttitor leo a diam. In nulla posuere sollicitudin aliquam ultrices. Aliquam sem et tortor consequat id porta nibh venenatis. Quam lacus suspendisse faucibus interdum posuere lorem ipsum. Risus sed vulputate odio ut. Sodales ut eu sem integer vitae justo eget. Pulvinar neque laoreet suspendisse interdum consectetur libero id faucibus nisl. Orci dapibus ultrices in iaculis nunc sed.</p>

<p>Vel risus commodo viverra maecenas. Urna neque viverra justo nec ultrices. Sodales ut eu sem integer vitae justo eget. Potenti nullam ac tortor vitae purus faucibus ornare. Nulla facilisi cras fermentum odio eu. Consectetur adipiscing elit ut aliquam purus sit amet luctus. Vitae auctor eu augue ut lectus arcu bibendum. Tellus in hac habitasse platea dictumst vestibulum rhoncus est pellentesque. Molestie ac feugiat sed lectus vestibulum mattis ullamcorper velit. Platea dictumst vestibulum rhoncus est pellentesque elit ullamcorper dignissim. Turpis cursus in hac habitasse platea dictumst quisque sagittis. Nisl tincidunt eget nullam non nisi. Sed viverra ipsum nunc aliquet bibendum enim facilisis gravida. Sodales neque sodales ut etiam sit amet nisl. Scelerisque in dictum non consectetur a erat nam at. At tempor commodo ullamcorper a lacus vestibulum sed. Accumsan in nisl nisi scelerisque eu ultrices vitae. Mattis pellentesque id nibh tortor.</p>
      </div>
    </div>
  </div>
  <p>
    <button class="acs-modal-open" data-target="#modal-number-3">I target modal number 3. I am large!</button>
  </p>
