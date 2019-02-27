# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
using module .\..\..\Common\Common.psm1
using module .\..\SslSettingRule.psm1

$exclude = @($MyInvocation.MyCommand.Name,'Template.*.txt')
$supportFileList = Get-ChildItem -Path $PSScriptRoot -Exclude $exclude
foreach ($supportFile in $supportFileList)
{
    Write-Verbose "Loading $($supportFile.FullName)"
    . $supportFile.FullName
}
# Header

<#
    .SYNOPSIS
        Convert the contents of an xccdf check-content element into a
        WebConfigurationPropertyRule object
    .DESCRIPTION
        The WebConfigurationPropertyRule class is used to extract the web
        configuration settings from the check-content of the xccdf. Once a STIG
        rule is identified as a web configuration property rule, it is passed
        to the WebConfigurationPropertyRule class for parsing and validation.
#>
Class SslSettingRuleConvert : SslSettingRule
{
    <#
        .SYNOPSIS
            Empty constructor for SplitFactory
    #>
    SslSettingRuleConvert ()
    {
    }

    <#
        .SYNOPSIS
            Converts a xccdf STIG rule element into a Web Configuration Property Rule
        .PARAMETER XccdfRule
            The STIG rule to convert
    #>
    SslSettingRuleConvert ([xml.xmlelement] $XccdfRule) : Base ($XccdfRule, $true)
    {
        $this.SetConfigSection()
        $this.SetKeyValuePair()

        if ($this.conversionstatus -eq 'pass')
        {
            if ($this.IsDuplicateRule($global:stigSettings))
            {
                $this.SetDuplicateTitle()
            }
        }
        $this.SetDscResource()
    }

    #region Methods

    <#
        .SYNOPSIS
            Extracts the config section from the check-content and sets the value
        .DESCRIPTION
            Gets the config section from the xccdf content and sets the value.
            If the section that is returned is not valid, the parser status is
            set to fail.
    #>
    [void] SetConfigSection ()
    {
        $thisConfigSection = Get-ConfigSection -CheckContent $this.SplitCheckContent

        if (-not $this.SetStatus($thisConfigSection))
        {
            $this.set_ConfigSection($thisConfigSection)
        }
    }

    <#
        .SYNOPSIS
            Extracts the key value pair from the check-content and sets the value
        .DESCRIPTION
            Gets the key value pair from the xccdf content and sets the value.
            If the value that is returned is not valid, the parser status is
            set to fail.
    #>
    [void] SetKeyValuePair ()
    {
        $thisKeyValuePair = Get-KeyValuePair -CheckContent $this.SplitCheckContent

        if (-not $this.SetStatus($thisKeyValuePair))
        {
            $this.set_Key($thisKeyValuePair.Key)
            $this.set_Value($thisKeyValuePair.Value)
        }
    }

    hidden [void] SetDscResource ()
    {
        $this.DscResource = 'xSslSetting'
    }

    static [bool] Match ([string] $CheckContent)
    {
        if
        (
            $CheckContent -Match 'SSL Settings' #-and
            #$CheckContent -NotMatch 'Get-WebConfigurationProperty'

        )
        {
            return $true
        }
        return $false
    }

    #endregion
}
