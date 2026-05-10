
# ============================================
# Script: get-tenant-security-info.ps1
# Purpose: Gather baseline tenant security info
# Author: Uzma Shabbir
# Date: April 2026
# ============================================

# Ensure the required modules are loaded into the session
Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue
Import-Module Microsoft.Graph.Users -ErrorAction SilentlyContinue
Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction SilentlyContinue

Write-Host "Initiating connection to Microsoft Graph..." -ForegroundColor Cyan

# 1. Connect to Microsoft Graph (Using TenantId to block Gmail auto-login)
Connect-MgGraph -TenantId "XXXX-XXXX-XXXX-XXXX" -Scopes `
   "Directory.Read.All", `
   "Policy.Read.All", `
   "AuditLog.Read.All", `
   "User.Read.All", `
   "RoleManagement.Read.Directory"

Write-Host "`n✅ Connected to Microsoft Graph" -ForegroundColor Green

# 2. Get tenant information
$organization = Get-MgOrganization | Select-Object -First 1
Write-Host "`n=== TENANT INFORMATION ===" -ForegroundColor Cyan
Write-Host "Tenant Name:     $($organization.DisplayName)"
Write-Host "Tenant ID:       $($organization.Id)"
Write-Host "Country:         $($organization.CountryLetterCode)"
Write-Host "Created:         $($organization.CreatedDateTime)"

# 3. Get total users count
$allUsers = Get-MgUser -All
$totalUsers = $allUsers.Count
Write-Host "`n=== USER STATISTICS ===" -ForegroundColor Cyan
Write-Host "Total Users: $totalUsers" -ForegroundColor White

# 4. Get Global Admins
$adminRole = Get-MgDirectoryRole | Where-Object {$_.DisplayName -eq "Global Administrator"}

if ($adminRole) {
    $globalAdmins = Get-MgDirectoryRoleMember -DirectoryRoleId $adminRole.Id
    
    # Fix for counting arrays in PowerShell
    $adminCount = if ($globalAdmins -is [array]) { $globalAdmins.Count } else { 1 }
    
    Write-Host "`n=== GLOBAL ADMINISTRATORS ($adminCount) ===" -ForegroundColor Cyan
    
    foreach ($admin in $globalAdmins) {
        $user = Get-MgUser -UserId $admin.Id -ErrorAction SilentlyContinue
        if ($user) {
           Write-Host "  - $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor White
        }
    }
}

# 5. Save results to JSON file
$report = [PSCustomObject]@{
    TenantName   = $organization.DisplayName
    TenantId     = $organization.Id
    TotalUsers   = $totalUsers
    ReportDate   = Get-Date -Format "yyyy-MM-dd HH:mm"
}

$report | ConvertTo-Json | Out-File ".\tenant-baseline-report.json"

Write-Host "`n✅ Tenant baseline report saved to current folder!" -ForegroundColor Green
