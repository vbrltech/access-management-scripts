#!/bin/bash

# Script to check repository access for specific GitHub users
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
echo -e "\n## Repository Access Details\n" >> "$REPORT_FILE"

# Get list of organizations
echo "Fetching organizations..."
orgs=$(gh api user/memberships/orgs --jq '.[].organization.login')

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