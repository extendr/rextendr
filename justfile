set default-list

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

check:
    R --quiet -e "devtools::check()"

test:
    R --quiet -e "devtools::test()"

update-snaps:
    R --quiet -e "testthat::snapshot_accept()"

lint:
    jarl check R/* tests/testthat/*
    air format --check R/* tests/*

lint-fix:
    jarl check R/* -f 

alias fmt := format
format:
    air format R/* tests/*

alias doc := document
document:
    R --quiet -e "devtools::document()"
