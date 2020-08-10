#!/usr/bin/env bash
set -euo pipefail

if [[ "${OSTYPE}" != "darwin"* ]]; then
    echo "Host OS must be OS X"
fi

# Subroutines

function read_environment {

    local SECRET_ENV_VARS_PATH="${PROJECT_DIR}/env.sh"

    #check if env-vars.sh exists
    if [ -f "${SECRET_ENV_VARS_PATH}" ]; then
        source "${SECRET_ENV_VARS_PATH}"
    fi

}

function gen_urlscheme {

    # copy the secret to the appcenter distribute url scheme entry
    echo  "[WS] Generate UrlScheme Info.plist entry"

    /usr/libexec/PlistBuddy -c "Set :CFBundleURLTypes:0:CFBundleURLSchemes:0 appcenter-${MSAPPCENTER_SECRET}" "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"
}

function gen_apikeys {

    echo  "[WS] Generate ApiKeys Plist File"

    local API_KEYS_PLIST_NAME="ApiKeys.plist"
    local API_KEYS_PLIST_PATH="${BUILT_PRODUCTS_DIR}/${API_KEYS_PLIST_NAME}"
    local MS_PLIST_KEY=":MSAppCenterSecretKey"

    # check plist to avoid unneeded work during builds

    if [ -f "${API_KEYS_PLIST_PATH}" ]; then
        REQUIRED_VALUE=$(/usr/libexec/PlistBuddy -c "Print ${MS_PLIST_KEY}" "${API_KEYS_PLIST_PATH}")
        if [ "${REQUIRED_VALUE}" != "${MSAPPCENTER_SECRET}" ]; then
            /usr/libexec/PlistBuddy -c "Set ${MS_PLIST_KEY} ${MSAPPCENTER_SECRET}" "${API_KEYS_PLIST_PATH}"
        fi
    else
        /usr/libexec/PlistBuddy -c "Add ${MS_PLIST_KEY} string ${MSAPPCENTER_SECRET}" "${API_KEYS_PLIST_PATH}"
    fi

    # copy to .app bundle resources

    cp "${API_KEYS_PLIST_PATH}" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/${API_KEYS_PLIST_NAME}"

}


########
# Main #
########

read_environment

case $1 in

        --urlscheme )   gen_urlscheme
                        ;;

        --apikeys )     gen_apikeys
                        ;;

esac
