#!/bin/sh

#Publish Docker Container To GitHub Package Registry
####################################################

# exit when any command fails
set -e

#check inputs
if [[ -z "$GITHUB_TOKEN" ]]; then
	echo "You must supply the environment variable GITHUB_TOKEN."
	exit 1
fi

if [[ -z "$INPUT_IMAGE_NAME" ]]; then
	echo "Set the IMAGE_NAME input."
	exit 1
fi

if [[ -z "$INPUT_DOCKERFILE_PATH" ]]; then
	echo "Set the DOCKERFILE_PATH input."
	exit 1
fi

if [[ -z "$INPUT_BUILD_CONTEXT" ]]; then
	echo "Set the BUILD_CONTEXT input."
	exit 1
fi


# The following environment variables will be provided by the environment automatically: GITHUB_REPOSITORY, GITHUB_SHA

# send credentials through stdin (it is more secure)
user=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/user | jq -r .login)
# lowercase the username
username="$(echo ${user} | tr "[:upper:]" "[:lower:]")"
echo ${GITHUB_TOKEN} | docker login docker.pkg.github.com -u "${username}" --password-stdin 

# Set Local Variables, lowering case to make it work
tag="$(echo ${GITHUB_REPOSITORY} | tr "[:upper:]" "[:lower:]")"
BASE_NAME="docker.pkg.github.com/${tag}/${INPUT_IMAGE_NAME}"

DOCKER_TAG="${BASE_NAME}:latest"
if [ "${INPUT_TAG}" ]; then DOCKER_TAG="${BASE_NAME}:${INPUT_TAG}"; fi

# Build The Container
docker build $BUILDPARAMS -t ${DOCKER_TAG} -f ${INPUT_DOCKERFILE_PATH} --rm --no-cache --squash ${INPUT_BUILD_CONTEXT}
docker push ${DOCKER_TAG}

echo "::set-output name=IMAGE_NAME::${DOCKER_TAG}"
echo "::set-output name=IMAGE_URL::https://github.com/${GITHUB_REPOSITORY}/packages"
