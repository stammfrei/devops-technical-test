#! /usr/bin/env bash

# Set color on execution one, to avoid calling it at
# each log calls
if [[ "$(tput colors)" -gt 8 ]]; then
	_color_green=$(tput setaf 2)
	export _color_green
	_color_yellow=$(tput setaf 3)
	export _color_yellow
	_color_red=$(tput setaf 1)
	export _color_red
	_color_blue=$(tput setaf 4)
	export _color_blue
	_color_reset=$(tput sgr0)
	export _color_reset
else
	export _color_yellow=""
	export _color_red=""
	export _color_blue=""
	export _color_reset=""
fi

# log to stderr, usage: log <level = info> <msg>
function log() {
	level=${1:?Povide a valid log level, choices: i/I/info/INFO (warn,error,debug)}
	shift
	msg=${*:?You need to provide a <msg> as second argument}

	case $level in
	i | I | info | INFO)
		level="${_color_green}INFO${_color_reset}"
		;;
	w | W | warn | WARN)
		level="${_color_yellow}WARN${_color_reset}"
		;;
	e | E | error | ERROR)
		level="${_color_red}ERROR${_color_reset}"
		;;
	d | D | debug | DEBUG)
		level="${_color_blue}DEBUG${_color_reset}"
		;;
	*)
		log e "bad log level given, falling back to info"
		level=INFO
		;;
	esac
	echo 1>&2 "${level}: ${msg}"
}

# Exit with <code> and <msg>
function exit_failed() {
	code=${1:-"1"}
	msg=${1:-"script $0 failed unexpectedly"}

	echo 1>&2 "$msg"
	exit "$code"
}

# Check that requireds [<bin>] are in $PATH
function requires() {
	bins=${*:?Please provide one or more binarie to check}

	for bin in $bins; do
		test -n "$(which "$bin")" || {
			log e "${bin} is required for this script and not in path"
			exit 1
		}
	done
}

# Check if docker image with <image:tag> exists
function check_image() {
	image=${1:?Please provide a docker image with 'image:tag' format}
	docker images --format "{{.Repository}}:{{.Tag}}" | grep -ic "$image"
}
