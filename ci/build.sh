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
	# Go back to project root at end of execution, the var must expand now
	project_root="${PWD}"

	tag=${1:-"emptytag"}
	hw_folder="packer/hello-world"

	# If explicit tag is not provided, use commit sha
	if [ "$tag" == "emptytag" ]; then
		log i "Using git sha as tag"
		sha=$(git rev-parse --short HEAD)
		tag=$sha
	fi

	# Export packer dynamic vars
	export PKR_VAR_tag="$tag"

	{
		log i "Initialize packer"
		packer init "$hw_folder"

		log i "Validating packer files"
		packer validate "$hw_folder"

		log i "Build packer output"
		packer build "$hw_folder/docker-hello-world.pkr.hcl"
	} || {
		err_code="$?"
		log e "failed to buld image"
		cd "${project_root}" || exit_failed 1 "Failed to go back to project root '${project_root}'"
		return "$err_code"
	}

	cd "${project_root}" || exit_failed 1 "Failed to go back to project root '${project_root}'"
}

# Trigger build on file change for the hello world example
function build-loop-packer-hw() {
	hw_folder="packer/hello-world"

	find "$hw_folder" -type f |
		SHELL=bash entr -cs "./ci/build.sh build-packer-hw && ./ci/build.sh test-hw-img"
}

# Test the hello world image
function test-hw-img() {
	log i "Testing the hello world image content"
	docker run --rm -it "packer-hello-world:$(git rev-parse --short HEAD)" "pwd && ls -liahs && cat hello.txt"
}

# Run the hello world image
function run-hw-img() {
	log i "Running the hello world image"
	docker run --rm -it "packer-hello-world:$(git rev-parse --short HEAD)" bash
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
		echo
		echo "# Commands"
		echo "----------"
		;;

	*)
		# Appellez ici votre fonction principale avec tous les arguments
		cmd=${1:?Please input a valid command, see help for usage}
		shift
		$cmd "$@"
		exit $?
		;;
	esac
fi
