#!/bin/bash

CONFIG_FILE="msmtp.conf"
SENT_MAIL_DIR="./sent_mails"
mkdir -p "$SENT_MAIL_DIR"  # Directory to store sent emails

function welcome_screen() {
    clear
    echo "Welcome to CLI Mail Client"
    echo "1) Login"
    echo "2) Exit"
    read -p "Choose an option: " choice
    case $choice in
        1) login ;;
        2) exit 0 ;;
        *) echo "Invalid option. Try again."; welcome_screen ;;
    esac
}

function login() {
    clear
    echo "Select Email Service"
    echo "1) Google"
    echo "2) Yahoo Mail"
    echo "3) Microsoft Outlook"
    read -p "Choose an option: " email_service
    case $email_service in
        1) smtp="smtp.gmail.com" port=587 ;;
        2) smtp="smtp.mail.yahoo.com" port=587 ;;
        3) smtp="smtp.office365.com" port=587 ;;
        *) echo "Invalid option. Try again."; login ;;
    esac

    read -p "Enter Email Address: " email
    read -s -p "Enter Password: " password
    echo

    echo "account default" > "$CONFIG_FILE"
    echo "host $smtp" >> "$CONFIG_FILE"
    echo "port $port" >> "$CONFIG_FILE"
    echo "auth on" >> "$CONFIG_FILE"
    echo "user $email" >> "$CONFIG_FILE"
    echo "password $password" >> "$CONFIG_FILE"
    echo "tls on" >> "$CONFIG_FILE"
    echo "tls_starttls on" >> "$CONFIG_FILE"
    echo "from $email" >> "$CONFIG_FILE"

    chmod 600 "$CONFIG_FILE"

    echo "Successfully Logged In."
    sleep 1
    main_menu "$email"
}

function main_menu() {
    local email="$1"
    clear
    echo "Welcome $email"
    echo "1) Compose Mail"
    echo "2) Sent Mails"
    echo "3) Logout"
    echo "4) Exit"
    read -p "Choose an option: " choice
    case $choice in
        1) compose_mail "$email" ;;
        2) view_sent ;;
        3) logout ;;
        4) exit 0 ;;
        *) echo "Invalid option. Try again."; main_menu "$email" ;;
    esac
}

function compose_mail() {
    local email="$1"
    clear
    read -p "To: " receiver
    read -p "Subject: " subject
    echo "Write your email:"
    mail_body=$(cat)

    email_message="To: $receiver
From: $email
Subject: $subject

$mail_body"

    echo "$email_message" | msmtp --file="$CONFIG_FILE" "$receiver"
    if [[ $? -eq 0 ]]; then
        echo "Mail sent successfully."
        # Save to sent folder
        sent_file="$SENT_MAIL_DIR/$(date +%s).mail"
        echo "$email_message" > "$sent_file"
    else
        echo "Failed to send mail."
    fi
    read -p "Press Enter to continue..."
    main_menu "$email"
}


function view_sent() {
    clear
    local files=("$SENT_MAIL_DIR"/*)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No sent mails found."
        read -p "Press Enter to go back..."
        return
    fi

    echo "Sent Mails:"
    select file in "${files[@]}" "Go Back"; do
        if [[ "$file" == "Go Back" ]]; then
            main_menu
            return
        elif [[ -f "$file" ]]; then
            clear
            cat "$file"
            echo
            echo "1. Delete this message"
            echo "2. Go back"
            read -p "Choose an option: " action
            case $action in
                1) rm "$file"; echo "Message deleted."; read -p "Press Enter to go back..."; view_sent ;;
                2) view_sent ;;
                *) echo "Invalid option. Try again."; view_sent ;;
            esac
        else
            echo "Invalid choice. Try again."
        fi
    done
}

function logout() {
    echo "Resetting configuration..."
    echo "" > "$CONFIG_FILE"
    echo "Logged out successfully."
    sleep 1
    welcome_screen
}

welcome_screen
