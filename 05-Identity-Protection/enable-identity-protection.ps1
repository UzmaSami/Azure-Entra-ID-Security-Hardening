# ============================================
# Script: enable-identity-protection.ps1
# Purpose: Configure Azure AD Identity Protection risk policies
# Author: Uzma Shabbir
# Date: May 2026
# ============================================

# User.Read.All is added to ensure display names resolve correctly
Connect-MgGraph -Scopes 'Policy.Read.All', 'Policy.ReadWrite.ConditionalAccess', 'IdentityRiskyUser.ReadWrite.All', 'User.Read.All'

Write-Host '[STATUS] Fetching Identity Protection Risk Data...' -ForegroundColor Cyan

# 1. Check users currently at risk
$riskyUsers = Get-MgRiskyUser -Filter "riskState eq 'atRisk'"

# Determine status color
$statusColor = 'Green'
if ($riskyUsers.Count -gt 0) { $statusColor = 'Red' }

Write-Host ' '
Write-Host '=== CURRENT RISK STATUS ===' -ForegroundColor Cyan
Write-Host ('Users currently at risk: ' + $riskyUsers.Count) -ForegroundColor $statusColor

# 2. Detail view of at-risk users
if ($riskyUsers.Count -gt 0) {
    Write-Host ' '
    Write-Host '=== AT RISK USERS ===' -ForegroundColor Red
    foreach ($user in $riskyUsers) {
        Write-Host ('User:       ' + $user.UserDisplayName) -ForegroundColor White
        Write-Host ('Risk Level: ' + $user.RiskLevel) -ForegroundColor Red
        Write-Host ('Risk State: ' + $user.RiskState) -ForegroundColor Yellow
        Write-Host ('Updated:    ' + $user.RiskLastUpdatedDateTime) -ForegroundColor White
        Write-Host '----------------------------------------' -ForegroundColor Gray
    }
}

# 3. Get the latest risk detections (events)
$riskDetections = Get-MgRiskDetection -Top 10

Write-Host ' '
Write-Host '=== RECENT RISK DETECTIONS ===' -ForegroundColor Cyan
if ($riskDetections.Count -gt 0) {
    $riskDetections | Select-Object DetectionTimingType, RiskEventType, RiskLevel, UserDisplayName | Format-Table -AutoSize
} else {
    Write-Host '[INFO] No recent risk detections found!' -ForegroundColor Green
}

# 4. Export report to CSV
if ($riskyUsers.Count -gt 0) {
    $riskyUsers | Export-Csv -Path '.\risky-users-report.csv' -NoTypeInformation
    Write-Host '[SUCCESS] Risky users report exported to risky-users-report.csv' -ForegroundColor Green
} else {
    Write-Host '[INFO] No risky users found to export.' -ForegroundColor White
}

Write-Host ' '
Write-Host '[SUCCESS] Identity protection scan complete!' -ForegroundColor Green

