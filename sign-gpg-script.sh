#!/usr/bin/env bash

# Check for at least one email argument
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <email_to_sign>..."
    exit 1
fi

# Variables
KEYSERVER="keyserver.cert.or.id"
DEFAULT_KEY="23222007@std.stei.itb.ac.id"

for EMAIL_TO_SIGN in "$@"; do
    echo "Processing $EMAIL_TO_SIGN"

    # Use expect to search for the email, select the key, sign the key, and send the key
    expect -c "
    set timeout -1
    spawn gpg --keyserver $KEYSERVER --search $EMAIL_TO_SIGN
    expect \"Keys 1-1 of 1 for\"
    send \"1\r\"
    expect eof
    " | tee /tmp/gpg_search_output_$EMAIL_TO_SIGN.txt

    # Extract key ID using grep and awk with a regex for a 16-character hexadecimal string
    KEY_ID=$(grep -oE '[A-F0-9]{16}' /tmp/gpg_search_output_$EMAIL_TO_SIGN.txt | head -n 1)

    if [ -z "$KEY_ID" ]; then
        echo "Key ID could not be found for $EMAIL_TO_SIGN."
        continue
    fi

    echo "Key ID found for $EMAIL_TO_SIGN: $KEY_ID"

    # Prompt user to sign the key manually
    echo "Please sign the key for $EMAIL_TO_SIGN manually. You may be prompted to enter your passphrase."
    # Run GPG command directly without expect, allowing GPG to interact directly with the user for passphrase input
    gpg --keyserver $KEYSERVER --default-key $DEFAULT_KEY --sign-key $KEY_ID

    echo "Sending the signed key back to the keyserver for $EMAIL_TO_SIGN..."
    gpg --keyserver $KEYSERVER --default-key $DEFAULT_KEY --send-key $KEY_ID

    echo "Process completed for $EMAIL_TO_SIGN."
done

echo "All processes completed."
