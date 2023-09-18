#! /usr/bin/env bash

# This script contains the effective logic to deploy the wordpress container
#

# Check we are on repo root
test -d .git || exit_failed 1 "You must execute this file from project root"

# Import the local common stuff
source ./ci/lib/bash/utils.sh

# Deploy the registry with terraform
function deploy-registry() {
	requires terraform

	TF_AUTO_APPROVE=${TF_AUTO_APPROVE:-"false"}
	if [ "$TF_AUTO_APPROVE" == "true" ]; then
		auto_approve="-auto-approve"
	fi

	log i "Starting terraform deploy"
	tfcmd="terraform -chdir=terraform/registry"
	$tfcmd apply "${auto_approve:-}"
}

# Deploy the ecs cluster with terraform
function deploy-ecs-cluster() {
	requires terraform

	if [ "${TF_AUTO_APPROVE:-"false"}" == "true" ]; then
		auto_approve="-auto-approve"
	fi

	log i "Starting terraform deploy"
	tfcmd="terraform -chdir=terraform/ecs"
	$tfcmd apply "${auto_approve:-}"
}

# Strip quotes injected by terraform output -json command
function strip-quotes() {
	var=${1:?Please input a string to parse}
	var=${var#\"}
	var=${var%\"}
	echo -n "$var"
}

function build-push-image() {
	requires terraform

	tfcmd="terraform -chdir=terraform/registry"
	log i "retrieving registry login informations form terraform"
	packer_folder="packer/wordpress"

	log i "initialize and validate packer configuration"
	packer init "$packer_folder"

	log i "build and push packer image"
	PKR_VAR_registry_url=$(strip-quotes "$($tfcmd output -json registry_url)")
	export PKR_VAR_registry_url

	PKR_VAR_repository_url=$(strip-quotes "$($tfcmd output -json repository_url)")
	export PKR_VAR_repository_url

	export PKR_VAR_tag="toto"

	packer validate "$packer_folder"
	if [ "${SKIP_BASE:-"false"}" == "false" ]; then
		packer build -only="base-ansible.docker.debian" "$packer_folder"
	else
		log i "Skipped base image build"
	fi

	packer build -only="wordpress.docker.base-ansible" "$packer_folder"
}

function full-deploy() {
	deploy-registry
	build-push-image
	deploy-ecs-cluster
}

function destroy() {
	if [ "${TF_AUTO_APPROVE:-"false"}" == "true" ]; then
		auto_approve="-auto-approve"
	fi

	log i "Destroy ecs cluster and rds"
	terraform -chdir=terraform/ecs destroy "${auto_approve:-}"

	log i "Destroy registry"
	terraform -chdir=terraform/registry destroy "${auto_approve:-}"
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
		echo "- terraform must be installed on your machine"
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
