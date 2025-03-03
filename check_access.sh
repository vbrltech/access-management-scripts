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
    need_manager_check=false
    
    for user in "$@"; do
        # Check if user is a member and their role
        member_info=$(gh api "/orgs/$org/memberships/$user" 2>&1 || echo "No membership")
        
        if [[ "$member_info" == *"You must be a member"* ]] || [[ "$member_info" == *"Must have admin rights"* ]]; then
            echo "- $user: ⚠️ Need manager check" >> "$REPORT_FILE"
            need_manager_check=true
        elif [[ "$member_info" == *"Not Found"* ]]; then
            echo "- $user: No membership" >> "$REPORT_FILE"
        else
            role=$(echo "$member_info" | jq -r '.role' 2>/dev/null || echo "unknown")
            state=$(echo "$member_info" | jq -r '.state' 2>/dev/null || echo "unknown")
            echo "- $user: $role (Status: $state)" >> "$REPORT_FILE"
        fi
    done

    if [ "$need_manager_check" = true ]; then
        echo "## $org Organization" >> "$NEED_MANAGER_FILE"
        echo "Please check organization membership for all users." >> "$NEED_MANAGER_FILE"
        echo "" >> "$NEED_MANAGER_FILE"
    fi
done

# Then check repository access
echo -e "\n## Repository Access Details\n" >> "$REPORT_FILE"

for org in $orgs; do
    echo "### Organization: $org" >> "$REPORT_FILE"
    echo "Checking organization: $org..."
    
    # Get repositories for organization
    repos=$(gh api "/orgs/$org/repos" --jq '.[].name')
    org_needs_check=false
    repos_needing_check=()
    
    for repo in $repos; do
        echo "Checking $org/$repo..."
        echo -e "\n#### $repo" >> "$REPORT_FILE"
        repo_needs_check=false
        
        # Check collaborators
        for user in "$@"; do
            response=$(gh api "/repos/$org/$repo/collaborators/$user" 2>&1 || echo "No access")
            if [[ "$response" == *"Must have push access"* ]]; then
                echo "- $user: ⚠️ Need manager check" >> "$REPORT_FILE"
                repo_needs_check=true
                org_needs_check=true
            elif [[ "$response" == *"Not Found"* ]]; then
                echo "- $user: No access" >> "$REPORT_FILE"
            else
                permission=$(echo "$response" | jq -r '.permissions' 2>/dev/null || echo "unknown")
                echo "- $user: Has access ($permission)" >> "$REPORT_FILE"
            fi
        done
        
        if [ "$repo_needs_check" = true ]; then
            repos_needing_check+=("$repo")
        fi
    done
    
    if [ "$org_needs_check" = true ]; then
        echo "## $org Repositories" >> "$NEED_MANAGER_FILE"
        echo "Please check the following repositories:" >> "$NEED_MANAGER_FILE"
        for repo in "${repos_needing_check[@]}"; do
            echo "- $org/$repo" >> "$NEED_MANAGER_FILE"
        done
        echo "" >> "$NEED_MANAGER_FILE"
    fi
done

# Add summary section
echo -e "\n## Summary\n" >> "$REPORT_FILE"
echo "Organizations and repositories that need manager verification are listed in: $NEED_MANAGER_FILE" >> "$REPORT_FILE"

echo -e "\nReports generated:"
echo "1. Full access report: $REPORT_FILE"
echo "2. Repositories needing manager check: $NEED_MANAGER_FILE"