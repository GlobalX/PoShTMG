###############################################################
###															###
###  PoShTMG Module											###
###															###
###  Contains the tears of DevOps Superstars:				###
###  Nial Francis &	Matt Parkes								###
###															###
###  @ GlobalX Information Pty. Ltd. Brisbane 2014			###
###															###
###############################################################

########	TYPE DEFINITIONS

#PolicyRuleTypes
Add-Type -TypeDefinition @"
	[System.Flags] public enum PolicyRuleTypes {
		Access  = 0,
		ServerPublishing  = 1,
		WebPublishing  = 2,
		PolicyPlaceHolder  = 100
	}
"@

#PolicyRuleActions
Add-Type -TypeDefinition @"
	[System.Flags] public enum PolicyRuleActions {
		Allow  = 0,
		Deny  = 1
	}
"@

#RedirectHTTPAsHTTPS
Add-Type -TypeDefinition @"
	[System.Flags] public enum RedirectHTTPAsHTTPS {
		Disabled  = 0,
		IfAuthenticated  = 1,
		Always  = 2
	}
"@

#PublishedServerType
Add-Type -TypeDefinition @"
	[System.Flags] public enum PublishedServerType {
		HTTP  = 0,
		HTTPS  = 1,
		HTTPAndHTTPS  = 2,
		FTP = 3
	}
"@

########	CONSTANTS

#LINK TRANSLATION MAPPING GUID
Set-Variable LinkTransGUID -option Constant -value "{3563FFF5-DF93-40eb-ABC3-D24B5F14D8AA}"

########	FUNCTIONS AND MAGIC
####		(DON'T CHANGE THIS STUFF)

function Get-TMGWebPublishingRules {
<#
	.SYNOPSIS
	Gets the TMG Web Publishing Rules whose names match the specified Filter.
	.DESCRIPTION
	Uses COM to get the TMG Web Publishing Rules from the Array that this TMG server is a member of, which match the specified Filter.
	.EXAMPLE
	Get-TMGWebPublishingRules -Filter "Test *"
	.PARAMETER Filter
	The string you want to filter on. Leave blank or don't specify for no filtering.
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, HelpMessage='The Filter to apply to the list of Rule Names.')] [string]$Filter
)
	$result = @()

	$fpcroot = New-Object -ComObject fpc.root
	$tmgarray = $fpcroot.GetContainingArray()
	$rules = $tmgarray.ArrayPolicy.PolicyRules
	
	#Set $Filter to * if not set
	if (-Not $Filter) {
		$Filter = "*"
	}
	
	ForEach ($rule in $rules) {
		if ($rule.Name -Like $name -And $rule.Type -eq [PolicyRuleTypes]::WebPublishing) {
			$result += $rule
		}
	}
	
	return $result
}

