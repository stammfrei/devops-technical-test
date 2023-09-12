#! /usr/bin/env bash

# This script groups many "dev" commands for this projects
# see each command comment for usage.

# Check we are on repo root
test -d .git || exit_failed 1 "You must execute this file from project root"

# Import the local common stuff
source ./ci/lib/bash/utils.sh

# --- Hello world example
# Build the hello world example
function build-packer-hw() {
	requires "packer" "git"

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

		log i "Validating and building packer files"
		packer validate "$hw_folder" &&
			packer build -only="hello-world.docker.ubuntu" "$hw_folder/docker-hello-world.pkr.hcl" &&
			packer build -only="second-world.docker.hello-world" "$hw_folder/docker-hello-world.pkr.hcl"
	} || {
		err_code="$?"
		log e "failed to build image"
		cd "${project_root}" || exit_failed 1 "Failed to go back to project root '${project_root}'"
		return "$err_code"
	}

	cd "${project_root}" || exit_failed 1 "Failed to go back to project root '${project_root}'"
}

# Trigger build on file change for the hello world example
function build-loop-packer-hw() {
	requires "docker"

	hw_folder="packer/hello-world"

	find "$hw_folder" -type f |
		SHELL=bash entr -cs "./ci/build.sh build-packer-hw && ./ci/build.sh test-hw-img"
}

# Test the hello world image
function test-hw-img() {
	requires "docker"

	log i "Testing the hello world image content"
	docker run --rm -it "packer-hello-world:$(git rev-parse --short HEAD)" \
		"pwd && ls -liahs && cat hello.txt && ls -liahs /app"
}

# Run the hello world image
function run-hw-img() {
	requires "docker"

	log i "Running the hello world image"
	docker run --rm -it "packer-hello-world:$(git rev-parse --short HEAD)" bash
}

# --- Wordpress build images
# Build the wordpress image
function build-wp() {
	requires "packer" "git"

	# Go back to project root at end of execution, the var must expand now
	project_root="${PWD}"

	tag=${1:-"emptytag"}
	hw_folder="packer/wordpress"

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

		log i "Validating and building packer files"
		packer validate "$hw_folder"

		if [ "${SKIP_BASE:-"false"}" == "false" ]; then
			packer build -only="base-ansible.docker.debian" "$hw_folder"
		else
			log i "Skipped base image build"
		fi

		packer build -only="wordpress.docker.base-ansible" "$hw_folder"
	} || {
		err_code="$?"
		log e "failed to build image"
		cd "${project_root}" || exit_failed 1 "Failed to go back to project root '${project_root}'"
		return "$err_code"
	}

	cd "${project_root}" || exit_failed 1 "Failed to go back to project root '${project_root}'"
}

# Trigger build on file change for the hello world example
function build-loop-wp() {
	requires "entr" "find"
	hw_folder="packer/wordpress"

	find "$hw_folder" -type f |
		SHELL=bash entr -cs "./ci/build.sh check && ./ci/build.sh build-wp && ./ci/build.sh test-wp"
}

# Test the hello world image
function test-wp() {
	requires "docker"

	log i "Testing the wordpress image content"
	docker run --rm -it "wordpress:$(git rev-parse --short HEAD)" \
		"test -x /opt/ansible.sh"
}

# Run the hello world image
function run-wp() {
	requires "docker"

	log i "Running the wordpress image"
	docker run --rm -it "wordpress:$(git rev-parse --short HEAD)" bash
}

# --- utils
# lint and format files
function check() {
	requires "shfmt" "shellcheck" "grep"

	log i "format sh files"
	shfmt -w .

	# lint bash files through shellcheck
	# we identify then by the shebang
	ci_files="$(grep -rE "^#.+/bin.+bash" ci -l)"
	build_files="$(grep -rE "^#.+/bin.+bash" packer -l)"

	log i "Checking sh files"
	# shellcheck disable=2086
	shellcheck $ci_files $build_files
}

# Equivalent to `if __name__ == "__main__":` in python
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
