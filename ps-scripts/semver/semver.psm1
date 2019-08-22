[CmdletBinding()]
param(
    [Parameter(Mandatory=$False)]
    [string]$semver_file_name = "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\.semver"
)

$MAJOR_LINE = 1
$MINOR_LINE = 2
$PATCH_LINE = 3
$SPECIAL_LINE = 4

function Invoke-Semver {
    <#
    .SYNOPSIS
    Provides semantic version tracking.
    .DESCRIPTION
    Invoke-Semver provides semantic version tracking. When invoking this command, if semantic versioning does
    not current exist, a new .semver file will be created to track semantic versioning.  It also provides commands
    to increment the version numbers, and the ability to format the versioning information in a string.
    .EXAMPLE
    Invoke-Semver
    Outputs the current version information as: v1.0.0
    .EXAMPLE
    Invoke-Semver -Increment major
    Increments the major version number by 1.  If the version number was previously 1.0.0, it will now be 2.0.0
    .EXAMPLE
    Invoke-Semver -Special alpha
    Sets the special version suffix.
    .EXAMPLE
    Invoke-Semver -Format %M.%m.%p$s
    Returns the current version number in the format of 1.0.0alpha
    .LINK
    https://github.com/bahrens/posh-semver
    #>
    param(
        [Parameter(Position=0,Mandatory=0,HelpMessage="Options are major, minor, patch")]
        [ValidateSet("major", "minor", "patch")]
        [string]
        $Increment,
        [Parameter(Position=1,Mandatory=0,HelpMessage="Set a special version suffix")]
        [string]
        $Special,
        [Parameter(Position=2,Mandatory=0,HelpMessage="Options are %M, %m, %p, %s")]
        [string]
        $Format)

    New-IfSemverNotExist

    $semver_content = Get-SemverContent

    Set-NumericVersion $Increment $semver_content

    Set-Special $Special $semver_content

    Get-Format $Format $semver_content
}

function New-IfSemverNotExist {

    if (!(Test-Path $semver_file_name)) {
        Write-Output "Could not find file $semver_file_name"        
        New-SemverFile
    }
}

function New-SemverFile {
    $contents = 
@"
--------
major: 0
minor: 0
patch: 0
special: ''
"@

    $contents | Out-File -filepath $semver_file_name
}

function Get-SemverContent {
    Get-Content $semver_file_name
}

function Set-NumericVersion($increment, $semver_content) {
    if ($increment -eq "major") {
        $version = Get-IncrementedVersion $semver_content $MAJOR_LINE
        [void](Save-NewVersion $semver_content $MAJOR_LINE "major" $version)
    }
    elseif ($increment -eq "minor") {
        $version = Get-IncrementedVersion $semver_content $MINOR_LINE
        [void](Save-NewVersion $semver_content $MINOR_LINE "minor" $version)
    }
    elseif ($increment -eq "patch") {
        $version = Get-IncrementedVersion $semver_content $PATCH_LINE
        [void](Save-NewVersion $semver_content $PATCH_LINE "patch" $version)
    }
}

function Get-IncrementedVersion($semver_content, $index) {
    $current_version = Get-Version $semver_content $index
    $current_version + 1
}

function Get-Version($semver_content, $index) {
    [void]($semver_content[$index] -match "(?<number>\d+)")
    [int]$matches['number']
}

function Set-Special($special, $semver_content) {
    if ($special.Length -ne 0) {
        [void](Save-NewVersion $semver_content $SPECIAL_LINE "special" "'$Special'")
    }
}

function Get-Format($format, $semver_content) {
    if ($format.Length -ne 0) {
        Format-VersionString $format $semver_content
    } else {
        Format-VersionString 'v%M.%m.%p' $semver_content
    }
}

function Save-NewVersion($semver_content, $index, $version_part, $version) {

    $semver_content[$index] = "$version_part`: $version"
    $semver_content | Out-File -filepath $semver_file_name
}

function Format-VersionString($format, $semver_content) {
    $format = $format -creplace '%M', (Get-Version $semver_content $MAJOR_LINE)
    $format = $format -creplace '%m', (Get-Version $semver_content $MINOR_LINE)
    $format = $format -creplace '%p', (Get-Version $semver_content $PATCH_LINE)
    $format = $format -creplace '%s', (Get-Special $semver_content $SPECIAL_LINE)
    $format
}

function Get-Special($semver_content, $index) {
    [void]($semver_content[$index] -match "'(?<special>.*)'")
    $matches['special']
}

Export-ModuleMember -Function 'Invoke-Semver'