function New-TMGWebPublishingRule {
	Param( 
		[parameter(Mandatory=$true)] [string]$Name,
		[parameter(Mandatory=$true)] [string]$ServerHostName,
		[parameter(Mandatory=$true)] [string]$ServerIP,
		[parameter(Mandatory=$true)] [string]$WebListener,
		[parameter(Mandatory=$true)] [string]$PublicNames,
		[ValidateSet("Allow","Deny")][string]$Action,
		[ValidateSet("HTTP","HTTPS","HTTPandSSL","FTP")][string]$ServerType,
		[string]$DeniedRuleRedirectURL,
		[string]$LogoffURL,
		[string]$SourceNetwork,
		[string]$ExcludeNetwork,
		[string]$SourceComputerSet,
		[string]$ExcludeComputerSet,
		[string]$SourceComputer,
		[string]$ExcludeComputer,
		[string]$InternalPathMapping,
		[string]$ExternalPathMapping,
		[string]$LinkTranslationReplace,
		[string]$LinkTranslationReplaceWith,
		[bool]$SameAsInternalPath,
		[bool]$TranslateLinks = 0,
		[bool]$Enabled,
		[int]$ServerAuthentication = 4,
		[int]$SSLRedirectPort,
		[int]$HTTPRedirectPort,
		[switch]$ForwardOriginalHostHeader,
		[switch]$StripDomainFromCredentials
	)
	
	if (-not($PolicyRules)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:PolicyRules = $tmgarray.ArrayPolicy.PolicyRules
	}

	try {
	  $PolicyRules.Remove("$Name")
	}
	catch {	}

	$newrule = $PolicyRules.AddWebPublishingRule("$Name")
	$newrule.WebPublishingProperties.WebSite = $ServerHostName
	$newrule.WebPublishingProperties.PublishedServer = $ServerIP
	$newrule.WebPublishingProperties.LogoffURL = $LogoffURL
	$newrule.WebPublishingProperties.SetWebListener($WebListener)
	$newrule.WebPublishingProperties.TranslateLinks = 0
	$newrule.WebPublishingProperties.CredentialsDelegationType = $ServerAuthentication
	$newrule.WebPublishingProperties.RedirectURL = $DeniedRuleRedirectURL
	$newrule.WebPublishingProperties.SSLRedirectPort = $SSLRedirectPort
	$newrule.WebPublishingProperties.HTTPRedirectPort = $HTTPRedirectPort
	$newrule.WebPublishingProperties.StripDomainFromCredentials = $StripDomainFromCredentials
	$newrule.WebPublishingProperties.Enabled = $Enabled
	$newrule.WebPublishingProperties.SendOriginalHostHeader = $ForwardOriginalHostHeader
	
	if ($Action) {$newrule.Action = [int][PolicyRuleActions]::$Action}
	if ($ServerType) {$newrule.WebPublishingProperties.PublishedServerType = [int][PublishedServerType]::$ServerType}
	
	## APPLY ACCESS POLICY IF SPECIFIED
	if (($SourceNetwork) -or ($SourceComputerSet) -or ($SourceComputer)) { $newrule.SourceSelectionIPs.Networks.RemoveAll() }
		if ($SourceNetwork) {$newrule.SourceSelectionIPs.Networks.Add("$SourceNetwork",0)}
		if ($SourceComputerSet) {$newrule.SourceSelectionIPs.ComputerSets.Add("$SourceComputerSet",0)}
		if ($SourceComputer) {$newrule.SourceSelectionIPs.Computers.Add("$SourceComputer",0)}
	if ($ExcludeNetwork) {$newrule.SourceSelectionIPs.Networks.Add("$ExcludeNetwork",1)}
	if ($ExcludeComputerSet) {$newrule.SourceSelectionIPs.ComputerSets.Add("$ExcludeComputerSet",1)}
	if ($ExcludeComputer) {$newrule.SourceSelectionIPs.Computers.Add("$ExcludeComputer",1)}
	
	if ($PublicNames) {
		foreach ($pnm in ([array]$PublicNames -split ",")) {
				$newrule.WebPublishingProperties.PublicNames.Add($pnm)
				}
		}
	
	if ($LinkTranslationReplace) {
		$nlt = $newrule.VendorParametersSets.Item($LinkTransGUID)
		$nlt.Value($LinkTranslationReplace) = $LinkTranslationReplaceWith
	}
	
	if ($SameAsInternalPath -eq 1) {$ExternalPathMapping = $InternalPathMapping}
	if ($InternalPathMapping) {$newrule.WebPublishingProperties.PathMappings.Add($InternalPathMapping,$SameAsInternalPath,$ExternalPathMapping)}

	Write-Host "`nWhen you're finished, run Save-TMGRules to save your changes`n"
}

function Get-TMGAccessRules {
<#
	.SYNOPSIS
	Gets the TMG Access Rules whose names match the specified Filter.
	.DESCRIPTION
	Uses COM to get the TMG Access Rules from the Array that this TMG server is a member of, which match the specified Filter.
	.EXAMPLE
	Get-TMGAccessRules -Filter "Test *"
	.PARAMETER Filter
	The string you want to filter on. Leave blank or don't specify for no filtering.
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, HelpMessage='The Filter to apply to the list of Rule Names.')] [string]$Filter
)
	$result = @()

	$fpcroot = New-Object -ComObject fpc.root
	$tmgarray = $fpcroot.GetContainingArray()
	$rules = $tmgarray.ArrayPolicy.PolicyRules
	
	#Set $Filter to * if not set
	if (-Not $Filter) {
		$Filter = "*"
	}
	
	ForEach ($rule in $rules) {
		if ($rule.Name -Like $name -And $rule.Type -eq [PolicyRuleTypes]::Access) {
			$result += $rule
		}
	}
	
	return $result
}

