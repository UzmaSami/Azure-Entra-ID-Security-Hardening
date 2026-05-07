# ============================================
# Script: setup-entra-hardening.ps1
# Purpose: Install modern modules for Entra ID Hardening
# Author: Uzma Shabbir
# ============================================

Write-Host "Starting Environment Setup..." -ForegroundColor Cyan

# 1. Install Microsoft Graph (The modern standard)
# This includes all sub-modules needed for Entra ID
Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
Write-Host "✅ Microsoft Graph SDK installed" -ForegroundColor Green

# 2. Install Az module (For subscription-level security)
Install-Module Az -Scope CurrentUser -Force -AllowClobber
Write-Host "✅ Az Module installed" -ForegroundColor Green

Write-Host "`nReady for Phase 1!" -ForegroundColor Green
Write-Host "Action Required: Please restart your PowerShell session now." -ForegroundColor Yellow
