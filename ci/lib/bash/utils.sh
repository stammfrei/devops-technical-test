#! /usr/bin/env bash

# Exit with <code> and <msg>
exit_failed() {
	code=${1:-"1"}
	msg=${1:-"script $0 failed unexpectedly"}

	echo 1>&2 "$msg"
	exit "$code"
}
