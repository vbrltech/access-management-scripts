# GitHub Access Management Scripts

This repository contains scripts for managing GitHub repository access and organization memberships. These scripts help administrators check and remove access for specific users across multiple repositories and organizations.

## Scripts

### 1. check_access.sh
Checks both organization memberships and repository access for specified GitHub users across all organizations you have access to.

```bash
# Make executable
chmod +x check_access.sh

# Usage
./check_access.sh username1 [username2 ...]

# Example
./check_access.sh udi256 udi256Daniil
```

The script will generate two reports:
1. Full access report (`reports/access_report_*.md`):
   - Organization memberships and roles
   - Repository access permissions
   - Complete access status for each user

2. Manager check report (`reports/need_manager_check_*.md`):
   - List of repositories/organizations that need manager access to verify
   - Cases where current user lacks permission to check access

### 2. remove_access.sh
Removes both organization memberships and repository access for specified GitHub users across all organizations you have access to.

```bash
# Make executable
chmod +x remove_access.sh

# Usage
./remove_access.sh username1 [username2 ...]

# Example
./remove_access.sh udi256 udi256Daniil
```

The script will generate two reports:
1. Removal log (`logs/removal_log_*.md`):
   - Detailed log of all removal actions
   - Success/failure status for each action
   - Summary of total removals

2. Manager actions needed (`logs/need_manager_removal_*.md`):
   - List of removals that need manager access
   - Organizations and repositories requiring elevated permissions
   - Clear instructions for managers

## Prerequisites

1. GitHub CLI (`gh`) must be installed and authenticated
2. You must have appropriate permissions in the organizations to:
   - View and modify organization memberships
   - View and modify repository access
3. For repositories/organizations where you lack permission, a manager will need to perform the actions

## Output Files

### Reports Directory
- Access check reports with timestamp
- List of repositories needing manager verification

### Logs Directory
- Removal action logs with timestamp
- List of removals needing manager action

## Security Note

Please ensure you have proper authorization before removing anyone's access. Recommended workflow:
1. Run `check_access.sh` first to review current access
2. Review the generated reports carefully
3. Get necessary approvals before running `remove_access.sh`
4. Forward the manager action report to appropriate personnel
5. Keep all logs for audit purposes