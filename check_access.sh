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
NEED_MANAGER_FILE="reports/need_manager_check_$(date +%Y%m%d_%H%M%S).md"

echo "# GitHub Access Report - $(date)" > "$REPORT_FILE"
echo "## Users Checked:" >> "$REPORT_FILE"
for user in "$@"; do
    echo "- $user" >> "$REPORT_FILE"
done

echo "# Repositories Needing Manager Check - $(date)" > "$NEED_MANAGER_FILE"
echo "The following repositories/organizations need manager access to verify:" >> "$NEED_MANAGER_FILE"
echo "" >> "$NEED_MANAGER_FILE"

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
    
    need_manager_check=false
    for repo in $repos; do
        echo "Checking $org/$repo..."
        echo -e "\n#### $repo" >> "$REPORT_FILE"
        
        # Check collaborators
        for user in "$@"; do
            response=$(gh api "/repos/$org/$repo/collaborators/$user" --silent || echo "No access")
            if [ "$response" == "No access" ]; then
                echo "- $user: No access" >> "$REPORT_FILE"
            elif [[ "$response" == *"Must have push access to view repository collaborators"* ]]; then
                echo "- $user: ⚠️ Need manager check" >> "$REPORT_FILE"
                need_manager_check=true
            else
                permission=$(echo "$response" | gh api --jq '.permissions' 2>/dev/null || echo "unknown")
                echo "- $user: Has access ($permission)" >> "$REPORT_FILE"
            fi
        done
    done
    
    if [ "$need_manager_check" = true ]; then
        echo "## $org" >> "$NEED_MANAGER_FILE"
        echo "Please check all repositories in this organization." >> "$NEED_MANAGER_FILE"
        echo "" >> "$NEED_MANAGER_FILE"
    fi
done

echo -e "\nReports generated:"
echo "1. Full access report: $REPORT_FILE"
echo "2. Repositories needing manager check: $NEED_MANAGER_FILE"