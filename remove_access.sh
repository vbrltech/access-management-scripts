#!/bin/bash

# Script to remove repository access and organization membership for specific GitHub users
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

# First handle organization memberships
echo -e "\n## Organization Membership Removals\n" >> "$LOG_FILE"

orgs=$(gh api user/memberships/orgs --jq '.[].organization.login')
org_removals=0

for org in $orgs; do
    echo "### $org" >> "$LOG_FILE"
    
    for user in "$@"; do
        # Check if user is a member
        member_info=$(gh api "/orgs/$org/memberships/$user" --silent || echo "No membership")
        
        if [ "$member_info" != "No membership" ]; then
            echo "Removing $user from organization $org..."
            if gh api -X DELETE "/orgs/$org/memberships/$user" --silent; then
                echo "- ✓ Removed $user from organization" >> "$LOG_FILE"
                ((org_removals++))
            else
                echo "- ❌ Failed to remove $user from organization" >> "$LOG_FILE"
            fi
        else
            echo "- $user: No membership found" >> "$LOG_FILE"
        fi
    done
done

# Then handle repository access
echo -e "\n## Repository Access Removals\n" >> "$LOG_FILE"

repo_removals=0

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
                    ((repo_removals++))
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
echo "Organization membership removals: $org_removals" >> "$LOG_FILE"
echo "Repository access removals: $repo_removals" >> "$LOG_FILE"
echo "Total removals: $((org_removals + repo_removals))" >> "$LOG_FILE"
echo -e "\nLog file generated: $LOG_FILE"