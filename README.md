# GitHub Access Management Scripts

This repository contains scripts for managing GitHub repository access across organizations. These scripts help administrators check and remove access for specific users across multiple repositories and organizations.

## Scripts

### 1. check_access.sh
Checks repository access for specified GitHub users across all organizations you have access to.

```bash
# Make executable
chmod +x check_access.sh

# Usage
./check_access.sh username1 [username2 ...]

# Example
./check_access.sh udi256 udi256Daniil
```

The script will:
- Generate a detailed report in the `reports` directory
- Show which repositories each user has access to
- Include permission levels for each access found

### 2. remove_access.sh
Removes repository access for specified GitHub users across all organizations you have access to.

```bash
# Make executable
chmod +x remove_access.sh

# Usage
./remove_access.sh username1 [username2 ...]

# Example
./remove_access.sh udi256 udi256Daniil
```

The script will:
- Remove access for specified users from all repositories where they have access
- Generate a detailed log in the `logs` directory
- Show successful and failed removal attempts
- Provide a summary of total access removals

## Prerequisites

1. GitHub CLI (`gh`) must be installed and authenticated
2. You must have appropriate permissions in the organizations to view and modify repository access

## Output Files

- Reports are saved in the `reports` directory with timestamp
- Removal logs are saved in the `logs` directory with timestamp

## Security Note

Please ensure you have proper authorization before removing anyone's access. It's recommended to run `check_access.sh` first to review current access before running `remove_access.sh`.