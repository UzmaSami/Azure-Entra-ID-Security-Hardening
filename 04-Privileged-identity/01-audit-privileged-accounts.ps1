# ============================================
# Script: audit-privileged-accounts.ps1
# Purpose: Identify and audit all privileged accounts and their assignments
# Author: Uzma Shabbir
# Date: May 2026
# ============================================

Connect-MgGraph -Scopes 'Directory.Read.All', 'RoleManagement.Read.Directory', 'User.Read.All'

Write-Host '[STATUS] Auditing privileged accounts...' -ForegroundColor Cyan

# 1. Get all active directory roles
$allRoles = Get-MgDirectoryRole

$privilegedReport = @()

foreach ($role in $allRoles) {
    # 2. Get members of each role
    $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id

    foreach ($member in $members) {
        # 3. Get user details (stripping unnecessary properties for speed)
        $user = Get-MgUser -UserId $member.Id -Property 'Id,DisplayName,UserPrincipalName,AccountEnabled' -ErrorAction SilentlyContinue

        if ($user) {
            # 4. Determine Risk Level without emojis
            $riskLevel = switch ($role.DisplayName) {
                'Global Administrator'     {'CRITICAL'}
                'Security Administrator'   {'HIGH'}
                'Exchange Administrator'   {'MEDIUM'}
                'SharePoint Administrator' {'MEDIUM'}
                default                    {'STANDARD'}
            }

            $privilegedReport += [PSCustomObject]@{
                RoleName          = $role.DisplayName
                UserName          = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                AccountEnabled    = $user.AccountEnabled
                RiskLevel         = $riskLevel
            }
        }
    }
}

# 5. Display results table
Write-Host ' '
Write-Host '=== PRIVILEGED ACCOUNT AUDIT ===' -ForegroundColor Cyan
$privilegedReport | Sort-Object RiskLevel | Format-Table -AutoSize

# 6. Summary by role
Write-Host ' '
Write-Host '=== SUMMARY BY ROLE ===' -ForegroundColor Cyan
$privilegedReport | Group-Object RoleName | Select-Object @{Name='Role';Expression={$_.Name}}, Count | Sort-Object Count -Descending | Format-Table -AutoSize

# 7. Security recommendations (Logic-based)
Write-Host ' '
Write-Host '=== SECURITY RECOMMENDATIONS ===' -ForegroundColor Yellow
$gaCount = ($privilegedReport | Where-Object { $_.RoleName -eq 'Global Administrator' }).Count

if ($gaCount -gt 3) {
    Write-Host "[WARNING] $gaCount Global Admins found! This is too many." -ForegroundColor Red
    Write-Host 'Recommendation: Reduce to maximum 2-3 emergency Global Admins.' -ForegroundColor Yellow
} else {
    Write-Host "[OK] Global Admin count is healthy: $gaCount" -ForegroundColor Green
}

# 8. Export report to CSV
$privilegedReport | Export-Csv -Path '.\privileged-accounts-audit.csv' -NoTypeInformation

Write-Host ' '
Write-Host '[SUCCESS] Privileged account audit exported to privileged-accounts-audit.csv' -ForegroundColor Green

