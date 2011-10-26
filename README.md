haXe Wiki CMS
===========

The haXe Wiki CMS is used by haxe.org and provides the following features :

* a wiki system with a clean extendable markup syntax 
  + realtime javascript-based preview
    
- each page can be translated while keeping the same navigation
  (fallback on default english language when user-language specific
  version is not found)

- user groups and rights management
  (control who can create/edit/modify/etc. all or specific pages/paths of the wiki)
  
- versioning of all pages changes

- some parts of the wiki can be turned into a blog-style view

- allow comments on pages/blogs - if activated

- an embededded forum system

- image and files uploads

- customizable themes with css

- a remoting api to perform automatic tasks
  (such as synchronizing the API documentation)

- entirely written in [haXe](http://www.haxe.org) !


SETUP
-----

In order to setup the wiki :

a) download the sources

b) install [haXe](http://www.haxe.org) + [Neko](http://www.nekovm.org)
   - requires haXe 2.09+

c) compile by running `haxe project.hxml`

d) either configure mod_neko for Apache or run the local neko server
   > `cd www`
   > `nekotools server -rewrite`

e) copy `config.tpl.xml` as `config.xml` and configure the `db` field with
   your local mysql database server
   
f) visit `http://localhost:2000/`
   it should create the database, refresh to start using !
