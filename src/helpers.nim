import std/hashes
import std/rdstdin
import std/strformat
import std/strutils
import std/times


func rstrip*(s: string, chars: string): string =
  ## like Python's rstrip() string method
  var bs: set[char] = {}
  for c in chars:
    bs = bs + {c}
  s.strip(leading = false, trailing = true, chars = bs)

func withoutPrefix*(s, prefix: string): string =
  ## Remove the given prefix. Returns a new string.
  result = s
  result.removePrefix(prefix)

proc inputExtra*(prompt: string = ""): string {.raises: [EOFError].} =
  # Ctrl+c and Ctrl+d throws an EOFError exception
  var line: string = ""
  let val = readLineFromStdin(prompt, line)    # line is modified
  if not val:
    raise newException(EOFError, "abort")
  line

proc getHash*(): string =
  ## Returns a hash string with hexa digits.
  ## The hash value is calculated from the Unix epoch time.
  let
    et: float = epochTime()   # a float because of sub-second resolution
    h = hash(et).abs          # the hash can be a negative value, hence the abs()
  #
  &"{h:x}"
