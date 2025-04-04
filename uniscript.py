#!/usr/bin/env python3

import sys
import os
from os.path import isfile, isdir, getmtime

import subprocess

import shutil

import traceback



# ENDUSER EDIT START

class Conf:
    verbose = False      # turn uniscript-infos on/off

    errorexit = 125     # code signals that something went wrong with uniscript.py itself, rather than the called Unison code;
                        # modify to un-clash with your (passed-through) Unison script exit codes

# ENDUSER EDIT END


def error(s):  raise Exception(f"[ERROR::uniscript] {s}")

class EnduserError(Exception):  pass
def erroruser(s):  raise EnduserError(f"[ERROR::uniscript]: {s}")

class AssertError(Exception):  pass
def errorassert(s):  raise AssertError(f"[ERROR_ASSERT::uniscript] {s}")


def info(*args, **kwargs):
    if Conf.verbose:  print("[INFO::uniscript]", *args, **kwargs)


def older(x,y):  return getmtime(x) < getmtime(y)

def exe(cmd, *, fail=True):
    p = subprocess.Popen("set -o pipefail ; " + cmd, shell=True, executable="/bin/bash", stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    o,e = p.communicate()
    rc = p.returncode
    lso = o.decode(encoding="UTF-8").split("\n")[:-1];  lse = e.decode(encoding="UTF-8").split("\n")[:-1]
    if p.returncode != 0 and fail:  raise Exception(  "exe: non-zero return code in command:\n%s\n-----stdout-----\n%s\n-----stderr-----:\n%s" % (cmd, "\n".join(lso), "\n".join(lse))  )
    return rc,lso,lse

def touch(s):  open(s, "w").close()

def file2ls(fname):
    with open(fname, "r") as file:
        return [ line.rstrip("\r\n") for line in file ]

def ls2file(ls, fname):
    with open(fname, "w") as file:
        for s in ls:  file.write(s + "\n")

def arefiles(ls):
    for s in ls:
        if not isfile(s):  return False
    return True

def getmtimes(ls):
    RET = []
    for s in ls:  RET.append(getmtime(s))
    return RET



class Rule:
    def __init__(self, targs, deps, recipes, *, phony=False):
        self.targs = targs
        self.deps = deps
        self.recipes = recipes
        self.phony = phony
    def run(self):
        for dep in self.deps:
            rule_to_create = get_rule(dep)
            if rule_to_create == None:  # must be file!
                if not isfile(dep):  error(f"file '{dep}' not found")
            else:
                rule_to_create.run()

        if self.phony == True:  # if blocks for printfs..
            info(f"target {self.targs}: phony => run")
            do = True
        elif not arefiles(self.targs):
            info(f"target {self.targs}: file missing => run")
            do = True
        elif len(self.deps) == 0:
            info(f"..target {self.targs}: file exists & no deps => skip")
            do = False
        elif min(getmtimes(self.targs)) < max(getmtimes(self.deps)):
            info(f"target {self.targs}: too old => run")
            do = True
        else:
            info(f"..target {self.targs}: still valid => skip")
            do = False
        if not do:  return []      

        RET = []        
        for recipe in self.recipes:
            if callable(recipe):
                recipe()
            else:
                _,RET,_ = exe(recipe)
        return RET

RULES = []
def get_rule(targ):  # single target!
    for rule in RULES:
        if targ in rule.targs:  return rule
    return None




def modify_script(targ, dep):
    ls = file2ls(dep)
    if len(ls) > 0:
        if ls[0].startswith("#!"):  ls[0] = "-- " + ls[0]
    ls.append(""); ls.append(""); ls.append(""); ls.append("")
    ls.append("-- premain is called before main to signal end of UCM header/hint/etc. output")
    ls.append(  "premain_ee0870f370bd4b018594b3eb1e796594 _ =")
    ls.append("""  printLine ("Hello, df881bc3422e4a37a24ee84694d57934 !")""")
    ls2file(ls, targ)

def check_parse(fname_stdout, cb_dir_to_delete):  # does nothing or raises exception
    ls = file2ls(fname_stdout)
    for s in ls:
        if "df881bc3422e4a37a24ee84694d57934" in s:  return
    shutil.rmtree(cb_dir_to_delete)
    for s in ls:  print(s, file=sys.stderr)
    erroruser("parse error when adding code to script codebase; see UCM output above")

def check_main(fname_stdout):
    ls = file2ls(fname_stdout)
    for s in ls:
        if "I looked for a function `main`" in s:  erroruser("no 'main' function found")

def main(args):
    if len(args) == 0:  print(_USAGE);  exit(Conf.errorexit)

    fname_script0,args_script = os.path.realpath(args[0]),args[1:]
    if not isfile(fname_script0):  erroruser(f"Unison script file '{args[0]}' not found")
    #s_args = " ".join( [f"'{s}'" for s in args_script] )

    fname_script =              fname_script0 + "._uniscript_.u"

    dname_ucb_libbase =         fname_script0 + "._uniscript_.unison_cb_libbase"
    fname_ucb_libbase_sqlite =  dname_ucb_libbase + "/.unison/v2/unison.sqlite3"
    
    dname_ucb_live =            fname_script0 + "._uniscript_.unison_cb_live"
    fname_ucb_live_sqlite =     dname_ucb_live + "/.unison/v2/unison.sqlite3"

    fname_ucb_live_ok =         dname_ucb_live + ".ok"
    fname_ucb_live_compiled0 =  dname_ucb_live + ".compiled"  # used in UCM, which adds the 'uc'
    fname_ucb_live_compiled =   dname_ucb_live + ".compiled.uc"


    fname_ucm_stdout =          fname_script0 + "._uniscript_.ucm_stdout"
    fname_ucm_stderr =          fname_script0 + "._uniscript_.ucm_stderr"


    # de-shebang; and insert 'canary' function to check parse
    RULES.append(   Rule(   [fname_script], 
                            [fname_script0], 
                            [   lambda: modify_script(fname_script, fname_script0)
                            ]
                        ) 
                )

    # create libbase template codebase
    RULES.append(   Rule(   [fname_ucb_libbase_sqlite],
                            [],
                            [   f"ucm --no-file-watch --codebase-create {dname_ucb_libbase} --exit",
                                f"""echo "lib.install @unison/base" | ucm --no-file-watch --codebase {dname_ucb_libbase}"""
                            ]
                        ) 
                )

    # create live codebase: copy from template and add script code
    RULES.append(   Rule(   [fname_ucb_live_sqlite],
                            [fname_ucb_libbase_sqlite, fname_script],
                            [   #f"rm -f {fname_ucb_live_ok}",
                                f"rm -rf {dname_ucb_live}",
                                f"cp -r {dname_ucb_libbase} {dname_ucb_live}",
                                #f"""echo -e "load {fname_script}\\nupdate\\nrun premain_ee0870f370bd4b018594b3eb1e796594\\nrun main {s_args}" | ucm --no-file-watch --codebase {dname_ucb_live} > {fname_ucm_stdout} 2> {fname_ucm_stderr}""",
                                f"""echo -e "load {fname_script}\\nupdate\\nrun premain_ee0870f370bd4b018594b3eb1e796594" | ucm --no-file-watch --codebase {dname_ucb_live} > {fname_ucm_stdout} 2> {fname_ucm_stderr} """,
                                #f""" (( $(grep -c 'df881bc3422e4a37a24ee84694d57934' {fname_ucm_stdout}) == 0 ))  &&  rm -rf {dname_ucb_live} """,
                                lambda: check_parse(fname_ucm_stdout, dname_ucb_live)
                            ]
                        )
                )

    # compile
    RULES.append(   Rule(   [fname_ucb_live_compiled],
                            [fname_ucb_live_sqlite],
                            [   f""" echo -e "compile main {fname_ucb_live_compiled0}" | ucm --no-file-watch --codebase {dname_ucb_live} > {fname_ucm_stdout} 2> {fname_ucm_stderr} """,
                                lambda: check_main(fname_ucm_stdout)
                            ]
                        )
                )



    # run the rules!
    RULES[-1].run()

    # if main is missing, the above check_main lambda should already fail; if compile failed otherwise, or 'main not found' string pattren changed:
    if not isfile(fname_ucb_live_compiled):
        ls = file2ls(fname_ucm_stdout)
        for s in ls:  print(s, file=sys.stderr)
        erroruser("compile failed; unable to detect reason; see UCM output above; run 'ucm -c <live codebase>' and try to compile 'main' manually")



    # exec
    os.execvp("ucm", ["ucm", "run.compiled", fname_ucb_live_compiled] + args_script)






_USAGE = """
Executes Unison code as script and calls its 'main' function.

Usage:
> uniscript.py  myscript.u  ..
(or add a shebang line at the top of your script)

Example:
> cat myscript.u
#!/usr/bin/env uniscript.py

main : '{IO, Exception} Unit
main _ =
  use Text ++
  args : [Text]
  args = getArgs()
  printLine ("Hello, " ++ Text.join " and " args ++ "!")

> myscript.u Laura Sally
Hello, Laura and Sally!

Method:
When a newly created script is run, a Unison codebase is created, and libbase downloaded.
(When the script is edited and re-run, however, this expensive step is skipped).
The script is copied, de-shebang-ed, added to a live copy of the libbase codebase,
compiled, and executed. (All steps only run if needed, in make-fashion.)
"""
if __name__ == '__main__':
    try:
        main(sys.argv[1:])
    except EnduserError as e:
        print(e, file=sys.stderr)
        exit(Conf.errorexit)
    except Exception as e:
        traceback.print_exc(file=sys.stderr)
        exit(Conf.errorexit)





