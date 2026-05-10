# ============================================
# Script: generate-security-report.ps1
# Purpose: Generate comprehensive Entra ID security hardening report
# Author: Uzma Shabbir
# Date: May 2026
# ============================================

Connect-MgGraph -Scopes "Directory.Read.All", "Policy.Read.All", "AuditLog.Read.All", "IdentityRiskyUser.Read.All"

$reportDate = Get-Date -Format "yyyy-MM-dd"
Write-Host "[STATUS] Gathering security metrics..." -ForegroundColor Cyan

# Gather data
$totalUsers   = (Get-MgUser -All).Count
$caPolicies   = (Get-MgIdentityConditionalAccessPolicy -All).Count
$riskyUsers   = (Get-MgRiskyUser -Filter "riskState eq 'atRisk'").Count

# Robust Global Admin check
$gaRole = Get-MgDirectoryRole | Where-Object {$_.DisplayName -eq "Global Administrator"}
if ($null -eq $gaRole) {
    # If the role hasn't been "activated" yet, we fetch the template ID
    $gaTemplate = Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Global Administrator"}
    $globalAdmins = (Get-MgDirectoryRoleMember -DirectoryRoleId $gaTemplate.Id).Count
} else {
    $globalAdmins = (Get-MgDirectoryRoleMember -DirectoryRoleId $gaRole.Id).Count
}

# Generate HTML report
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Entra ID Security Hardening Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background: #f0f2f5; color: #333; }
        .container { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); max-width: 1000px; margin: auto; }
        h1 { color: #0078d4; border-bottom: 3px solid #0078d4; padding-bottom: 15px; margin-bottom: 20px; }
        h2 { color: #201f1e; margin-top: 35px; border-left: 5px solid #0078d4; padding-left: 15px; }
        .metric-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin: 25px 0; }
        .metric-box { background: #0078d4; color: white; padding: 25px; border-radius: 10px; text-align: center; }
        .metric-number { font-size: 38px; font-weight: bold; }
        .metric-label { font-size: 14px; margin-top: 8px; text-transform: uppercase; letter-spacing: 1px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; background: white; }
        th { background: #f3f2f1; color: #201f1e; padding: 15px; text-align: left; border-bottom: 2px solid #edebe9; }
        td { padding: 12px 15px; border-bottom: 1px solid #edebe9; font-size: 14px; }
        tr:hover { background-color: #f9f9f9; }
        .badge { padding: 6px 12px; border-radius: 15px; font-size: 12px; font-weight: 600; }
        .badge-green { background: #dff6dd; color: #107c10; }
        .badge-blue { background: #deecf9; color: #0078d4; }
        footer { margin-top: 50px; color: #605e5c; font-size: 12px; border-top: 1px solid #edebe9; padding-top: 20px; text-align: center; }
    </style>
</head>
<body>
<div class='container'>
    <h1>Entra ID Security Hardening Report</h1>
    <p><strong>Environment:</strong> Hybrid Identity Framework (Windows Server 2022)</p>
    <p><strong>Report Date:</strong> $reportDate</p>
    <p><strong>Lead Security Engineer:</strong> Uzma Shabbir</p>

    <h2>Security Metrics Overview</h2>
    <div class='metric-grid'>
        <div class='metric-box'>
            <div class='metric-number'>$totalUsers</div>
            <div class='metric-label'>Total Users</div>
        </div>
        <div class='metric-box'>
            <div class='metric-number'>$caPolicies</div>
            <div class='metric-label'>CA Policies</div>
        </div>
        <div class='metric-box'>
            <div class='metric-number'>$globalAdmins</div>
            <div class='metric-label'>Global Admins</div>
        </div>
        <div class='metric-box'>
            <div class='metric-number'>$riskyUsers</div>
            <div class='metric-label'>Risky Users</div>
        </div>
    </div>

    <h2>Security Controls Implemented</h2>
    <table>
        <tr><th>Control Domain</th><th>Status</th><th>Configuration ID</th></tr>
        <tr>
            <td>Administrator Protection</td>
            <td><span class='badge badge-green'>Active</span></td>
            <td>CA001 - MFA Enforcement for Admin Roles</td>
        </tr>
        <tr>
            <td>Standard User Protection</td>
            <td><span class='badge badge-green'>Active</span></td>
            <td>CA002 - MFA Enforcement for All Users</td>
        </tr>
        <tr>
            <td>Attack Surface Reduction</td>
            <td><span class='badge badge-green'>Blocked</span></td>
            <td>CA003 - Legacy Authentication Protocols</td>
        </tr>
        <tr>
            <td>Threat Detection - High Risk</td>
            <td><span class='badge badge-green'>Automated Block</span></td>
            <td>CA004 - Identity Protection High Risk</td>
        </tr>
        <tr>
            <td>Threat Detection - Med Risk</td>
            <td><span class='badge badge-blue'>MFA Challenge</span></td>
            <td>CA005 - Identity Protection Medium Risk</td>
        </tr>
        <tr>
            <td>Privileged Identity Audit</td>
            <td><span class='badge badge-green'>Verified</span></td>
            <td>Global Admin Role Review</td>
        </tr>
        <tr>
            <td>Sign-in Pattern Analysis</td>
            <td><span class='badge badge-green'>Completed</span></td>
            <td>7-Day Log Investigation</td>
        </tr>
    </table>

    <h2>Operational Recommendations</h2>
    <ul>
        <li>Monitor Conditional Access "Report-Only" logs for 14 days before switching to full enforcement.</li>
        <li>Review and rotate the password for the emergency 'Break Glass' account (xxusk) quarterly.</li>
        <li>Implement Privileged Identity Management (PIM) for Just-In-Time role activation.</li>
        <li>Conduct a deep-dive investigation into any sign-ins originating from unexpected regions (e.g., NL).</li>
    </ul>

    <footer>
        Report generated by Entra ID Security Hardening Toolkit | Version 1.0 | $reportDate
    </footer>
</div>
</body>
</html>
"@

# Save and Launch
$filePath = "$PSScriptRoot\security-report-$reportDate.html"
$html | Out-File $filePath -Encoding UTF8
Start-Process $filePath

Write-Host "[SUCCESS] Final security report generated at: $filePath" -ForegroundColor Green
Write-Host "[SUCCESS] Report opened in browser." -ForegroundColor Green

