#!/bin/bash


# how execute phpdoctor
EXEC='phpdoctor analyse'
CHANGED_FILES_FOR_PHPDOCTOR="${INPUT_FILES}"
PHPDOCTOR_OPTIONS=""
OUTPUT_FILE="phpdoctor_output.txt"
PARSER="/action/parse_phpdoctor.py"

# check changed files if want to check just changes
if [ -n "${INPUT_ONLY_CHANGED_FILES}" ] && [ "${INPUT_ONLY_CHANGED_FILES}" = "true" ]; then
    echo "Will only check changed files"
    USE_CHANGED_FILES="true"
    PR="$(jq -r '.pull_request.number' < "${GITHUB_EVENT_PATH}")"
    URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${PR}/files"
    AUTH="Authorization: Bearer ${INPUT_TOKEN}"
    CURL_RESULT=$(curl --request GET --url "${URL}" --header "${AUTH}")
    CHANGED_FILES=$(echo "${CURL_RESULT}" | jq -r '.[] | select(.status != "removed") | .filename')
else
    USE_CHANGED_FILES="false"
fi
test $? -ne 0 && echo "Could not determine changed files" && exit 1

# Check if autoload option
if [[ ! -z ${INPUT_AUTOLOAD_FILE} ]]; then
    echo "${AUTOLOAD_PATH}"
    cp ${AUTOLOAD_PATH}/${INPUT_AUTOLOAD_FILE} ./
    PHPDOCTOR_OPTIONS="--autoload-file=${INPUT_AUTOLOAD_FILE}" 
else
    PHPDOCTOR_OPTIONS=""
fi

# Run command 
if [ "${USE_CHANGED_FILES}" = "true" ]; then
    echo "COMMAND"
    echo " ${EXEC} ${PHPDOCTOR_OPTIONS} ${CHANGED_FILES}"
    ${EXEC} ${PHPDOCTOR_OPTIONS} ${CHANGED_FILES} &> ${OUTPUT_FILE}
    # exit code of phpdoctor
    MD_EXIT_CODE="$?"
    cat ${OUTPUT_FILE}
    OWNER=${GITHUB_REPOSITORY_OWNER}
    REPO_NAME=${GITHUB_REPOSITORY#*/}
    echo "${PARSER} ${OWNER} ${REPO_NAME} ${INPUT_HEAD_SHA_ANNOTATIONS} ${OUTPUT_FILE}"
    ${PARSER} ${OWNER} ${REPO_NAME} ${INPUT_HEAD_SHA_ANNOTATIONS} ${OUTPUT_FILE}
else
    echo "COMMAND"
    echo " ${EXEC} ${PHPDOCTOR_OPTIONS} ${INPUT_FILES}"
    ${EXEC} ${PHPDOCTOR_OPTIONS} ${INPUT_FILES}
    # exit code of phpdoctor
    MD_EXIT_CODE="$?"
    OWNER=${GITHUB_REPOSITORY_OWNER}
    REPO_NAME=${GITHUB_REPOSITORY#*/}
    which python
    
    echo "${PARSER} ${OWNER} ${REPO_NAME} ${INPUT_HEAD_SHA_ANNOTATIONS} ${OUTPUT_FILE}"
    ${PARSER} ${OWNER} ${REPO_NAME} ${INPUT_HEAD_SHA_ANNOTATIONS} ${OUTPUT_FILE}
fi

exit $MD_EXIT_CODE
