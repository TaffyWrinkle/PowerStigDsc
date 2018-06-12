﻿<#
    Use embedded STIG data and skip an entire rule set. In this example,
    the Windows Server 2012R2 V2 R8 domain controller STIG is processed by
    the composite resource and merges in the default values for any settings
    that have a valid range. Additionally, a skip is added inline to the
    configuration, so that the setting for all STIG ID's with the type
    'AuditPolicyRule' would be marked to skip configuration when applied.
#>

configuration Sample_WindowsServer_SkipRuleType
{
    param
    (
        [parameter()]
        [string]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName PowerStigDsc

    Node $NodeName
    {
        WindowsServer BaseLine
        {
            OsVersion    = '2012R2'
            OsRole       = 'DomainController'
            StigVersion  = '2.8'
            SkipRuleType = 'AuditPolicyRule'
        }
    }
}

Sample_WindowsServer_SkipRuleType