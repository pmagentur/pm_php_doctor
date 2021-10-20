#!/bin/bash


# how execute phpmd
EXEC='phpdoctor analyse'
CHANGED_FILES_FOR_PHPDOCTOR="${INPUT_FILES}"
PHPDOCTOR_OPTIONS=""

cp /action/phpdoctor-matcher.json /github/workflow/phpdoctor-matcher.json
echo "this directory"
pwd
ls -la
echo "prev"
pwd
ls -la
# check changed files if want to check just changes
if [ -n "${INPUT_ONLY_CHANGED_FILES}" ] && [ "${INPUT_ONLY_CHANGED_FILES}" = "true" ]; then
    echo "Will only check changed files"
    USE_CHANGED_FILES="true"
    PR="$(jq -r '.pull_request.number' < "${GITHUB_EVENT_PATH}")"
    URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${PR}/files"
    AUTH="Authorization: Bearer ${INPUT_TOKEN}"
    CURL_RESULT=$(curl --request GET --url "${URL}" --header "${AUTH}")
    CHANGED_FILES=$(echo "${CURL_RESULT}" | jq -r '.[] | select(.status != "removed") | .filename')
    # PHPMD files should be separated via comma
    CHANGED_FILES=$(echo ${CHANGED_FILES} | sed s/' '/','/g)
    # TEST
    echo "CHANGED FILES"
    echo "${CHANGED_FILES}"
else
    USE_CHANGED_FILES="false"
fi
test $? -ne 0 && echo "Could not determine changed files" && exit 1

# Check if autoload option
if [[ ! -z ${INPUT_AUTOLOAD_FILE} ]]; then
    PHPDOCTOR_OPTIONS="--autoload-file=${INPUT_AUTOLOAD_FILE}" 
    echo "COMMAND OPTIONS"
    echo "${PHPDOCTOR_OPTIONS}"
else
    PHPDOCTOR_OPTIONS=""
fi

echo "::add-matcher::${RUNNER_TEMP}/_github_workflow/phpdoctor-matcher.json"
#TODO fix if phpdoctor disabled and use_changed_files = false
# Run command 
if [ "${USE_CHANGED_FILES}" = "true" ]; then
    echo "COMMAND"
    echo " ${EXEC} ${PHPDOCTOR_OPTIONS} ${CHANGED_FILES}"
    ${EXEC} ${PHPDOCTOR_OPTIONS} ${CHANGED_FILES} 
else
    echo "COMMAND"
    echo " ${EXEC} ${PHPDOCTOR_OPTIONS} ${INPUT_FILES}"
    ${EXEC} ${PHPDOCTOR_OPTIONS} ${INPUT_FILES}
fi

# exit code of phpmd
MD_EXIT_CODE="$?"
echo "::remove-matcher owner=phpdoctor::"

# Check the exit status regarding https://phpmd.org/documentation/index.html
if [ "0" == ${MD_EXIT_CODE} ]; then
    # This exit code indicates that everything worked as expected.
    status="success"
elif [ "1" == ${MD_EXIT_CODE} ]; then
    # This exit code indicates that an exception occurred which has interrupted PHPMD during execution.
    status="failure"
elif [ "2" == ${MD_EXIT_CODE} ]; then
    # This exit code means that PHPMD has processed the code under test without the occurrence of an error/exception,
    # but it has detected rule violations in the analyzed source code. You can also prevent this behaviour with the 
    # --ignore-violations-on-exit flag, which will result to a 0 even if any violations are found
    status="failure"
elif [ "3" == ${MD_EXIT_CODE} ]; then
    # This exit code means that one or multiple files under test could not be processed because of an error. 
    # There may also be violations in other files that could be processed correctly
    status="failure"
fi

exit $MD_EXIT_CODE
#if [ "${USE_CHANGED_FILES}" = "true" ]; then
#    ${INPUT_PHPMD_BIN_PATH} ${CHANGED_FILES} ${INPUT_RENDERERS} ${INPUT_RULES}
#else
#    ${INPUT_PHPMD_BIN_PATH} ${CHANGED_FILES} ${INPUT_RENDERERS} ${INPUT_RULES}
#fi
