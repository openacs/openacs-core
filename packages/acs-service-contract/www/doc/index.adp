
<property name="context">{/doc/acs-service-contract {ACS Service Contracts}} {ACS Service Contract Documentation}</property>
<property name="doc(title)">ACS Service Contract Documentation</property>
<master>
<h1>ACS Service Contract Documentation</h1>
<h2>Why</h2>
<p>To facilitate greater code reuse, application integration, and
package extensibility within the OpenACS.</p>
<p>To do this acs-service-contract defines an API for the creation
of interfaces and discovery of interface implementations.</p>
<h2>Background</h2>
<p>Most component systems are based on the use of interfaces.
Interfaces allow components to create contracts which define their
functional level of reuse and customization. It also provides the
infrastructure for runtime discovery of which implemented
interfaces are available.</p>
<p>The ACS4 is based on a thin object system, that is primarily
relational but the acs_objects system allows a veneer of object
orientedness by providing globally unique object ids, object
metadata, and bundling of data and methods as an object. While this
permits a level of reuse on an object or package basis, it requires
hardcoding the unit of reuse.</p>
<p>ACS Service contract allows these objects and packages to also
define and register their implementation of interfaces, so the
level of reuse is defined at the contract level.</p>
<p>In addition ACS Service contract provides mean to dispatch
method calls on an interface implementation. The dispatch means is
only available through tcl.</p>
<p>Interface Discovery is available programmatically as well as via
documentation through ad_proc.</p>
<p>The Service Contract interface specification was inspired by
WDSL, the interface specification for web services.</p>
<h2>Hitchiker&#39;s Guide to Service Contract Definitions</h2>
<ul>
<li>contract - analogous to interface, contracts serve as logical
containers for operations.</li><li>operation - a method of an interface. defines a method
signature, including both input and outputs as well as metadata
such as caching.</li><li>implementation - an implementation is a set of concrete
functions that fufills an interface.</li><li>implementation alias - is the method of an implementation that
fufills a given operation of the contract.</li><li>bindings - association between an interface and an
implementation.</li><li>types - define the kind of input and outputs a operation
receives.</li>
</ul>
<h2>Usage</h2>
<h3>Design the Contract</h3>
<p>First Off design the interface for your contract, keeping in
mind that all implementations need to implement it and that
extension of the contract after deployment is often not practical.
In other words take the time to do a little future proofing and
thinking about possible uses that you weren&#39;t planning on.</p>
<h3>Defining Operations</h3>
<p>Next define the logical operations that will make up your
contract</p>
<h3>Register the Contract</h3>
<p>with acs contracts.</p>
<p>Implement the Contract</p>
<h2>FAQ</h2>
<h3>Why Does an implementation reference an interface?</h3>
<p>This might seem a little strange since a binding is the official
reference between an implementation and an interface. However it is
quite possible that an implementation for interface might exist
prior to the interface being defined, ie the interface defining
package is not installed. By retaining this information the
interface defining package can be installed and the implementations
already installed on the system can be bound to it.</p>
<h2>Api Reference</h2>
<p>[for oracle please syntax replace __ with .]</p>
<h3>Creating Message Types</h3>
<ul><li>(sql):: acs_sc_msg_type__new (name, spec):
<p>defines a type based on spec. Spec should be a string (possibly
empty) that defines the names and types that compose this type.
example <code>ObjectDisplay.Name.InputType</code> as name
<code>object_id:integer</code> as spec.</p>
</li></ul>
<h3>Creating Interfaces</h3>
<ul><li>(sql):
<pre>
acs_sc_contract__new (contract_name, contract_desc):</pre>
</li></ul>
<p>creates a new contract to serve as a logical container for
operations. contract_desc is a text description of the
contract.</p>
<ul><li>(sql):
<pre>
acs_sc_operation__new (contract_name, operation_name,
                                       operation_desc, operation_iscachable_p,
                                       operation_inputtype, operation_outputtype
                                      ):</pre>
</li></ul>
<p>creates a new operation as part of a contract.</p>
<h3>Creating Implementations</h3>
<ul><li>(tcl) acs_sc_proc (contract, operation, impl): registers an
implementations. ?? why operation</li></ul>
<h3>Discovery</h3>
<ul><li>(tcl) acs_sc_binding_exists_p (contract, impl): returns boolean
whether a binding exists between a given contract name and
implementation.</li></ul>
<h3>Dispatching</h3>
<ul><li>(tcl) acs_sc::invoke (contract, operation, [arguments, impl]):
calls an operation</li></ul>
<h2>Examples</h2>
<p>Included in the service contract package are examples for oracle
and PostgreSQL of a trivial contract.</p>
<p>Also the search contract functions as a non-trivial core
contract used by openacs4.</p>
<h2>Further Reading</h2>
<p>Abstract Factory Pattern - GOF</p>
<p>Component Systems - Clemens Syzperski</p>
<p>WSDL Spec</p>
<h2>Release Notes</h2>
<p>Please file bugs in the <a href="http://openacs.org/bugtracker/openacs/">Bug Tracker</a>.</p>
<h2>Credits</h2>
<p>Most content was provided by Neophytos Demetriou. Most of the
errors were provided by Kapil Thangavelu.</p>
