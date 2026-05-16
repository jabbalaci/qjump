# Converter

If you used QuickJump before, then
you can convert its database to the new format easily.

Example:

```shell
$ cat quickjump.json
{
    "~/Dropbox/nim/Nimony": "nimony",
    "~/Dropbox/c64/XC=BASIC": "xcbasic"
}

$ ./convert.py
"nimony":     "~/Dropbox/nim/Nimony"
"xcbasic":    "~/Dropbox/c64/XC=BASIC"
```

Redirect the output and use the new
database with QJump:

```shell
$ ./convert.py >qjump.txt

$ cat qjump.txt
"nimony":     "~/Dropbox/nim/Nimony"
"xcbasic":    "~/Dropbox/c64/XC=BASIC"
```
