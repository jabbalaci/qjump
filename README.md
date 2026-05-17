QJump
=====

QJump (short for QuickJump) allows you to bookmark directories on your local machine and switch between them easily.
It's like a URL shortener but it's designed for your local machine.

Supported platforms
-------------------

I tried it under Linux only. It works with Bash, ZSH and Fish shells (settings are included).
I think it should also work under Mac OS.

Demo
----

![QJump in action](demo/demo.gif)

After the bookmark, you can also specify a substring
and you'll be redirected to the first subdirectory
whose name contains this substring:

```shell
$ cd
$ pwd
/home/jabba

$ qj nim
$ pwd
/home/jabba/Dropbox/nim

$ cd
$ pwd
/home/jabba

$ qj nim/26
$ pwd
/home/jabba/Dropbox/nim/Nim-2026
```

Here, only "`nim`" was present in the database. However,
"`nim/26`" worked and the current directory was changed to "`.../nim/Nim-2026`".

Help
----
```text
QJump 0.3.2 by Jabba Laci (jabba.laci@gmail.com), 2026
https://github.com/jabbalaci/qjump

Usage: qj [alias] [option]

Provide an alias (bookmark) or use one of these options:

-h, --help          show this help
-v, --version       version info
-l, --list          show list of available aliases
-d, --dead          list dead (non-existing) paths
-a, --alive         list existing paths
```

Motivation
----------

During my daily work, there are some folders that I visit regularly.
QJump lets me change directories with the speed of light :)

Installation
------------

* In the source code (`qjump.nim`), modify the value of `DB_FILE`.
  It contains the path of the database file that will be created.
  If you modify anything, don't forget to recompile the project (see the `Makefile`).
* Add the content of `function.bash` / `function.zsh` / `function.fish` to your
  shell's settings file (depending on what shell you use).
  Modify the variable `QJ` to point to the binary `qjump` .
* Open a new terminal and issue the command `qj`, which calls the shell function.
  When you call `qj` for the first time and no database file exists yet,
  then `qjump` will create a simple DB file that you can extend later.

Notes
-----

QJump generates a hash for a directory, it'll be the bookmark. You are encouraged to change it by editing the database file (`qjump.txt`) manually.
Just make sure that all bookmarks are unique.
The program generates 3-character-long bookmarks but you can use
shorter / longer bookmarks if you want.

Links
-----

* [QuickJump](https://github.com/jabbalaci/quickjump) is the predecessor of this project,
  written in Python. QJump (this project) is similar but it contains some improvements,
  and since it's written in [Nim](https://nim-lang.org/) (a compiled language), it ships as a single binary.
  QuickJump is retired; use QJump instead.
