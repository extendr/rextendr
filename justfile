export TERM_PROGRAM := ""
export VSCODE_PID := ""
export VSCODE_CWD := ""
export VSCODE_IPC_HOOK_CLI := ""
export VSCODE_GIT_ASKPASS_NODE := ""
export VSCODE_GIT_ASKPASS_EXTRA_ARGS := ""
export VSCODE_GIT_ASKPASS_MAIN := ""
export VSCODE_GIT_IPC_HANDLE := ""
export VSCODE_INJECTION := ""
export VSCODE_PROFILE_INITIALIZED := ""
export VSCODE_PYTHON_AUTOACTIVATE_GUARD := ""
export POSITRON := ""
export POSITRON_LONG_VERSION := ""
export POSITRON_MODE := ""
export POSITRON_VERSION := ""

default:
  just --list

check: 
  R --quiet -e "devtools::check()"

test: 
  R --quiet -e "devtools::test()"

update-snaps:
  R --quiet -e "testthat::snapshot_accept()"

lint: 
  jarl check R/ 

lint-fix: 
  jarl check R/ -f 

fmt:
  air format R/

doc:
  R --quiet -e "devtools::document()"