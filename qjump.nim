#!/usr/bin/env nimbang
#nimbang-args c -d:release
#nimbang-settings hideDebugInfo

#[
QJump
=====

QJump (short for QuickJump) allows you to bookmark directories
on your local machine and switch between them easily.
It's like a URL shortener but it's designed for your local machine.

Installation
------------

* In the source code (this file), modify the value of `DB_FILE`.
  It contains the path of the database file that will be created.
  If you modify anything, don't forget to recompile the project.
* Add the content of `function.bash` / `function.zsh` / `function.fish`
  to your shell's settings file (depending on what shell you use).
  Modify the variable `QJ` to point to the binary `qjump` .
* Open a new terminal and issue the command `qj`, which calls the shell function.
  When you call `qj` for the first time and no database file exists yet,
  then `qjump` will create a simple DB file that you can extend later.

It was tested under Linux only.

Author: Laszlo Szathmary <jabba.laci@gmail.com>, 2026
GitHub: https://github.com/jabbalaci/qjump
]#

import std/algorithm
import std/editdistance
import std/os
import std/re
import std/sequtils
import std/sets
import std/strformat
import std/strutils
import std/tables

import helpers
import jsystem

proc myQuit(code: int) =
  # Prints ".", thus we remain in the current folder.
  echo "."
  quit(code)

let
  VERSION = "0.3.4"
  HOME = getHomeDir().rstrip("/")
  DB_DIR = getEnv("DROPBOX", HOME).rstrip("/")
  DB_FILE = &"{DB_DIR}/qjump.txt"
  TEMP_FILE = &"{DB_FILE}.tmp"
  # I suggest using an editor that starts in the terminal (vim, micro, etc.):
  EDITOR = getEnv("EDITOR", "")
  # replace some prefixes in the paths:
  PREFIXES = {
    HOME: "~",
    "/opt/_trash": "/trash",
    "/opt/_home_jabba": "~",
  }.toTable

if EDITOR.len == 0:
  stderr.writeLine("Error: set your environment variable EDITOR")
  quit(1)

const SAMPLE_DB = """
# This is just a comment. Comments and blank lines are ignored.
# The bookmarks have a very simple syntax:
# "bookmark": "/path/to/dir"

"tmp":               "/tmp"
""".strip

# Is the given key (bookmark) found or not?
type
  Status = enum
    stNotFound
    stFound

  Check = enum
    chDead,
    chAlive

# Entry #####################################################################

type
  Database = object
    entries: seq[Entry]
    longestKeyLength: int
    keys: HashSet[string]

  Entry = object
    parent: ptr Database
    line: string
    key: string
    path: string
    isKeyPath: bool

proc simplifyPath(self: var Entry) =
  # Using the PREFIXES dictionary, do some changes.
  for prefix, by in PREFIXES:
    if self.path.startsWith(prefix):
      self.path = by & self.path.withoutPrefix(prefix)
      break # stop after one change

proc getRestoredPath(self: Entry): string =
  # Restore the "~" prefix to your home folder's path.
  if self.path.startsWith("~"):
    HOME & self.path.withoutPrefix("~")
  else:
    self.path

proc `$`(self: Entry): string =
  # toString() method that adds some formatting
  if self.isKeyPath:
    let spaces = " ".repeat(self.parent.longestKeyLength - len(self.key) + 4)
    "\"$1\":$2\"$3\"".format(self.key, spaces, self.path)
  else:
    self.line

proc newEntry(db: ptr Database, key, path: string): Entry =
  # constructor proc
  Entry(parent: db, key: key, path: path, isKeyPath: true)

# Database ##################################################################

proc createSampleDb(self: Database) =
  # It's called when you launch `qjump` for the very first time.
  stderr.writeLine(&"# the database file doesn't exist => creating '{DB_FILE}'")
  try:
    writeFile(DB_FILE, SAMPLE_DB)
    stderr.writeLine(&"# success")
    stderr.writeLine("")
  except IOError:
    stderr.writeLine(&"# Error: the database file '{DB_FILE}' couldn't be created.")
    quit(1)

