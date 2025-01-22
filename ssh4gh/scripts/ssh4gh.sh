#!/bin/bash

# Script version
VERSION="1.0.0"

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is required but not installed. Please install Docker first."
    exit 1
fi

# Function to check and create .ssh directory with proper permissions
setup_ssh_dir() {
    local ssh_dir="$HOME/.ssh"
    local config_file="$ssh_dir/config"
    
    # Create .ssh directory if it doesn't exist
    if [ ! -d "$ssh_dir" ]; then
        echo "Creating .ssh directory..."
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
    fi

    # Create config file if it doesn't exist
    if [ ! -f "$config_file" ]; then
        echo "Creating SSH config file..."
        touch "$config_file"
        chmod 600 "$config_file"
    elif [ "$(stat -c %a $config_file)" != "600" ]; then
        echo "Fixing SSH config file permissions..."
        chmod 600 "$config_file"
    fi
}

# Help function
show_help() {
    echo "GitHub SSH Key Setup Script v${VERSION}"
    echo "-------------------------"
    echo "Usage: $(basename $0) [options] <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  add <token> <email> <key_name> [github_username]  Add new SSH key"
    echo "  list [github_token]                              List all SSH keys"
    echo "  delete <key_name>                                Delete SSH key"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --version  Show version"
    echo ""
    echo "Examples:"
    echo "  $(basename $0) add ghp_xxxxxxxxxxxx your@email.com github_key username"
    echo "  $(basename $0) list"
    echo "  $(basename $0) delete github_key"
    echo ""
    echo "After setup, you can clone repositories using:"
    echo "  git clone git@github.com-username:username/reponame"
}

# Version function
show_version() {
    echo "v${VERSION}"
}

# List SSH keys function
list_keys() {
    local GITHUB_ACCESS_TOKEN=$1
    echo "Configured SSH keys:"
    echo "------------------"
    
    # List local SSH keys
    echo "Local SSH keys:"
    if [ -d "$HOME/.ssh" ]; then
        for key in "$HOME/.ssh"/*.pub; do
            if [ -f "$key" ]; then
                key_name=$(basename "$key" .pub)
                echo "Key: $key_name"
                echo "  Public key: $key"
                echo "  Private key: ${key%.pub}"
                
                # Find host entry in config
                if [ -f "$HOME/.ssh/config" ]; then
                    host_entry=$(grep -B1 "IdentityFile.*$key_name\$" "$HOME/.ssh/config" | grep "Host" | cut -d' ' -f2)
                    if [ ! -z "$host_entry" ]; then
                        echo "  Host entry: $host_entry"
                    fi
                fi
                echo ""
            fi
        done
    else
        echo "  No SSH directory found."
    fi
    
    # List GitHub SSH keys
    echo ""
    echo "GitHub SSH keys:"
    if [ ! -z "${GITHUB_ACCESS_TOKEN}" ]; then
        echo "${GITHUB_ACCESS_TOKEN}" | docker run -i --rm \
            -v "$HOME/.ssh:/root/.ssh" -w /gh \
            heartonbit/gh:latest sh -c " \
                gh auth login --with-token && \
                gh ssh-key list \
            "
    else
        echo "  No GitHub token provided. To list GitHub SSH keys, run: $(basename $0) list <GITHUB_ACCESS_TOKEN>"
    fi
}

# Delete SSH key function
delete_key() {
    local key_name=$1
    if [ -z "$key_name" ]; then
        echo "Error: Key name is required"
        return 1
    fi

    local private_key="$HOME/.ssh/$key_name"
    local public_key="$HOME/.ssh/$key_name.pub"
    local config_file="$HOME/.ssh/config"

    # Remove from ssh-agent
    ssh-add -d "$private_key" 2>/dev/null

    # Remove keys
    if [ -f "$private_key" ]; then
        rm "$private_key"
        echo "Deleted private key: $private_key"
    fi
    if [ -f "$public_key" ]; then
        rm "$public_key"
        echo "Deleted public key: $public_key"
    fi

    # Remove from SSH config
    if [ -f "$config_file" ]; then
        # Create temporary file
        temp_file=$(mktemp)
        # Remove Host block containing the key
        awk -v key="$key_name" '
            /^Host/ { 
                if (p) { print buf }
                buf = $0 ORS
                p = 1
                next
            }
            /IdentityFile.*'$key_name'$/ {
                buf = ""
                p = 0
                next
            }
            { 
                if (p) { buf = buf $0 ORS }
                else { print }
            }
            END { if (p) { print buf } }
        ' "$config_file" > "$temp_file"
        mv "$temp_file" "$config_file"
        echo "Removed key from SSH config"
    fi

    echo "SSH key '$key_name' has been deleted"
}

# Update SSH config
update_ssh_config() {
    local key_name=$1
    local github_username=$2
    local ssh_dir="$HOME/.ssh"
    local config_file="$ssh_dir/config"
    local host_entry="github.com-${github_username:-personal}"
    
    # Ensure proper directory and file permissions
    setup_ssh_dir

    # Check if host entry already exists
    if ! grep -q "^Host $host_entry$" "$config_file"; then
        {
            echo ""
            echo "Host $host_entry"
            echo "  HostName github.com"
            echo "  IdentityFile ~/.ssh/${key_name}"
            if [ ! -z "$github_username" ]; then
                echo "  User $github_username"
            fi
        } >> "$config_file"
    fi
}

# Parse command line options
while [[ "$1" =~ ^- ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

# Parse commands
command=$1
case $command in
    add)
        shift
        if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
            show_help
            exit 1
        fi
        GITHUB_ACCESS_TOKEN=$1
        EMAIL=$2
        KEY_NAME=$3
        GITHUB_USERNAME=$4

        # Check if key already exists
        if [ -f ~/.ssh/${KEY_NAME} ]; then
            echo "Error: SSH key '~/.ssh/${KEY_NAME}' already exists"
            exit 1
        fi

        # generate ssh key
        echo "Generating SSH key..."
        ssh-keygen -t ed25519 -C "${EMAIL}" -q -N "" -f ~/.ssh/${KEY_NAME}
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/${KEY_NAME}

        # add ssh key to github 
        echo "Adding SSH key to GitHub..."
        echo "${GITHUB_ACCESS_TOKEN}" | docker run -i --rm \
            -v "$HOME/.ssh:/root/.ssh" -w /gh \
            heartonbit/gh:latest sh -c " \
                gh auth login --with-token && \
                cat /root/.ssh/${KEY_NAME}.pub | gh ssh-key add -t $(hostname) \
            "

        # Update SSH config
        echo "Updating SSH config..."
        update_ssh_config "$KEY_NAME" "$GITHUB_USERNAME"

        echo "SSH key has been successfully generated and registered with GitHub!"
        echo "Private key location: ~/.ssh/${KEY_NAME}"
        echo "Public key location: ~/.ssh/${KEY_NAME}.pub"
        echo ""
        echo "SSH config has been updated. You can now clone repositories using:"
        if [ ! -z "$GITHUB_USERNAME" ]; then
            echo "  git clone git@github.com-${GITHUB_USERNAME}:${GITHUB_USERNAME}/reponame"
        else
            echo "  git clone git@github.com-personal:username/reponame"
        fi
        ;;
    list)
        shift
        list_keys "$1"
        ;;
    delete)
        shift
        delete_key "$1"
        ;;
    *)
        echo "Unknown command: $command"
        show_help
        exit 1
        ;;
esac
