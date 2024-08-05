# REPLizing Unison, 2D-Coding, Death to Vertical Scrolling, and Salvaging `cd`

*This is version 0 of the description, quickly put together in defense of the `cd` command in Unison's codebase manager `ucm`. Updates and more background incoming.*

`ucm`, the Unison codebase manager, has recently deprecated the useful `cd` command -- yet that command had made the wrapper scripts here simpler, as the current "dir" or namespace is handled by the codebase manager (and thus mostly avoids having to use stanzas). The irony of asking the functional Unison crew to un-deprecate `cd` and to keep handling this state is not lost..

- *We use `ucm` 0.5.25. Code here still breaks easily on version changes.*

- *The code below is in bash_scripts. Ignore the old Julia code in the other dirs for now; it still uses stanzas..*

<br>

## A Motivating Example

We try to cajole **Unison**'s `ucm` codebase manager to act as a REPL, mainly for educational (well, mostly mine) purposes. Our gold standard is **Julia**'s outstanding REPL -- I would encourage you to quickly install it and play around with it for 10 minutes; you'll see why. In fact, we plan to effectively *skin* the Julia REPL into a Unison one.

As an intermediate learning step, we hacked together a few bash wrapper scripts around `ucm`. The scripts are named like their standard Unix counterparts, prefixed with "u" -- `uls`, for example, lists the terms of the current Unison namespace. Just put this repo's `bash_scripts` subdir into your PATH. (The "new" `ucb` creates and activates codebases.) The rest is self-explatory, ha ha.

Behold `bash` as Unison REPL:

```
$ echo $0
-bash
$ ucb
ERROR: ucb: no codebase set; set with 'ucb <codebase>' or create with 'ucb -C <codebase>'
$ ucb -C MyUnisonCodebase
codebase created; installing standard lib -- this may take a few minutes..
  Downloaded 3633 entities.
  I installed @unison/base/releases/3.13.0 as unison_base_3_13_0.
current codebase: /home/martin/unisandbox/MyUnisonCodebase
$ uls
  1. lib/ (7192 terms, 180 types)
$ ucd lib
$ upwd
scratch/main:.lib
$ uls
  1. unison_base_3_13_0/ (7192 terms, 180 types)
$ ucd unison_base_3_13_0
$ uls | head -n4
  1.  Any          (builtin type)
  2.  Any/         (4 terms)
  3.  Boolean      (builtin type)
  4.  Boolean/     (53 terms)
$ ucd ..
$ ucd ..
$ uls
  1. lib/ (7192 terms, 180 types)
$ uwatch 1+1
2
$ uadd myconst = 13
new term definition added
$ uwatch myconst
13
$ uupd myconst = 42
term definition updated
$ uwatch myconst
42
$ uadd 'helloPlanet _ = printLine "Hello, world!"'
new term definition added
$ uls
  1. helloPlanet (∀ _. _ ->{IO, Exception} ())
  2. lib/        (7192 terms, 180 types)
  3. myconst     (Nat)
$ umv helloPlanet helloWorld
  Done.
$ urun helloWorld
Hello, world!
$ ucat helloWorld
  _ -> printLine "Hello, world!"
$ ufind .  |  head -n4
  1.    helloWorld : ∀ _. _ ->{IO, Exception} ()
  2.    structural ability lib.unison_base_3_13_0.abilities.Abort
  3.    lib.unison_base_3_13_0.abilities.Abort.abort : {Abort} a
  4.    lib.unison_base_3_13_0.abilities.Abort.abort.doc : Doc
$ ufind .  |  grep hello
  1.    helloWorld : ∀ _. _ ->{IO, Exception} ()
```

<br>

### Notes:

* move became mv; later, delete might become (u)rm; delete.namespace -> `(u)rm namespace.` -- the final dot denoting a namespace like a `subdir/` in Unix

* find operates, by default, with the Unix logic, with `.` meaning root in the Unison context

* we can combine `u*` pipe-wise with grep, head, etc.

