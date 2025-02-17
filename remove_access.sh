#!/bin/bash

# Script to remove repository access for specific GitHub users
# Usage: ./remove_access.sh username1 [username2 ...]

if [ $# -eq 0 ]; then
    echo "Usage: $0 username1 [username2 ...]"
    echo "Example: $0 udi256 udi256Daniil"
    exit 1
fi

# Create output directory for logs
mkdir -p logs
LOG_FILE="logs/removal_log_$(date +%Y%m%d_%H%M%S).md"

echo "# GitHub Access Removal Log - $(date)" > "$LOG_FILE"
echo "## Users Processed:" >> "$LOG_FILE"
for user in "$@"; do
    echo "- $user" >> "$LOG_FILE"
done
echo -e "\n## Removal Actions\n" >> "$LOG_FILE"

# Get list of organizations
echo "Fetching organizations..."
orgs=$(gh api user/memberships/orgs --jq '.[].organization.login')

# Counter for removed access
total_removed=0

for org in $orgs; do
    echo "### Organization: $org" >> "$LOG_FILE"
    echo "Processing organization: $org..."
    
    # Get repositories for organization
    repos=$(gh api "/orgs/$org/repos" --jq '.[].name')
    
    for repo in $repos; do
        echo "Checking $org/$repo..."
        echo -e "\n#### $repo" >> "$LOG_FILE"
        
        # Check and remove collaborators
        for user in "$@"; do
            access=$(gh api "/repos/$org/$repo/collaborators/$user" --silent || echo "No access")
            if [ "$access" != "No access" ]; then
                echo "Removing $user from $org/$repo..."
                if gh api -X DELETE "/repos/$org/$repo/collaborators/$user" --silent; then
                    echo "- ✓ Removed $user" >> "$LOG_FILE"
                    ((total_removed++))
                else
                    echo "- ❌ Failed to remove $user" >> "$LOG_FILE"
                fi
            else
                echo "- $user: No access found" >> "$LOG_FILE"
            fi
        done
    done
done

echo -e "\n## Summary" >> "$LOG_FILE"
echo "Total access removals: $total_removed" >> "$LOG_FILE"
echo -e "\nLog file generated: $LOG_FILE"