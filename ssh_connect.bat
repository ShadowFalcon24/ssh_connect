#!/bin/bash

# Path to the configuration file
config_file="ssh_connections.json"

# Function to load connection data from the configuration file
load_connection_data() {
    if [[ -f "$config_file" ]]; then
        cat "$config_file" | jq -c '.[]'
    else
        echo "No configuration file found at $config_file. Creating a new one with example data."
        example_data='[
            {
                "Name": "Server1",
                "Host": "server1.example.com",
                "Port": 22,
                "Username": "your_username",
                "Password": "your_password"
            },
            {
                "Name": "Server2",
                "Host": "server2.example.com",
                "Port": 22,
                "Username": "your_username",
                "Password": "your_password"
            }
        ]'
        echo "$example_data" > "$config_file"
        echo "$example_data" | jq -c '.[]'
    fi
}

# Function to display connection menu and let user choose a connection
show_connection_menu() {
    connections=($(load_connection_data))
    echo "Available connections:"
    for i in "${!connections[@]}"; do
        name=$(echo "${connections[$i]}" | jq -r '.Name')
        echo "$((i+1)). $name"
    done
    read -p "Enter the number of the connection to connect to: " choice
    if ((choice <= 0 || choice > ${#connections[@]})); then
        echo "Invalid selection. Please choose a valid connection number."
        return 1
    fi
    selected_connection="${connections[$((choice-1))]}"
    echo "$selected_connection"
}

# Function to establish SSH connection
connect_to_ssh() {
    host=$(echo "$1" | jq -r '.Host')
    port=$(echo "$1" | jq -r '.Port')
    username=$(echo "$1" | jq -r '.Username')
    password=$(echo "$1" | jq -r '.Password')

    expect -c "
    spawn ssh -p $port $username@$host
    expect \"password:\"
    send \"$password\r\"
    interact
    "
}

# Main script
connections=$(load_connection_data)
if [[ -z "$connections" ]]; then
    echo "No connections found. Please configure connections first."
    exit 1
fi

selected_connection=$(show_connection_menu)
if [[ $? -ne 0 ]]; then
    exit 1
fi

connect_to_ssh "$selected_connection"
