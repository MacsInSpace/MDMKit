function Publish-JamfPackage {
    <#
    .SYNOPSIS
        Uploads a package file to Jamf Pro cloud distribution (JCDS), creating the
        package record if needed.
    .DESCRIPTION
        Uses the Jamf Pro API upload endpoint (POST /api/v1/packages/{id}/upload,
        Jamf Pro 11.5+), which relays the file to the cloud distribution point and
        computes the hash server-side.

        Record resolution order:
          1. -PackageId, if supplied.
          2. An existing record whose fileName matches the file's name (reused —
             uploading replaces the stored file).
          3. A new record is created (name defaults to the file's base name).

        Jamf computes the package hash asynchronously after upload; -WaitForHash
        polls until it appears so you can verify before deploying.
    .PARAMETER Path
        Path to the package file (.pkg/.dmg/etc.).
    .PARAMETER WaitForHash
        Poll the package record (up to -TimeoutMinutes) until Jamf has computed the
        file hash, then return the record including it.
    .EXAMPLE
        Publish-JamfPackage -Path ./Firefox-128.0.pkg
    .EXAMPLE
        Publish-JamfPackage -Path ./Firefox-128.0.pkg -CategoryId 5 -WaitForHash
    .EXAMPLE
        Get-ChildItem ./out/*.pkg | ForEach-Object { Publish-JamfPackage -Path $_.FullName }
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateScript({ Test-Path $_ -PathType Leaf }, ErrorMessage = 'Package file not found: {0}')]
        [string] $Path,

        [string] $PackageId,

        [string] $PackageName,

        [string] $CategoryId = '-1',

        [switch] $WaitForHash,

        [ValidateRange(1, 120)]
        [int] $TimeoutMinutes = 10,

        # Upload HTTP timeout in seconds; raise for very large packages on slow links.
        [int] $UploadTimeoutSec = 3600,

        [PSTypeName('JamfProKit.Session')]
        [object] $Session
    )

    begin {
        $resolved = Assert-JamfSession -Session $Session
    }

    process {
        $file = Get-Item -Path $Path
        $targetId = $PackageId

        if (-not $targetId) {
            $existing = @(Get-JamfPackage -Session $resolved -FileName $file.Name)
            if ($existing.Count -gt 1) {
                throw "Multiple package records match fileName '$($file.Name)' (ids: $($existing.id -join ', ')). Specify -PackageId."
            }
            if ($existing.Count -eq 1) {
                $targetId = [string]$existing[0].id
                Write-Verbose "Reusing existing package record id $targetId for $($file.Name)."
            }
        }

        $sizeMB = [math]::Round($file.Length / 1MB, 1)
        if (-not $PSCmdlet.ShouldProcess("$($file.Name) ($sizeMB MB)", 'Upload package to Jamf Pro')) {
            return
        }

        if (-not $targetId) {
            $name = if ($PackageName) { $PackageName } else { $file.BaseName }
            $record = New-JamfPackage -Session $resolved -PackageName $name -FileName $file.Name `
                -CategoryId $CategoryId -Confirm:$false
            $targetId = [string]$record.id
            Write-Verbose "Created package record id $targetId for $($file.Name)."
        }

        Write-Verbose "Uploading $($file.Name) ($sizeMB MB) to package id $targetId..."
        Invoke-JamfRequest -Session $resolved -Method POST -Path "api/v1/packages/$targetId/upload" `
            -Form @{ file = $file } -TimeoutSec $UploadTimeoutSec | Out-Null

        if ($WaitForHash) {
            $deadline = [DateTimeOffset]::UtcNow.AddMinutes($TimeoutMinutes)
            do {
                $record = Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/packages/$targetId"
                $hash = if ($record.PSObject.Properties.Match('hashValue').Count -gt 0) { $record.hashValue } else { $null }
                if ($hash) { return $record }
                Write-Verbose 'Waiting for Jamf to compute the package hash...'
                Start-Sleep -Seconds 10
            } while ([DateTimeOffset]::UtcNow -lt $deadline)
            Write-Warning "Upload completed but no hash appeared within $TimeoutMinutes minute(s); returning the record as-is."
            return $record
        }

        Invoke-JamfRequest -Session $resolved -Method GET -Path "api/v1/packages/$targetId"
    }
}
