#!/usr/bin/env bash




set -o pipefail




eecho() {
    echo "${1}" >&2
}




eexit() {
    eecho "ERROR: ${1}"
    exit 99
}

aexit() {
    eecho "ERROR::ASSERT: ${1}"
    exit 99
}

uexit() {
    eecho "${_USAGE}"
    exit 2
}



