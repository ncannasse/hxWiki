Haxe Wiki CMS
===========

The Haxe Wiki CMS is used by haxe.org and provides the following features :

- a wiki system with a clean extendable markup syntax
  + realtime javascript-based preview

- each page can be translated while keeping the same navigation
  + (fallback on default english language when user-language specific
  version is not found)

- user groups and rights management
  + (control who can create/edit/modify/etc. all or specific pages/paths of the wiki)

- versioning of all pages changes

- some parts of the wiki can be turned into a blog-style view

- allow comments on pages/blogs - if activated

- an embededded forum system

- image and files uploads

- customizable themes with css

- a remoting api to perform automatic tasks
  + (such as synchronizing the API documentation)

- entirely written in [Haxe](http://www.haxe.org) !


SETUP
-----

In order to setup the wiki :

1. [download](https://github.com/ncannasse/hxWiki/downloads) or clone the source code

2. install [Haxe](http://www.haxe.org) + [Neko](http://www.nekovm.org)
    - requires Haxe 2.09+

3. install [MySQL](http://www.mysql.com/downloads/mysql/) database server
    - create a database called `hxwiki`

4. configure website
    - copy `config.tpl.xml` as `config.xml` and set the `db` field with your local mysql database server `db="mysql://root:@localhost:3306/hxwiki"`

5. install mtwin and templo libraries
    - `haxelib install mtwin`
    - `haxelib install templo`

6. compile by running `haxe project.hxml`

7. create temploc executable
    - `cd www`
    - `haxelib run templo`

8. either configure [mod_neko](http://haxe.org/doc/build/mod_neko) for Apache or run the local neko server
    - `nekotools server -rewrite`

9. visit `http://localhost:2000/`
    - it should create the database, refresh to start using !

CONFIG OPTIONS
-----

+ change website design
  - set `style="haxe"` for old design 
  - set `style="haxe2"` for new design

+ use google search
  - set gsearch `gsearch="1"`
