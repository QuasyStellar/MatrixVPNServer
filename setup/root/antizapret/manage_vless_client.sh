#!/bin/bash
#
# VLESS client management script
#
set -e

CLIENTS_DIR="/usr/local/etc/xray/clients"
CONFIG_FILE="/usr/local/etc/xray/config.json"
KEYS_FILE="/usr/local/etc/xray/keys"
TEMPLATE_FILE="/root/antizapret/config.json.template"
SERVER_IP=$(curl -s ifconfig.me)

# Function to update Xray config from template
update_xray_config() {
    # Build client JSON arrays
    CLIENTS_ANTIZAPRET=""
    CLIENTS_GLOBAL=""
    
    for client_file in "$CLIENTS_DIR"/*.uuid; do
        if [[ -f "$client_file" ]]; then
            client_name=$(basename "$client_file" .uuid)
            uuid=$(cat "$client_file")
            
            # Create JSON object for the client
            client_json="{\"id\": \"$uuid\", \"flow\": \"xtls-rprx-vision\"}"

            # Add to the correct list based on name
            if [[ "$client_name" == *"-global" ]]; then
                if [ -z "$CLIENTS_GLOBAL" ]; then
                    CLIENTS_GLOBAL="$client_json"
                else
                    CLIENTS_GLOBAL="$CLIENTS_GLOBAL, $client_json"
                fi
            else
                if [ -z "$CLIENTS_ANTIZAPRET" ]; then
                    CLIENTS_ANTIZAPRET="$client_json"
                else
                    CLIENTS_ANTIZAPRET="$CLIENTS_ANTIZAPRET, $client_json"
                fi
            fi
        fi
    done

    source "$KEYS_FILE"

    # Read template and replace placeholders
    CONFIG=$(cat "$TEMPLATE_FILE")
    CONFIG=${CONFIG//'"__CLIENTS_ANTIZAPRET__"'/[$CLIENTS_ANTIZAPRET]}
    CONFIG=${CONFIG//'"__CLIENTS_GLOBAL__"'/[$CLIENTS_GLOBAL]}
    CONFIG=${CONFIG//'${PRIVATE_KEY}'/$PRIVATE_KEY}
    
    # Write the new config
    echo "$CONFIG" > "$CONFIG_FILE"

    # Restart Xray to apply changes
    systemctl restart xray
}

add_client() {
    client_name=$1
    is_global=false
    if [ "$2" == "--global" ]; then
        is_global=true
        client_name="${client_name}-global"
    fi
    
    if [ -f "$CLIENTS_DIR/$client_name.uuid" ]; then
        echo "Client '$client_name' already exists."
        exit 1
    fi
    
    uuid=$(xray uuid)
    echo "$uuid" > "$CLIENTS_DIR/$client_name.uuid"
    echo "Client '$client_name' added with UUID: $uuid"
    
    update_xray_config
    
    source "$KEYS_FILE"
    
    if [ "$is_global" = true ]; then
        link="vless://$uuid@$SERVER_IP:8443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC_KEY&sid=0123456789abcdef&type=tcp&headerType=none#$client_name"
        echo -e "\nGlobal VLESS link:\n$link"
    else
        link="vless://$uuid@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC_KEY&sid=0123456789abcdef&type=tcp&headerType=none#$client_name"
        echo -e "\nAntizapret VLESS link:\n$link"
    fi
}

delete_client() {
    client_name=$1
    
    if [ ! -f "$CLIENTS_DIR/$client_name.uuid" ]; then
        echo "Client '$client_name' not found."
        exit 1
    fi
    
    rm "$CLIENTS_DIR/$client_name.uuid"
    echo "Client '$client_name' deleted."
    
    update_xray_config
}

list_clients() {
    echo "VLESS clients:"
    ls -1 "$CLIENTS_DIR" | sed 's/\.uuid$//'
}

case "$1" in
    add)
        add_client "$2" "$3"
        ;;
    delete)
        delete_client "$2"
        ;;
    list)
        list_clients
        ;;
    *)
        echo "Usage: $0 {add|delete|list} [client_name] [--global]"
        exit 1
esac
