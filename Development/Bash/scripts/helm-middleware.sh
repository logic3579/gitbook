#!/bin/bash
set -e
set -o pipefail

# Help info
### Use helm command manage middleware package by custom helm repo.
###
### Usage:
###   ./helm-middleware.sh [flags] [command] [middleware]
###
### Flags:
###   -n    namespace name
###   -h    help for script
###
### Available command:
###   list         list all installed middleware package
###   install      create package directory (if not exists) and install middleware
###   uninstall    uninstall middleware package and remove directory
###
### Available middleware:
###   kafka            Cluster mode, use kraft protocol
###   redis            Single mode, one instance
###   redis-cluster    Cluster mode, three master instance
###   rocketmq         2m-2s-async
###
### Examples:
###   # Show help infomation
###   ./helm-middleware.sh -h
###
###   # List all middleware package in test namespace
###   ./helm-middleware.sh -n dev list
###
###   # Install kafka to test namespace
###   ./helm-middleware.sh -n test install kafka
###
###   # Uninstalled redis-cluster in uat namespace
###   ./helm-middleware.sh -n uat uninstall rocketmq
###
function show_help() {
  perl -ne 'print if s/^### ?//' "$0" || \
  sed -rn 's/^### ?//;T;p;' "$0"
  exit 0
}

# logging function
function log_info() {
  local message="$@"
  echo "[INFO] $message"
}
function log_warning() {
  local message="$@"
  echo "[WARNING] $message" >&2
}
function die_exit() {
  local message="$@"
  echo "[ERROR] $message" 1>&2
  exit 111
}


# global environment
namespaces=(
    "dev"
    "test"
    "uat"
)
actions=(
    "list"
    "install"
    "uninstall"
)
middlewares=(
    "kafka"
    "redis"
    "redis-cluster"
    "rocketmq"
)
helm_reponame="my-repo"


# pre check
function pre_check() {
    # getopts and help info
    while getopts ":n:h" opt; do
        case $opt in
            n) namespace=$OPTARG;;
            h) show_help;;
            \?) die_exit "Invalid option: -$OPTARG, only support flag (-n or -h)";;
        esac
    done

    # check -n flag and namespace exist in the namespaces
    if [[ -n "$namespace" ]]; then
        grep -qw $namespace <<< "${namespaces[@]}" || die_exit "Kubernetes namespace must be in (${namespaces[@]})"
    else
        show_help
    fi

    # shift flag and opt
    shift $((OPTIND-1))

    # check action and middleware
    action=$1
    middleware=$2
    if [[ -z "$action" ]];then
        die_exit "Command action cannot be null and must be in (${actions[@]})"
    elif [[ -n "$action" ]];then
        grep -qw $action <<< "${actions[@]}" || die_exit "Command action must be in (${actions[@]})"
        if [[ "$action" != "list" && -z "$middleware" ]];then
            die_exit "Middleware cannot be null and must be in (${middlewares[@]})"
        elif [[ -n "$middleware" ]];then
            grep -qw $middleware <<< "${middlewares[@]}" || die_exit "Middleware must be in (${middlewares[@]})"
        fi
    else
        die_exit "Unknow error, check it"
    fi

    # check custom helm repo
    command helm &> /dev/null || die_exit "Command helm not found, install it first: https://helm.sh/docs/intro/install/"
    helm repo list |grep -qw ${helm_reponame} || die_exit "Custom helm repo ${helm_reponame} not exist, must add it first"
}

function list() {
    printf "%-15s %-15s\n" "Namespace" "Middleware"
    for m in $(helm -n $1 list |awk '{print $1}' || echo none)
    do
        grep -qw $m <<< "${middlewares[@]}" && printf "%-15s %-15s\n" $1 $m
    done
    log_info "Select middleware list successfully"
}

function install() {
    # todo: --set xxx
    install_result=$(helm -n $1 upgrade --install $2 "$helm_reponame/$2" 2>&1) || die_exit $install_result
    log_info "Install middleware [$2] successfully"
}

function uninstall() {
    uninstall_result=$(helm -n $1 uninstall $2 2>&1) || die_exit $uninstall_result
    log_info "Uninstall middleware [$2] successfully"
}

function main() {
    case $action in
    list)
        list $namespace
        ;;
    install)
        install $namespace $middleware
        ;;
    uninstall)
        uninstall $namespace $middleware
        ;;
    *)
        die_exit "Unknow error, check it"
    esac
}

pre_check "$@"
main "$@"