function New-TMGAccessRule {
	Param(
		[parameter(Mandatory=$true)] [string]$Name,
		[ValidateSet("Allow","Deny")][string]$Action,
		[int]$ProtocolSelectionMethod = 1,
		[string]$ProtocolName,
		[string]$AppliedComputerSet
	)

	if (-not($PolicyRules)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:PolicyRules = $tmgarray.ArrayPolicy.PolicyRules
	}

	try {
		$PolicyRules.Remove("$Name")
	}
	catch { }

	$newrule = $PolicyRules.AddAccessRule("$Name")
	if ($Action) {$newrule.Action = [int][PolicyRuleActions]::$Action}
	$newrule.AccessProperties.ProtocolSelectionMethod = $ProtocolSelectionMethod
	$newrule.AccessProperties.SpecifiedProtocols.Add("$ProtocolName",0)
	$newrule.SourceSelectionIPs.ComputerSets.Add("$AppliedComputerSet",0)

	Write-Host "`nWhen you're finished, run Save-TMGRules to save your changes`n"
}

function Get-TMGComputerSets {
<#
	.SYNOPSIS
	Gets the TMG Computer Sets whose names match the specified Filter.
	.DESCRIPTION
	Uses COM to get the TMG Computer Sets from the Array that this TMG server is a member of, which match the specified Filter.
	.EXAMPLE
	Get-TMGComputerSets -Filter "Test *"
	.PARAMETER Filter
	The string you want to filter on. Leave blank or don't specify for no filtering.
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, HelpMessage='The Filter to apply to the list of Rule Names.')] [string]$Filter
)
	$result = @()

	$fpcroot = New-Object -ComObject fpc.root
	$tmgarray = $fpcroot.GetContainingArray()
	$computersets = $tmgarray.RuleElements.ComputerSets
	
	#Set $Filter to * if not set
	if (-Not $Filter) {
		$Filter = "*"
	}
	
	ForEach ($computerset in $computersets) {
		if ($computerset.Name -Like $name) {
			$result += $computerset
		}
	}
	
	return $result
}

function New-TMGComputerSet {
	Param( 
		[parameter(Mandatory=$true)] [string]$Name
	)

	if (-not($ComputerSet)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:ComputerSet = $tmgarray.RuleElements.ComputerSets
	}

	$newcs = $ComputerSet.Add($Name)

	Write-Host "`nWhen you're finished, run Save-TMGComputerSet to save your changes`n"
}

function Add-TMGComputerToSet {
	Param( 
		[parameter(Mandatory=$true)] [string]$SetName,
		[parameter(Mandatory=$true)] [string]$ClientName,
		[parameter(Mandatory=$true)] [string]$ComputerIP
	)

	if (-not($ComputerSet)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:ComputerSet = $tmgarray.RuleElements.ComputerSets
	}

	$newcmp = $ComputerSet.item($SetName)
	$newcmp.Computers.Add($ClientName,$ComputerIP)

	Write-Host "`nWhen you're finished, run Save-TMGComputerSet to save your changes`n"
}

function New-TMGStaticRoute {
	Param( 
		[parameter(Mandatory=$true)] [string]$Destination,
		[parameter(Mandatory=$true)] [string]$Mask,
		[parameter(Mandatory=$true)] [string]$Gateway,
		[int]$Metric = 256
	)

	if (-not($ComputerSet)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:StRoute = $tmgarray.StaticRoutes
	}

	$newstrt = $StRoute.Add($Destination,$Mask,"",$Gateway)
	$newstrt.Metric = $Metric

	Write-Host "`nWhen you're finished, run Save-TMGStaticRoute to save your changes`n"
}

function Get-TMGProtocolDefinitions {
<#
	.SYNOPSIS
	Gets the TMG Protocol Definitions whose names match the specified Filter.
	.DESCRIPTION
	Uses COM to get the TMG Protocol Definitions from the Array that this TMG server is a member of, which match the specified Filter.
	.EXAMPLE
	Get-TMGProtocolDefinitions -Filter "Test *"
	.PARAMETER Filter
	The string you want to filter on. Leave blank or don't specify for no filtering.
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, HelpMessage='The Filter to apply to the list of Rule Names.')] [string]$Filter
)
	$result = @()

	$fpcroot = New-Object -ComObject fpc.root
	$tmgarray = $fpcroot.GetContainingArray()
	$protocols = $tmgarray.RuleElements.ProtocolDefinitions
	
	#Set $Filter to * if not set
	if (-Not $Filter) {
		$Filter = "*"
	}
	
	ForEach ($protocol in $protocols) {
		if ($protocol.Name -Like $name) {
			$result += $protocol
		}
	}
	
	return $result
}