* **we really like that the current dir is a state in the codebase, and we really like to modify it with `cd` (otherwise we would have to keep track of this state outside) -- PLEASE PLEASE keep `cd`!**

<br>

The scripts work by piping commands into ucm, and then filtering the output. Here is, for example, `ufind`:

```
#!/usr/bin/env bash
. ucommon.sh

_USAGE="
Finds Unison terms.
"
(( $# == 0 ))  &&  uexit

# TODO pipe breaks with, eg, '| head -n5'; that's why we use cat reduntantly
echo "find-in.all $@" | _ucm0 | deprompt.sh > ufind.stdout  &&  cat ufind.stdout
```

`_ucm0` suppresses the header, color codes, right-trims spaces.. The superfluous `cat` here makes this SIGPIPE-friendly.

<br>
<br>

(

A few wishes for `ucm`:

* *PLEASE PLEASE: `cd`*

* `--no-banner`, `--no-colors`, `--no-unicode` options

* (maybe make `ucm` work better with SIGPIPE? Need to look into this, hope not my fault)

* the behavior of `run` as command line argument seems to have changed; previously I could `ucm -c MyCodebase run helloWorld` -- now this requires a path; suppose this has similar reason to `cd`-deprecation

* `--no-prompt` to turn off prompt (stuff like `scratch/main:.lib>` appears in stdout)

)

<br>
<br>

## Next Up

This is mainly a dryrun. We'd next like to combine the `urun`, `uwatch`, `uadd`, and `uupd` commands into a single `u` command, that automatically detect term definitions or expressions, and just "does the right thing":

```
$ u 1+1
2
$ u sqr x = x*x      # aha, '=' means new or updated term
$ u sqr 2
4
```

This, in turn, hopefully leads to full REPL (a Julia REPL mode most likely) -- with `u>` prompt (or current namespace):

```
u> 1+1
2
u> sqr x = x*x
u> sqr 2
4
```

<br>
<br>

## Unison in Our Nutshell

Unison has a clever (Gödel-like) way of enumerating code. This frees the layer of human-readable names from indexing and referencing code, to serving but one master -- the human. We can finally name and re-name galore! (One-time unit testing, distributed systems, never-broken codebases of course are also nice to have, but NAMING, my Gods..)

The structure of terms in Unison namespaces is ideal for using the file system metaphors. Unison can leverage million-ennia of developers' muscle memory training.

<br>
<br>

## 2D-Coding

Our code is usually structured linearly, as code blocks in a file. We often have sequences of conceptually different code block types -- comments, docstrings, happy-path code, error-handling code, module exports..

It would be great if we could arrange these blocks in a 2D view. Imagine an Excel with large cells, each containing a function, its docstring, an error-check for that function's arguments.. We would arrange these in a 2D grid that allows for easy consistency checks, with minimal vertical scrolling (see sidenote below):

```
/*happy*/         /*doc str*/ /*sad-path*/

...
----------------------------------------------------------------------
func A(x,y):     | A:doc"A bla | func checkA(x,y): | // TODO
  checkA(x,y)    |  bla blu    |   if ...          | // use long double
  return x/y     |  bla"       |
----------------------------------------------------------------------
<next row>       | ...         | ...               | ...
...
```

We can only emulate such structures, eg, in whitespace-oblivious languages like C++, by indenting, putting comments to the right, using a custom preprocessor or to-be-written IDE plugins.. A structured language like Unison could provide a super-framework for such an IDE -- we just put an additional "add/update" button inside each cell and voilà.

(Now, true, `cd` is no longer needed here. But I think the crack of `cd` would be helpful for learners; later they will buy the cocaine of `deploy.all PROD`. PLEASE PLEASE?)


### Sidenote on Vertical Scrolling

2D-Coding also alleviates another problem of linear sequences of code blocks: vertical scrolling. Death to it.

Even if we split our code into somewhat manageable files, we find ourselves continuously scrolling hither and tither, visually grasping at code structures for orientation, ever skimming and scanning, the sorry twins of micro-drains on our concentration. I rest my case.

