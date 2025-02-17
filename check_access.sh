#!/bin/bash

# Script to check repository access and organization membership for specific GitHub users
# Usage: ./check_access.sh username1 [username2 ...]

if [ $# -eq 0 ]; then
    echo "Usage: $0 username1 [username2 ...]"
    echo "Example: $0 udi256 udi256Daniil"
    exit 1
fi

# Create output directory for reports
mkdir -p reports
REPORT_FILE="reports/access_report_$(date +%Y%m%d_%H%M%S).md"

echo "# GitHub Access Report - $(date)" > "$REPORT_FILE"
echo "## Users Checked:" >> "$REPORT_FILE"
for user in "$@"; do
    echo "- $user" >> "$REPORT_FILE"
done

# First check organization memberships
echo -e "\n## Organization Memberships\n" >> "$REPORT_FILE"

orgs=$(gh api user/memberships/orgs --jq '.[].organization.login')

for org in $orgs; do
    echo "### $org" >> "$REPORT_FILE"
    
    for user in "$@"; do
        # Check if user is a member and their role
        member_info=$(gh api "/orgs/$org/memberships/$user" --silent || echo "No membership")
        
        if [ "$member_info" != "No membership" ]; then
            role=$(echo "$member_info" | gh api --jq '.role' 2>/dev/null || echo "unknown")
            state=$(echo "$member_info" | gh api --jq '.state' 2>/dev/null || echo "unknown")
            echo "- $user: $role (Status: $state)" >> "$REPORT_FILE"
        else
            echo "- $user: No membership" >> "$REPORT_FILE"
        fi
    done
done

# Then check repository access
echo -e "\n## Repository Access Details\n" >> "$REPORT_FILE"

for org in $orgs; do
    echo "### Organization: $org" >> "$REPORT_FILE"
    echo "Checking organization: $org..."
    
    # Get repositories for organization
    repos=$(gh api "/orgs/$org/repos" --jq '.[].name')
    
    for repo in $repos; do
        echo "Checking $org/$repo..."
        echo -e "\n#### $repo" >> "$REPORT_FILE"
        
        # Check collaborators
        for user in "$@"; do
            access=$(gh api "/repos/$org/$repo/collaborators/$user" --silent || echo "No access")
            if [ "$access" != "No access" ]; then
                permission=$(gh api "/repos/$org/$repo/collaborators/$user" --jq '.permissions')
                echo "- $user: Has access ($permission)" >> "$REPORT_FILE"
            else
                echo "- $user: No access" >> "$REPORT_FILE"
            fi
        done
    done
done

echo -e "\nReport generated: $REPORT_FILE"