proc readDb(self: var Database) =
  # Read the database file, parse it, and fill the data structures.
  if not fileExists(DB_FILE):
    self.createSampleDb()
  # if we get here, then the database exists:
  let
    f = open(DB_FILE, fmRead)
    pattern = re(r"'(.*)':\s*'(.*)'".replace("'", "\""))
  defer: f.close()

  var
    line_number = 0
    matches: array[2, string]
  for line in f.lines:
    inc line_number
    var e = Entry()
    e.parent = addr self
    e.line = line
    if match(line.strip, pattern, matches):
      e.key = matches[0]
      e.path = matches[1].rstrip("/")
      e.isKeyPath = true
      if len(e.key) > self.longestKeyLength:
        self.longestKeyLength = len(e.key)
      e.simplifyPath()
      #
      if e.key in self.keys:
        stderr.writeLine(
          &"# Error: the key '{e.key}' is a duplicate in line {line_number}"
        )
        stderr.writeLine(&"# Tip: remove the duplicate from '{DB_FILE}'")
        myQuit(1)
      # else:
      self.keys.incl(e.key)
    #
    self.entries.add(e)

proc getAllKeys(self: Database): seq[string] =
  # Get all the keys. Skip the other lines (comments, blank lines, etc.).
  for e in self.entries:
    if e.isKeyPath:
      result.add(e.key)

proc findSimilarKeysV1(self: Database, key: string): seq[string] =
  # Using substring match. Return the top 3 similarities.
  let key = key.toLower
  for e in self.entries:
    if e.isKeyPath and key in e.line.toLower:
      result.add(e.key)
    #
  #
  result.safeSlice(0, 3)

proc findSimilarKeysV2(self: Database, key: string): seq[string] =
  # Using the Levenstein distance. Return the top 3 similarities.
  func myCmp(s, t: string): int =
    editDistance(s, key) - editDistance(t, key)
  #
  result = sorted(self.getAllKeys(), myCmp)
  return result.safeSlice(0, 3)

proc getPath(self: Database, key: string): (string, Status) =
  # Having the key, return the corresponding path.
  # The status indicates if the key was found or not.
  proc remove_duplicates(li: seq[string]): seq[string] =
    # Return a copy that contains no duplicates and the order is kept.
    for s in li:
      if s notin result:
        result.add(s)
      #
    #
  #
  let key = key.split('/')[0]
  for e in self.entries:
    if e.isKeyPath and e.key == key:
      return (e.getRestoredPath(), stFound)
    #
  #
  stderr.writeLine("# no such bookmark")
  var bookmarks: seq[string]
  bookmarks.add(self.findSimilarKeysV1(key))  # max. 3 bookmarks are added
  bookmarks.add(self.findSimilarKeysV2(key))  # max. 3 bookmarks are added
  bookmarks = remove_duplicates(bookmarks)
  stderr.write("# similar bookmarks: ")
  stderr.writeLine(bookmarks.join(", "))
  return (".", stNotFound)

proc getUniqueHash(self: Database): string =
  # Generate a unique 3-hex-digit hash (ex.: "a07").
  let keys: seq[string] = self.getAllKeys()
  while true:
    let h = getHash()[0 ..< 3]
    if h notin keys:
      return h

proc check(self: Database, what: Check) =
  proc checkDead() =
    for e in self.entries:
      if e.isKeyPath:
        if not dirExists(e.getRestoredPath):
          stderr.writeLine(e.line)
  #
  proc checkAlive() =
    for e in self.entries:
      if not e.isKeyPath:
        stderr.writeLine(e.line)
      else:
        if dirExists(e.getRestoredPath):
          stderr.writeLine(e.line)
  #
  if what == chDead:
    checkDead()
  else:
    checkAlive()

proc dump(self: Database, to: File = stdout) =
  # Dump the database either to stdout, or to a file.
  for e in self.entries:
    to.writeLine(e)

# ############################################################################

