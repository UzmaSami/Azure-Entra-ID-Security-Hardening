# ============================================
# Script: ca-require-mfa-admins.ps1
# Purpose: Create Conditional Access policy requiring MFA for admins
# Author: Uzma Shabbir
# ============================================

Connect-MgGraph -Scopes 'Policy.Read.All', 'Policy.ReadWrite.ConditionalAccess'

Write-Host '[STATUS] Creating CA Policy: MFA for Administrators...' -ForegroundColor Cyan

# Define all administrator role IDs (Changed actual IDs with roles)
$adminRoles = @(
    'Global Administrator',
    'Security Administrator',
    'Exchange Administrator',
    'User Administrator',
    'Helpdesk Administrator',
    'Service Support Admin',
    'SharePoint Admin',
  
)

# Create the Conditional Access policy
$params = @{
    DisplayName = 'CA001 - Require MFA for All Administrators'
    State       = 'enabledForReportingButNotEnforced'
    Conditions  = @{
        Users = @{ IncludeRoles = $adminRoles }
        Applications = @{ IncludeApplications = @('All') }
        ClientAppTypes = @('all')
    }
    GrantControls = @{
        Operator        = 'OR'
        BuiltInControls = @('mfa')
    }
}

# Create the policy
$policy = New-MgIdentityConditionalAccessPolicy -BodyParameter $params

Write-Host '[SUCCESS] CA Policy created successfully!' -ForegroundColor Green
Write-Host 'Policy ID:   ' $policy.Id -ForegroundColor Cyan
Write-Host 'Policy Name: ' $policy.DisplayName -ForegroundColor Cyan
Write-Host 'State:       ' $policy.State -ForegroundColor Yellow
Write-Host '[WARNING] Policy is in REPORT MODE - safe for testing' -ForegroundColor Yellow

# Save policy ID for reference
$logText = 'CA001 Policy ID: ' + $policy.Id
Add-Content -Path '.\ca-policy-ids.txt' -Value $logText

