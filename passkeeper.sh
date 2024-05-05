#!/bin/bash

source .env.local

PASSWORD_FILE="$PASSWORD_FILE_PATH"

if [ "$1" == "-add" ]; then
    if [ -z "$2" ]; then
        echo "Please provide a service name like: passkeeper -add <service>"
        exit 1
    fi

    # Decrypt the file and get the .json file name
    decrypt.sh "${PASSWORD_FILE}"
    JSON_FILE=$(basename "${PASSWORD_FILE}" .enc)

    SERVICE="$2"

    # Ask for the details
    read -p "Enter mail: " MAIL
    read -p "Enter username: " USERNAME
    read -sp "Enter password: " PASSWORD
    echo
    read -p "Enter site (optional): " SITE

    # Check if at least mail or username is provided
    if [ -z "$MAIL" ] && [ -z "$USERNAME" ]; then
        echo "At least mail or username must be provided."
        exit 1
    fi

    # Check if the service already exists
    if jq -e ".services[] | select(.name==\"$SERVICE\")" "${JSON_FILE}" >/dev/null 2>&1; then
        # Service exists, add new account
        NEW_ACCOUNT=$(jq -n --arg mail "$MAIL" --arg username "$USERNAME" --arg password "$PASSWORD" '{mail: $mail, username: $username, password: $password}')
        jq "(.services[] | select(.name==\"$SERVICE\").accounts) += [$NEW_ACCOUNT]" "${JSON_FILE}" > "temp.json" && mv "temp.json" "${JSON_FILE}"
    else
        # Service doesn't exist, create new service
        NEW_SERVICE=$(jq -n --arg service "$SERVICE" --arg mail "$MAIL" --arg username "$USERNAME" --arg password "$PASSWORD" --arg site "$SITE" \
            '{name: $service, accounts: [{mail: $mail, username: $username, password: $password}], site_url: $site}')
        jq ".services += [$NEW_SERVICE]" "${JSON_FILE}" > "temp.json" && mv "temp.json" "${JSON_FILE}"
    fi

    # Encrypt the .json file
    encrypt.sh "${JSON_FILE}"
#Retrieve an existing service
elif [ "$1" == "-get" ]; then
    if [ -z "$2" ]; then
        echo "Please provide a service name like: passkeeper -get <service>"
        exit 1
    fi

    SERVICE="$2"
    decrypt.sh "${PASSWORD_FILE}"
    JSON_FILE=$(basename "${PASSWORD_FILE}" .enc)

    # Check if the service exists
    if jq -e ".services[] | select(.name==\"$SERVICE\")" "${JSON_FILE}" >/dev/null 2>&1; then
        # Service exists, print the details
        jq -r ".services[] | select(.name==\"$SERVICE\") | \"\(.name) \(.site_url)\", .accounts[]" "${JSON_FILE}"
        encrypt.sh "${JSON_FILE}"
    else
        # Service doesn't exist
        echo "No service named '$SERVICE' found."
    fi
fi
