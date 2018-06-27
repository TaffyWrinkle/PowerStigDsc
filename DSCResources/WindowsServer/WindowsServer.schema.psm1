# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

using module ..\helper.psm1
using module PowerStig

<#
    .SYNOPSIS
        A composite DSC resource to manage the Windows Server STIG settings

    .PARAMETER OsVersion
        The version of the server operating system STIG to apply and monitor

    .PARAMETER OsRole
        The role of the server operating system STIG to apply and monitor. This value further
        filters the OsVersion to select the exact STIG to apply

    .PARAMETER StigVersion
        Uses the OsVersion and OsRole to select the version of the STIG to apply and monitor. If
        this parameter is not provided, the most recent version of the STIG is automatically selected.

    .PARAMETER ForestName
        A string that sets the forest name for items such as security group. The input should be the FQDN of the forest.
        If this is omitted the forest name of the computer that generates the configuration will be used.

    .PARAMETER DomainName
        A string that sets the domain name for items such as security group. The input should be the FQDN of the domain.
        If this is omitted the domain name of the computer that generates the configuration will be used.

    .PARAMETER Exception
        A hashtable of StigId=Value key pairs that are injected into the STIG data and applied to
        the target node. The title of STIG settings are tagged with the text ‘Exception’ to identify
        the exceptions to policy across the data center when you centralize DSC log collection.

    .PARAMETER OrgSettings
        The path to the xml file that contains the local organizations preferred settings for STIG
        items that have allowable ranges.

    .PARAMETER SkipRule
        The SkipRule Node is injected into the STIG data and applied to the taget node. The title
        of STIG settings are tagged with the text 'Skip' to identify the skips to policy across the
        data center when you centralize DSC log collection.

    .PARAMETER SkipRuleType
        All STIG rule IDs of the specified type are collected in an array and passed to the Skip-Rule
        function. Each rule follows the same process as the SkipRule parameter.
#>
Configuration WindowsServer
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('2012R2', '2016')]
        [string]
        $OsVersion,

        [Parameter(Mandatory = $true)]
        [ValidateSet('DC', 'MS')]
        [string]
        $OsRole,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('2.9','2.12')]
        [version]
        $StigVersion,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ForestName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject]
        $Exception,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject]
        $OrgSettings,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject]
        $SkipRule,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [psobject]
        $SkipRuleType
    )

    if ( $Exception )
    {
        $exceptionsObject = [StigException]::ConvertFrom( $Exception )
    }
    else
    {
        $exceptionsObject = $null
    }

    if ( $SkipRule )
    {
        $skipRuleObject = [SkippedRule]::ConvertFrom( $SkipRule )
    }
    else
    {
        $skipRuleObject = $null
    }

    if ( $SkipRuleType )
    {
        $skipRuleTypeObject = [SkippedRuleType]::ConvertFrom( $SkipRuleType )
    }
    else
    {
        $skipRuleTypeObject = $null
    }

    if ( $OrgSettings )
    {
        $orgSettingsObject = Get-OrgSettingsObject -OrgSettings $OrgSettings
    }
    else
    {
        $orgSettingsObject = $null
    }

    $technology        = [Technology]::New( "Windows" )
    $technologyVersion = [TechnologyVersion]::New( $OsVersion, $technology )
    $technologyRole    = [TechnologyRole]::New( $OsRole, $technologyVersion )
    $StigDataObject    = [StigData]::New( $StigVersion, $orgSettingsObject, $technology,
                                          $technologyRole, $technologyVersion, $exceptionsObject,
                                          $skipRuleTypeObject, $skipRuleObject )

    $StigData = $StigDataObject.StigXml
    # $resourcePath is exported from the helper module in the header

    Import-DscResource -ModuleName AuditPolicyDsc
    . "$resourcePath\windows.AuditPolicySubcategory.ps1"

    Import-DscResource -ModuleName AccessControlDsc
    . "$resourcePath\windows.AccessControl.ps1"

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    . "$resourcePath\windows.Registry.ps1"
    . "$resourcePath\windows.Script.wmi.ps1"
    . "$resourcePath\windows.Script.skip.ps1"
    . "$resourcePath\windows.WindowsFeature.ps1"

    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    . "$resourcePath\windows.xService.ps1"

    Import-DscResource -ModuleName SecurityPolicyDsc
    . "$resourcePath\windows.AccountPolicy.ps1"
    . "$resourcePath\windows.UserRightsAssignment.ps1"
    . "$resourcePath\windows.SecurityOption.ps1"
}