proc saveDb(db: Database): bool =
  # Save the database to file. First we write to a temp file.
  try:
    let f = open(TEMP_FILE, fmWrite)
    db.dump(f)
    f.close()
  except IOError as e:
    stderr.writeLine("Error writing to the temp file: ", e.msg)
    return false
  #
  if getFileSize(TEMP_FILE) > 0:
    moveFile(TEMP_FILE, DB_FILE)
    return true
  # else:
  removeFile(TEMP_FILE)
  false

proc go_interactive() =
  # If the program is started without arguments, then we enter the interactive mode.
  var db = Database()
  db.readDb()
  #
  db.dump()  # print to screen
  echo "-".repeat(78)
  let info = """
[1 a c]           add (create) a new bookmark for the current directory
[2 e]             edit the bookmarks
[q qq Enter]      quit
""".strip
  echo info
  echo ""
  while true:
    var answer: string
    try:
      answer = inputExtra("-> ").strip
    except EOFError:
      echo "bye"
      break
    #
    if answer in ["q", "qq", ""]:
      echo "bye"
      break
    elif answer in ["1", "a", "c"]:
      let
        key = db.getUniqueHash()
        path = getCurrentDir()
      let e = newEntry(addr db, key, path)
      db.entries.add(e)
      let status = saveDb(db)
      if status:
        echo &"# saved: '{key}' -> '{path}'"
      #
    elif answer in ["2", "e"]:
      let cmd = &"{EDITOR} {DB_FILE}"
      discard execShellCmd(cmd)
      let before = db.getAllKeys.len
      db = Database()  # reset
      db.readDb()  # reload
      let after = db.getAllKeys.len
      if saveDb(db):  # simplify, reformat
        echo &"# number of entries before: {before}, after: {after}"
      #
    else:
      echo "Wat?"
    #
  # end while

proc print_help(to: File = stderr) =
  # -h or --help calls this
  let info = fmt"""
QJump {VERSION} by Jabba Laci (jabba.laci@gmail.com), 2026
https://github.com/jabbalaci/qjump

Usage: qj [alias] [option]

Location of DB file: {DB_FILE}

Provide an alias (bookmark) or use one of these options:

-h, --help          show this help
-v, --version       version info
-l, --list          show list of available aliases
-d, --dead          list dead (non-existing) paths
-a, --alive         list existing paths
""".strip
  to.writeLine(info)

proc print_version(to: File = stderr) =
  # -v or --version calls this
  let info = fmt"""
QJump {VERSION}
""".strip
  to.writeLine(info)

proc find_destination_directory(dname: string, parts: seq[string]): string =
  # An intelligent way to figure out what the user wants.
  var path_parts = @[dname]
  for p in parts:
    let path_so_far = path_parts.join("/")
    var found = false
    for f in sorted(walkDir(path_so_far).toSeq.filterIt(it.kind in [pcDir, pcLinkToDir])):
      let fname = f.path.extractFilename
      if p.toLower in fname.toLower:
        path_parts.add(fname)
        found = true
        break
      #
    #
    if not found:
      return path_so_far
  #
  path_parts.join("/")

# ############################################################################

proc main() =
  let args = sys.argv[1 .. sys.argv.high]
  #
  if len(args) == 0:
    go_interactive()
  else:
    let param = args[0]
    if param in ["-h", "--help"]:
      print_help(to=stderr)
      myQuit(0)
    if param in ["-v", "--version"]:
      print_version(to=stderr)
      myQuit(0)
    #
    var db = Database()
    db.readDb()
    #
    if param in ["-l", "--list"]:
      db.dump(to=stderr)
      myQuit(0)
    if param in ["-d", "--dead"]:
      db.check(chDead)
      myQuit(0)
    if param in ["-a", "--alive"]:
      db.check(chAlive)
      myQuit(0)
    #
    let key = param.rstrip("/")
    var (dname, status) = db.getPath(key)
    if status == stFound:
      if "/" notin key:
        discard
      else:
        let parts = key.split("/")
        dname = find_destination_directory(dname, parts[1 .. parts.high])
    #
    echo dname

# ############################################################################

when isMainModule:
  main()
