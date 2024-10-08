
<property name="context">{/doc/acs-service-contract/ {ACS Service Contracts}} {}</property>
<property name="doc(title)"></property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              

ACS Service Contract Overview by Neophytos Demetriou
(k2pts\@yahoo.com) and Kapil Thangavelu (k_vertigo\@yahoo.com) Goals
- To increase inter-application code reuse by designating
interfaces for interaction. - To increase flexibility by allowing
developers to reimplement an interface for their needs. - To
provide the framework for constructing web services by housing the
metadata needed to construct wsdl. - To be low impediment to
developers to create interfaces for their packages. - To reduce
fixed dependencies in packages. Definitions Interface - An abstract
set of operations supported by one or more endpoints. Operation -
An abstract description of an action supported by the service.
Binding - A concrete implementation for a particular interface.
Function - The implementation of an operation. Actors Registrar -
An entity that defines the specification of a contract and
registers it with the repository. Provider - Provides an
implementation of the contract. Dependent - Something that uses a
contract.
