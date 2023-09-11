#! /usr/bin/env bash
#
# This script groups many "dev" commands for this projects
# see each command comment for usage.

# Check we are on repo root
test -d .git || exit_failed 1 "You must execute this file from project root"

# Import the local common stuff
source ./ci/lib/bash/utils.sh

# Build the hello world example
function build-packer-hw() {
	trap "cd ${PWD}" EXIT SIGINT # Go back to project root at end of execution

	tag=${1:-"emptytag"}
	hw_folder="packer/hello-world"

	# If explicit tag is not provided, use commit sha
	if [ "$tag" == "emptytag" ]; then
		echo 1>&2 "Using git sha as tag"
		sha=$(git rev-parse --short HEAD)
		tag=$sha
	fi

	(
		packer init "$hw_folder" &&
			echo 2>&1 "Validating packer files" &&
			packer validate \
				-var "tag=${tag}" "$hw_folder" &&
			echo 2>&1 "Build packer output" &&
			packer build \
				-var "tag=${tag}" "$hw_folder/docker-hello-world.pkr.hcl"
	) ||
		exit_failed 1 "failed to build image"

	exit 0
}

# Trigger build on file change for the hello world example
function build-loop-packer-hw() {
	hw_folder="packer/hello-world"

	find "$hw_folder" -type f |
		entr -cs "./ci/build.sh build-packer-hw"
}

# Test the hello world image
function test-hw-img() {
	docker run -it
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	set -o errexit  # Interrompt le script en cas d'erreur
	set -o errtrace # Interrompt le script en cas d'erreur dans une fonction ou un shell nesté
	set -o nounset  # Ne permet pas l'utilisation de variable non définies
	set -o pipefail # Permet de catch les erreurs dans les pipelines dans ce cas `command_fail | command_ok`

	case "${1:-}" in
	-h | --help)
		echo "# Requirements"
		echo "----------"
		echo "GITLAB_TOKEN env var must be set."
		echo
		echo "# Commands"
		echo "----------"
		echo
		echo "Start a build: "
		echo "$0 build"
		echo
		echo "Start a build everytime a file in src is changed: "
		echo "$0 build-loop"
		echo
		echo "Test a build:"
		echo "$0 test"
		echo
		;;

	*)
		# Appellez ici votre fonction principale avec tous les arguments
		cmd=${1:?Please input a valid command, see help for usage}
		shift
		$cmd "$@"
		echo pwd
		exit $?
		;;
	esac
fi
