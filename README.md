# SSH4GH - GitHub SSH Key Manager

A bash command-line tool to manage GitHub SSH keys easily.

## Features

- Generate and register SSH keys with GitHub
- List local and GitHub SSH keys
- Delete SSH keys
- Automatic SSH config management
- Multiple account support

## Prerequisites

- Docker
- GitHub Personal Access Token with `admin:public_key`, `admin:ssh_signing_key`, `read:org` scope
- Python 3.6 or later

## Installation

### Using virtual environment (recommended)

```bash
#Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate
# Install the package
pip install ssh4gh
```

### Installation from GitHub

```bash
pip install git+https://github.com/heartonbit/ssh4gh.git
```

### Development Installation

```bash
# You may need to install virtualenv first and then create and activate virtual environment
pip install virtualenv
python3 -m venv venv
source venv/bin/activate
# Clone the repository
git clone https://github.com/heartonbit/ssh4gh.git
# Navigate to the repository directory
cd ssh4gh
# Install in development mode
pip install -e .
```

## Usage

```bash
# List local SSH keys
ssh4gh list

# Add new SSH key
ssh4gh add <github_token> <email> <key_name> [github_username]

# List SSH keys including GitHub keys
ssh4gh list <github_token>

# Delete SSH key
ssh4gh delete <key_name>

# Examples
ssh4gh add ghp_xxxxxxxxxxxx your@email.com github_key username
ssh4gh list ghp_xxxxxxxxxxxx
ssh4gh delete github_key

```

