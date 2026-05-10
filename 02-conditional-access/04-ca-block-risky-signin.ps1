# ============================================
# Script: ca-block-risky-signin.ps1
# Purpose: Block or require MFA for risky sign-in attempts
# Author: Uzma Shabbir
# Date: May 2026
# ============================================

Connect-MgGraph -Scopes 'Policy.Read.All', 'Policy.ReadWrite.ConditionalAccess', 'User.Read.All'

Write-Host '[STATUS] Creating Risk-Based CA Policies...' -ForegroundColor Cyan

# 1. Look up your Break Glass account UPN to exclude
$breakGlassUpn = 'xxusk@nazshkhanxxxgmail.onmicrosoft.com'
$breakGlassUser = Get-MgUser -UserId $breakGlassUpn -ErrorAction SilentlyContinue

if ($breakGlassUser) {
    $excludedUsers = @($breakGlassUser.Id)
    Write-Host '[SUCCESS] Break glass account found and excluded.' -ForegroundColor Green
} else {
    Write-Host '[ERROR] Break glass account not found! Aborting.' -ForegroundColor Red
    exit
}

# 2. Policy: Block HIGH risk sign-ins
$blockHighRisk = @{
    DisplayName = 'CA004 - Block High Risk Sign-ins'
    State       = 'enabledForReportingButNotEnforced'
    Conditions  = @{
        Users = @{
            IncludeUsers = @('All')
            ExcludeUsers = $excludedUsers
        }
        Applications = @{ IncludeApplications = @('All') }
        SignInRiskLevels = @('high')
    }
    GrantControls = @{
        Operator        = 'OR'
        BuiltInControls = @('block')
    }
}

$policy1 = New-MgIdentityConditionalAccessPolicy -BodyParameter $blockHighRisk
Write-Host '[SUCCESS] High Risk Sign-in Block policy created!' -ForegroundColor Green

# 3. Policy: Require MFA for MEDIUM risk sign-ins
$mfaMediumRisk = @{
    DisplayName = 'CA005 - Require MFA for Medium Risk Sign-ins'
    State       = 'enabledForReportingButNotEnforced'
    Conditions  = @{
        Users = @{
            IncludeUsers = @('All')
            ExcludeUsers = $excludedUsers
        }
        Applications = @{ IncludeApplications = @('All') }
        SignInRiskLevels = @('medium')
    }
    GrantControls = @{
        Operator        = 'OR'
        BuiltInControls = @('mfa')
    }
}

$policy2 = New-MgIdentityConditionalAccessPolicy -BodyParameter $mfaMediumRisk
Write-Host '[SUCCESS] Medium Risk MFA policy created!' -ForegroundColor Green

# 4. Final summary report
Write-Host '[INFO] Fetching all current CA Policies...' -ForegroundColor Cyan
Get-MgIdentityConditionalAccessPolicy | Select-Object DisplayName, State | Format-Table -AutoSize

# Save IDs for reference
$logText = 'CA004 ID: ' + $policy1.Id + ' | CA005 ID: ' + $policy2.Id
Add-Content -Path '.\ca-policy-ids.txt' -Value $logText

