# A Unison REPL, 2D-Coding, and Vertical Scrolling Begone

*This is version 0 of the description, quickly put together in defense of the `cd` command in `ucm`. Updates and more background incoming.*

*We use `ucm` 0.5.25. Code here still breaks easily on version changes.*

<br>

## A Motivating Example

We try to cajole **Unison**'s `ucm` codebase manager to act as a REPL, mainly for educational (well, mostly mine) purposes. Our gold standard is **Julia**'s outstanding REPL -- I would encourage you to quickly install it and play around with it. In fact, we plan to effectively *skin* the Julia REPL into a Unison one.

As an intermdeiate learning step, we hacked together a few bash wrapper scripts around `ucm`. The scripts are named like their standard Unix counterparts, prefixed with "u" -- `uls`, for example, lists the terms of the current Unison namespace. Just put this repo's `bash_scripts` subdir into your PATH. The "new" `ucb` creates and activates codebases.

Behold `bash` as Unison REPL:

```
$ echo $0
-bash
$ ucb
/home/martin/unisandbox/MyUnisonCodebase
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
$ uls | head -n5
  1.  Any          (builtin type)
  2.  Any/         (4 terms)
  3.  Boolean      (builtin type)
  4.  Boolean/     (53 terms)
  5.  Bytes        (builtin type)
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
$ ufind . | head -n5
  1.    helloWorld : ∀ _. _ ->{IO, Exception} ()
  2.    structural ability lib.unison_base_3_13_0.abilities.Abort
  3.    lib.unison_base_3_13_0.abilities.Abort.abort : {Abort} a
  4.    lib.unison_base_3_13_0.abilities.Abort.abort.doc : Doc
  5.    lib.unison_base_3_13_0.abilities.Abort.abortWhen : Boolean ->{Abort} ()
$ ufind . | grep hello
  1.    helloWorld : ∀ _. _ ->{IO, Exception} ()
```