function New-TMGProtocolDefinition {
	Param( 
		[parameter(Mandatory=$true)] [string]$Name
	)

	if (-not($Protocol)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:Protocol = $tmgarray.RuleElements.ProtocolDefinitions
	}

	$newprot = $Protocol.Add($Name)

	Write-Host "`nWhen you're finished, run Save-TMGProtocols to save your changes`n"
}

function Add-TMGProtocolPort {
	Param( 
		[parameter(Mandatory=$true)] [string]$Name,
		[parameter(Mandatory=$true)] [int]$LowPort,
		[parameter(Mandatory=$true)] [int]$HighPort,
		[parameter(Mandatory=$true)] [int]$Direction,
		[switch]$TCP,
		[switch]$UDP
	)

	if (($TCP -eq $false) -and ($UDP -eq $false)) {throw "You must specify an IP protocol"}

	if (-not($Protocol)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:Protocol = $tmgarray.RuleElements.ProtocolDefinitions
	}

	$newprot = $Protocol.Item($Name)
	if ($TCP) { $newprot.PrimaryConnections.AddTCP($Direction,$LowPort,$HighPort) }
	if ($UDP) { $newprot.PrimaryConnections.AddUDP($Direction,$LowPort,$HighPort) }

	Write-Host "`nWhen you're finished, run Save-TMGProtocols to save your changes`n"
}

function Get-TMGWebListeners {
<#
	.SYNOPSIS
	Gets the TMG Web Listeners whose names match the specified Filter.
	.DESCRIPTION
	Uses COM to get the TMG Web Listeners from the Array that this TMG server is a member of, which match the specified Filter.
	.EXAMPLE
	Get-TMGWebListeners -Filter "Test *"
	.PARAMETER Filter
	The string you want to filter on. Leave blank or don't specify for no filtering.
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, HelpMessage='The Filter to apply to the list of Rule Names.')] [string]$Filter
)
	$result = @()

	$fpcroot = New-Object -ComObject fpc.root
	$tmgarray = $fpcroot.GetContainingArray()
	$weblisteners = $tmgarray.RuleElements.WebListeners
	
	#Set $Filter to * if not set
	if (-Not $Filter) {
		$Filter = "*"
	}
	
	ForEach ($weblistener in $weblisteners) {
		if ($weblistener.Name -Like $name) {
			$result += $weblistener
		}
	}
	
	return $result
}

function New-TMGWebListener {
	Param( 
		[parameter(Mandatory=$true)] [string]$Name,
		[parameter(Mandatory=$true)][ValidateSet("NoAuth","HTTP","HTMLForm")] [string]$ClientAuthentication,
		[ValidateSet("Disabled","IfAuthenticated","Always")][string]$RedirectHTTPAsHTTPS,
		[string]$ListeningIP,
		[string]$CustomFormsDirectory,
		[string]$SSODomainNames,
		[string]$CertThumbprint,
		[int]$SSLPort,
		[int]$HTTPPort = 80,
		[int]$MaxConnections,
		[int]$SSLClientCertificateTimeout,
		[int]$ConnectionTimeout = $([int]::MinValue),
		[int]$UnlimitedNumberOfConnections = $([int]::MinValue),
		[bool]$SSOEnabled = 0,
		[bool]$SSLClientCertificateTimeoutEnabled
	)

	if (-not($WebListener)) {
	$fpcroot = New-Object -ComObject fpc.root
	$tmgarray = $fpcroot.GetContainingArray()
	$global:WebListener = $tmgarray.RuleElements.WebListeners
	}

	try {
	  $WebListener.Remove("$Name")
	}
	catch { }

	$newlistener = $WebListener.Add("$Name")
	$newlistener.Properties.TCPPort = $HTTPPort
	$newlistener.Properties.SSOEnabled = $SSOEnabled
	$newlistener.Properties.NumberOfConnections = $MaxConnections
	$newlistener.Properties.SSLPort = $SSLPort
	$newlistener.Properties.SSLClientCertificateTimeoutEnabled = $SSLClientCertificateTimeoutEnabled
	$newlistener.Properties.SSLClientCertificateTimeout = $SSLClientCertificateTimeout
	
	if ($SSODomainNames) {$newlistener.Properties.SSOEnabled = 1; $newlistener.Properties.SSODomainNames.Add($SSODomainNames)}
	if ($RedirectHTTPAsHTTPS) {$newlistener.Properties.RedirectHTTPAsHTTPS = [int][RedirectHTTPAsHTTPS]::$RedirectHTTPAsHTTPS}

	switch ($ClientAuthentication) {
		NoAuth {
			$newlistener.Properties.IntegratedWindowsAuthentication = 0
		}
		HTTP { <# DEFAULT #> }
		HTMLForm {
			$newlistener.Properties.AuthenticationSchemes.Add("FBA with AD",0)
			$newlistener.Properties.FormsBasedAuthenticationProperties.CustomFormsDirectory = $CustomFormsDirectory
		}
	}
	
	if ($ListeningIP) {
		$newlistener.IPsOnNetworks.Add("EXTERNAL",2,$ListeningIP)
		} else {
		$newlistener.IPsOnNetworks.Add("EXTERNAL",0,"")
	}

	if ($CertThumbprint) {
		$certhash = (gci cert:\LocalMachine\my\$CertThumbprint).getcerthash()
		$newlistener.Properties.AppliedSSLCertificates.Add($certhash,"")
	}

	if ($UnlimitedNumberOfConnections -ge 0) {
		$newlistener.Properties.UnlimitedNumberOfConnections = $UnlimitedNumberOfConnections
	}

	if ($ConnectionTimeout -ge 0) {
		$newlistener.Properties.ConnectionTimeout = $ConnectionTimeout
	}

	$newlistener.Save()
}

function Add-TMGIPRangeToNetwork {
	Param( 
		[parameter(Mandatory=$true)] [string]$NetworkName,
		[parameter(Mandatory=$true)] [string]$LowIP,
		[parameter(Mandatory=$true)] [string]$HighIP
	)

	if (-not($NetworkConf)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:NetworkConf = $tmgarray.NetworkConfiguration.Networks
	}

	$newrange = $NetworkConf.Item($NetworkName)
	$newrange.IPRangeSet.Add($LowIP,$HighIP)

	Write-Host "`nWhen you're finished, run Save-TMGNetworkConfiguration to save your changes`n"
}

function Add-TMGAdapterRangeToNetwork {
	Param( 
		[parameter(Mandatory=$true)] [string]$NetworkName,
		[parameter(Mandatory=$true)] [string]$AdapterName
	)

	if (-not($NetworkConf)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:NetworkConf = $tmgarray.NetworkConfiguration.Networks
	}
	
	if (-not($TMGServer)) {
		$fpcroot = New-Object -ComObject fpc.root
		$global:TMGServer = $fpcroot.GetContainingServer()
	}
	
	$adap = $TMGServer.Adapters | Where-Object -FilterScript { $_.friendlyname -eq $AdapterName }

	$newrange = $NetworkConf.Item($NetworkName)
	foreach ($elem in $adap.IpRanges) {
	$newrange.IPRangeSet.Add(($elem | foreach {$_.IP_From}),($elem | foreach {$_.IP_To}))
	}

	Write-Host "`nWhen you're finished, run Save-TMGNetworkConfiguration to save your changes`n"
}

function Set-TMGFloodMitigation {
<#
	.SYNOPSIS
	
	.DESCRIPTION
	
	.EXAMPLE
	
	.PARAMETER Filter
	
#>
[CmdletBinding(DefaultParametersetName="DefaultLimit")]
param
( 
	# Int.MinValue is horrible but it's the only way because PowerShell won't tell
	# you if a Parameter has been _set_ or not (other than switches via IsPresent).
    [Parameter(Mandatory=$false)] [int]$Enabled = $([int]::MinValue),
    [Parameter(Mandatory=$false)] [int]$LogQuotaRejectedTraffic = $([int]::MinValue),

    [Parameter(Mandatory=$false)] [int]$DefaultUDPLimit = $([int]::MinValue),
    [Parameter(Mandatory=$false)] [int]$DefaultTCPLimit = $([int]::MinValue),
    [Parameter(Mandatory=$false)] [int]$DefaultOtherLimit = $([int]::MinValue),
    [Parameter(Mandatory=$false)] [int]$DefaultTCPLimitPerMinute = $([int]::MinValue),
    [Parameter(Mandatory=$false)] [int]$DefaultHTTPLimitPerMinute = $([int]::MinValue),
    
	[Parameter(Mandatory=$false)] [int]$SpecialUDPLimit = $([int]::MinValue),
    [Parameter(Mandatory=$false)] [int]$SpecialTCPLimit = $([int]::MinValue),
    [Parameter(Mandatory=$false)] [int]$SpecialOtherLimit = $([int]::MinValue),
    [Parameter(Mandatory=$false)] [int]$SpecialTCPLimitPerMinute = $([int]::MinValue),
    [Parameter(Mandatory=$false)] [int]$SpecialHTTPLimitPerMinute = $([int]::MinValue)
)

	if (-not($ConnLimit)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:ConnLimit = $tmgarray.ArrayPolicy.ConnectionLimitPolicy
	}

	if ($Enabled -ge 0) {
		$ConnLimit.Enabled = $Enabled
	}
	if ($LogQuotaRejectedTraffic -ge 0) {
		$ConnLimit.LogQuotaRejectedTraffic = $LogQuotaRejectedTraffic
	}

	if ($DefaultUDPLimit -ge 0) {
		$ConnLimit.DefaultLimit.UDPLimit = $DefaultUDPLimit
	}
	if ($DefaultTCPLimit -ge 0) {
		$ConnLimit.DefaultLimit.TCPLimit = $DefaultTCPLimit
	}
	if ($DefaultOtherLimit -ge 0) {
		$ConnLimit.DefaultLimit.OtherLimit = $DefaultOtherLimit
	}
	if ($DefaultTCPLimitPerMinute -ge 0) {
		$ConnLimit.DefaultLimit.TCPLimitPerMinute = $DefaultTCPLimitPerMinute
	}
	if ($DefaultHTTPLimitPerMinute -ge 0) {
		$ConnLimit.DefaultLimit.HTTPLimitPerMinute = $DefaultHTTPLimitPerMinute
	}
	
	if ($SpecialUDPLimit -ge 0) {
		$ConnLimit.SpecialLimit.UDPLimit = $SpecialUDPLimit
	}
	if ($SpecialTCPLimit -ge 0) {
		$ConnLimit.SpecialLimit.TCPLimit = $SpecialTCPLimit
	}
	if ($SpecialOtherLimit -ge 0) {
		$ConnLimit.SpecialLimit.OtherLimit = $SpecialOtherLimit
	}
	if ($SpecialTCPLimitPerMinute -ge 0) {
		$ConnLimit.SpecialLimit.TCPLimitPerMinute = $SpecialTCPLimitPerMinute
	}
	if ($SpecialHTTPLimitPerMinute -ge 0) {
		$ConnLimit.SpecialLimit.HTTPLimitPerMinute = $SpecialHTTPLimitPerMinute
	}
	
	Write-Host "`nWhen you're finished, run Save-TMGFloodMitigationConfiguration to save your changes`n"
}

function  Save-TMGFloodMitigationConfiguration {
	if (-not($ConnLimit)) {throw "Nothing to save"}
	try { $ConnLimit.Save() }
	catch { throw $_.Exception.Message }
	write-host "Saving..."
	WaitForSync
}

function Save-TMGWebListener {
	if (-not($WebListener)) {throw "Nothing to save"}
	try { $WebListener.Save() }
	catch { throw $_.Exception.Message }
	write-host "Saving..."
	WaitForSync
}

function Save-TMGComputerSet {
	if (-not($ComputerSet)) {throw "Nothing to save"}
	try { $ComputerSet.Save() }
	catch { throw $_.Exception.Message }
	write-host "Saving..."
	WaitForSync
}

function Save-TMGRules {
	if (-not($PolicyRules)) {throw "Nothing to save"}
	try { $PolicyRules.Save() }
	catch { throw $_.Exception.Message }
	write-host "Saving..."
	WaitForSync
}

function Save-TMGProtocols {
	if (-not($Protocol)) {throw "Nothing to save"}
	try { $Protocol.Save() }
	catch { throw $_.Exception.Message }
	write-host "Saving..."
	WaitForSync
}

function Save-TMGStaticRoute {
	if (-not($StRoute)) {throw "Nothing to save"}
	try { $StRoute.Save() }
	catch { throw $_.Exception.Message }
	write-host "Saving..."
	WaitForSync
}

function Save-TMGNetworkConfiguration {
	if (-not($NetworkConf)) {throw "Nothing to save"}
	try { $NetworkConf.Save() }
	catch { throw $_.Exception.Message }
	write-host "Saving..."
	WaitForSync
}

function WaitForSync {

	if (-not($TMGServer)) {
		$fpcroot = New-Object -ComObject fpc.root
		$global:TMGServer = $fpcroot.GetContainingServer()
	}

	sleep 15
	do {write-host "Waiting for sync...";sleep 10;$TMGServer.DistributionStatus.Refresh()}
	while ($TMGServer.DistributionStatus.Status -ne 2)
	write-host "Configuration synced!"
}

export-modulemember *-*