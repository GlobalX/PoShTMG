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

#CredentialsDelegation
# 0 = fpcDelegationNonePassThrough
# 1 = fpcDelegationNoneBlock
# 2 = fpcDelegationSecurID 
# 3 = fpcDelegationBasic
# 4 = fpcDelegationNTLM
# 5 = fpcDelegationSPNEGO
# 6 = fpcDelegationKerberosConstrained
Add-Type -TypeDefinition @"
	[System.Flags] public enum CredentialsDelegation {
		NoneClientMay  = 0,
		NoneClientCannot  = 1,
		RSASecurID  = 2,
		Basic = 3,
		NTLM = 4,
		Negotiate = 5,
		Kerberos = 6
	}
"@

#FpcProtocolSelectionType
Add-Type -TypeDefinition @"
	[System.Flags] public enum ProtocolSelectionType {
		All  = 0,
		Selected  = 1,
		AllExceptSelected  = 2
	}
"@

#FpcUDPConnectionDirectionType
# fpcReceiveOnly = 0
# fpcSendOnly = 1
# fpcReceiveSend = 2
# fpcSendReceive = 3
Add-Type -TypeDefinition @"
	[System.Flags] public enum ConnectionDirection {
		In  = 0,
		Out  = 1,
		Receive = 0,
		Send = 1,
		ReceiveSend = 2,
		SendReceive = 3
	}
"@

#FpcConnectionProtocolType 
# fpcICMP = 1
# fpcIGMP = 2
# fpcGGP  = 3
# fpcIP = 4
# fpcST = 5
# fpcTCP = 6
# fpcUDP = 17
# fpcICMPv6 = 158
Add-Type -TypeDefinition @"
	[System.Flags] public enum ConnectionProtocolType {
		ICMP = 1,
		IGMP = 2,
		GGP  = 3,
		IP = 4,
		ST = 5,
		TCP = 6,
		UDP = 17,
		ICMPv6 = 158
	}
"@

#FpcIpSelectionMethods
Add-Type -TypeDefinition @"
	[System.Flags] public enum IPSelectionMethod {
		All  = 0,
		Default  = 1,
		Specified  = 2
	}
"@

#FpcIncludeStatus
Add-Type -TypeDefinition @"
	[System.Flags] public enum IncludeStatus {
		Include  = 0,
		Exclude  = 1
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
		if ($rule.Name -Like $Filter -And $rule.Type -eq [PolicyRuleTypes]::WebPublishing) {
			$result += $rule
		}
	}
	
	return $result
}

function New-TMGWebPublishingRule {
<#
	.SYNOPSIS
	Creates a new TMG Web Publishing Rule.
	.DESCRIPTION
	Uses COM to create the specified TMG Web Publishing Rule on the array that this TMG server is a member of.
	
	New-TMGWebPublishingRule can be executed consecutively to create new rules. Save-TMGRules must then be executed to save the changes.

	Parameter names match the option name in the GUI Web Publishing Rule Properties dialog where possible, others have been added to parameter help.
	Run Get-Help New-TMGWebPublishingRule -Full
	.PARAMETER ServerHostName
	GUI Location: To tab / The rule applies to the published site.
	.PARAMETER ServerIP
	GUI Location: To tab / Computer name or IP address...
	.PARAMETER ForwardOriginalHostHeader
	GUI Location: To tab.
	.PARAMETER PublicNames
	A comma separated list of DNS and IP addresses specified on the Public Name tab.
	.PARAMETER SourceNetwork
	A comma separated list of network objects to add to the [applies to traffic] box on the From tab.
	.PARAMETER SourceComputerSet
	A comma separated list of computer set objects to add to the [applies to traffic] box on the From tab.
	.PARAMETER SourceComputer
	A comma separated list of computer objects to add to the [applies to traffic] box on the From tab.
	.PARAMETER ExcludeNetwork
	A comma separated list of network objects to add to the Exceptions box on the From tab.
	.PARAMETER ExcludeComputerSet
	A comma separated list of computer set objects to add to the Exceptions box on the From tab.
	.PARAMETER ExcludeComputer
	A comma separated list of computer objects to add to the Exceptions box on the From tab.
	.PARAMETER DeniedRuleRedirectURL
	GUI Location: Action tab / Redirect HTTP requests... box. Setting this also checks the check box and nullifying unchecks.
	.PARAMETER InternalPathMapping
	GUI Location: Paths tab - The Internal Path setting. NOTE: This item must be paired with either ExternalPathMapping or SameAsInternalPath.
	.PARAMETER ExternalPathMapping
	GUI Location: Paths tab - The External Path setting. Must be paired with InternalPathMapping.
	.PARAMETER SameAsInternalPath
	GUI Location: Paths tab - This option is a bool, paired with the Internal Path setting autofills ExternalPathMapping to match.
	.PARAMETER LinkTranslationReplace
	GUI Location: Link Translation tab / Configure / Replace. Must be paired with LinkTranslationReplaceWith.
	.PARAMETER LinkTranslationReplaceWith
	GUI Location: Link Translation tab / Configure / With. Must be paired with LinkTranslationReplace.
	.PARAMETER TranslateLinks
	GUI Location: Link Translation tab / Apply link translation...
	.PARAMETER ServerAuthentication
	GUI Location: Authentication Delegation tab / Method used...
	NoneClientMay | NoneClientCannot | RSASecurID | Basic | NTLM | Negotiate | Kerberos
	.PARAMETER ServerType
	GUI Location: Bridging tab.
	HTTP | HTTPS | HTTPandSSL | FTP
	.PARAMETER HTTPRedirectPort
	GUI Location: Bridging tab.
	.PARAMETER SSLRedirectPort
	GUI Location: Bridging tab.
	.PARAMETER UserSet
	GUI Location: Users tab.
	Specifies a User Set object to add to the rule. This can be included or an excluded with the IncludeStatus parameter.
	.PARAMETER IncludeStatus
	GUI Location: Users tab.
	Include | Exclude
	When specified with a UserSet, this parameter specifies whether the User Set is Included or Excluded.
	Included adds the set to the This rule applies to... list.
	Excluded adds the set to the Exceptions list.
	Default is Included.
	.EXAMPLE
	New-TMGWebPublishingRule -Name Test -Action Allow -ServerHostName myinternalserver -ServerIP 192.168.1.1 -WebListener MyWL -PublicNames "www.mysite.com,www.awesome.com"
	.EXAMPLE
	New-TMGWebPublishingRule -Name Test -Action Deny -WebListener MyWL -PublicNames "www.mysite.com,www.awesome.com"
	.EXAMPLE
	New-TMGWebPublishingRule -Name Test -Action Allow -ServerHostName myinternalserver -ServerIP 192.168.1.1  -WebListener MyWL -ForwardOriginalHostHeader -UserSet MyUserList -IncludeStatus Include
#>
	Param( 
		[parameter(Mandatory=$true)] [string]$Name,
		[parameter(Mandatory=$true)][ValidateSet("Allow","Deny")][string]$Action,
		[parameter(Mandatory=$true)] [string]$WebListener,
		[ValidateSet("HTTP","HTTPS","HTTPandSSL","FTP")][string]$ServerType,
		[ValidateSet("NoneClientMay","NoneClientCannot","RSASecurID","Basic","NTLM","Negotiate","Kerberos")][string]$ServerAuthentication = "NTLM",
		[ValidateSet("Include","Exclude")][string]$IncludeStatus = "Include",
		[string]$UserSet,
		[string]$ServerHostName,
		[string]$ServerIP,
		[string]$PublicNames,
		[string]$DeniedRuleRedirectURL,
		[string]$LogoffURL,
		[string]$SourceNetworks,
		[string]$ExcludeNetworks,
		[string]$SourceComputerSets,
		[string]$ExcludeComputerSets,
		[string]$SourceComputers,
		[string]$ExcludeComputers,
		[string]$InternalPathMapping,
		[string]$ExternalPathMapping,
		[bool]$SameAsInternalPath,
		[hashtable]$PathMappings,
		[bool]$TranslateLinks = 0,
		[string]$LinkTranslationReplace,
		[string]$LinkTranslationReplaceWith,
		[bool]$Enabled = $true,
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
	$newrule.WebPublishingProperties.CredentialsDelegationType = [int][CredentialsDelegation]::($ServerAuthentication)
	$newrule.WebPublishingProperties.RedirectURL = $DeniedRuleRedirectURL
	$newrule.WebPublishingProperties.StripDomainFromCredentials = $StripDomainFromCredentials
	$newrule.Enabled = $Enabled
	$newrule.WebPublishingProperties.SendOriginalHostHeader = $ForwardOriginalHostHeader
	
	if ($SSLRedirectPort) { $newrule.WebPublishingProperties.SSLRedirectPort = $SSLRedirectPort }
	if ($HTTPRedirectPort) { $newrule.WebPublishingProperties.HTTPRedirectPort = $HTTPRedirectPort }
	if ($Action) {$newrule.Action = [int][PolicyRuleActions]::$Action}
	if ($ServerType) {$newrule.WebPublishingProperties.PublishedServerType = [int][PublishedServerType]::$ServerType}
	if ($SameAsInternalPath -eq 1) {$ExternalPathMapping = $InternalPathMapping}
	if ($InternalPathMapping) {$newrule.WebPublishingProperties.PathMappings.Add($InternalPathMapping,$SameAsInternalPath,$ExternalPathMapping)}
	
	## APPLY ACCESS POLICY IF SPECIFIED
	if (($SourceNetwork) -or ($SourceComputerSet) -or ($SourceComputer)) { $newrule.SourceSelectionIPs.Networks.RemoveAll() }
	
	if ($SourceNetworks) {
		foreach ($src in ([array]$SourceNetworks -split ",")) {
				$newrule.SourceSelectionIPs.Networks.Add("$src",0)}
	}
		
	if ($SourceComputerSets) {
		foreach ($src in ([array]$SourceComputerSets -split ",")) {
				$newrule.SourceSelectionIPs.ComputerSets.Add("$src",0)}
	}
	
	if ($SourceComputers) {
		foreach ($src in ([array]$SourceComputers -split ",")) {
				$newrule.SourceSelectionIPs.Computers.Add("$src",0)}
	}
	
	if ($ExcludeNetworks) {
		foreach ($exc in ([array]$ExcludeNetworks -split ",")) {
				$newrule.SourceSelectionIPs.Networks.Add("$exc",1)}
	}
	
	if ($ExcludeComputerSets) {
		foreach ($exc in ([array]$ExcludeComputerSets -split ",")) {
				$newrule.SourceSelectionIPs.ComputerSets.Add("$exc",1)}
	}
	
	if ($ExcludeComputers) {
		foreach ($exc in ([array]$ExcludeComputers -split ",")) {
				$newrule.SourceSelectionIPs.Computers.Add("$exc",1)}
	}
	
	if ($PublicNames) {
		foreach ($pnm in ([array]$PublicNames -split ",")) {
				$newrule.WebPublishingProperties.PublicNames.Add($pnm) }
	}
	
	if ($LinkTranslationReplace) {
		<#try {
			$nlt = $newrule.VendorParametersSets.Item($LinkTransGUID)
		} catch {
			$nlt = $newrule.VendorParametersSets.Add($LinkTransGUID)
		}#>
		$nlt = $newrule.VendorParametersSets.Add($LinkTransGUID)
		$nlt.Value($LinkTranslationReplace) = $LinkTranslationReplaceWith
	}
	
	if ($UserSet) {
		$newrule.WebPublishingProperties.UserSets.RemoveAll()
		$newrule.WebPublishingProperties.UserSets.Add($UserSet,([int][IncludeStatus]::$IncludeStatus))
	}
	
	if ($PathMappings) {
		ForEach ($PathMapping in $PathMappings.GetEnumerator()) {
			if ($PathMapping.Name -eq $PathMapping.Value) { $PathMappingsSame = $true }  else { $PathMappingsSame = $false }
			$newrule.WebPublishingProperties.PathMappings.Add($PathMapping.Name,$PathMappingsSame,$PathMapping.Value)
		}
	}
	
	return $newrule
}

function Move-TMGRule {
	
	Param( 
		[string]$Name,
		$TMGWebPublishingRule,
		
		[switch]$Up,
		[switch]$Down
		
#		[int]$Position,		#Position will determine correct number of MoveUp() or MoveDown() to get to the desired position
#		[switch]$Top,		#Top 			""					""
#		[switch]$Bottom		#Bottom			""					""

#		$AboveRuleNamed		#will place this rule immediately above the specified rule
#		$BelowRuleNamed,	#will place this rule immediately below the specified rule

	)
	
	if ((-Not $TMGWebPublishingRule) -And (-Not $Name)) {
		Throw "You must provide -TMGWebPublishingRule or -Name"
	}
	elseif (($TMGWebPublishingRule) -And ($Name)) {
		Throw "You must not provide both -TMGWebPublishingRule and -Name"
	}
	
	if (-not($PolicyRules)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:PolicyRules = $tmgarray.ArrayPolicy.PolicyRules
	}
	
	if ($Name) {
		ForEach ($policyrule in $global:PolicyRules) {
			if ($policyrule.Name -eq $Name) {
				$rule = $policyrule
				break
			}
		}
	}
	if ($TMGWebPublishingRule) {
		$rule = $TMGWebPublishingRule
	}
	
	if ($Up) { 
		$global:PolicyRules.MoveUp($rule.order)
	}
	
	if ($Down) {
		$global:PolicyRules.MoveDown($rule.order)
	}
	
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
		if ($rule.Name -Like $Filter -And $rule.Type -eq [PolicyRuleTypes]::Access) {
			$result += $rule
		}
	}
	
	return $result
}

function New-TMGAccessRule {
<#
	.SYNOPSIS
	Creates a new TMG Access Rule.
	.DESCRIPTION
	Uses COM to create the specified TMG Access Rule on the array that this TMG server is a member of.
	
	New-TMGAccessRule can be executed consecutively to create new rules. Save-TMGRules must then be executed to save the changes.

	Parameter names match the option name in the GUI Access Rule Properties dialog where possible, others have been added to parameter help.
	Run Get-Help New-TMGAccessRule -Full
	.PARAMETER ProtocolNames
	A comma separated list of protocol object names.
	.PARAMETER SourceNetwork
	A comma separated list of network objects to add to the [applies to traffic] box on the From tab.
	.PARAMETER SourceComputerSet
	A comma separated list of computer set objects to add to the [applies to traffic] box on the From tab.
	.PARAMETER SourceComputer
	A comma separated list of computer objects to add to the [applies to traffic] box on the From tab.
	.PARAMETER ExcludeNetwork
	A comma separated list of network objects to add to the Exceptions box on the From tab.
	.PARAMETER ExcludeComputerSet
	A comma separated list of computer set objects to add to the Exceptions box on the From tab.
	.PARAMETER ExcludeComputer
	A comma separated list of computer objects to add to the Exceptions box on the From tab.
	.EXAMPLE
	New-TMGAccessRule -Name Test -Action Allow -ProtocolSelectionMethod AllExceptSelected -ProtocolNames HTTP -ExcludeNetwork MyEnemies
#>
	Param(
		[parameter(Mandatory=$true)][string]$Name,
		[parameter(Mandatory=$true)][ValidateSet("Allow","Deny")][string]$Action,
		[ValidateSet("All","Selected","AllExceptSelected")][string]$ProtocolSelectionMethod = "Selected",
		[ValidateSet("Include","Exclude")][string]$IncludeStatus = "Include",
		[string]$UserSet,
		[string]$ProtocolNames,
		[string]$SourceNetwork,
		[string]$ExcludeNetwork,
		[string]$SourceComputerSet,
		[string]$ExcludeComputerSet,
		[string]$SourceComputer,
		[string]$ExcludeComputer
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
	$newrule.Action = [int][PolicyRuleActions]::$Action
	$newrule.AccessProperties.ProtocolSelectionMethod = [int][ProtocolSelectionType]::$ProtocolSelectionMethod
	
	## APPLY ACCESS POLICY IF SPECIFIED
	if (($SourceNetwork) -or ($SourceComputerSet) -or ($SourceComputer)) { $newrule.SourceSelectionIPs.Networks.RemoveAll() }
	
	if ($SourceNetwork) {
		foreach ($src in ([array]$SourceNetwork -split ",")) {
				$newrule.SourceSelectionIPs.Networks.Add("$src",0) }
	}
		
	if ($SourceComputerSet) {
		foreach ($src in ([array]$SourceComputerSet -split ",")) {
				$newrule.SourceSelectionIPs.ComputerSets.Add("$src",0) }
	}
	
	if ($SourceComputer) {
		foreach ($src in ([array]$SourceComputer -split ",")) {
				$newrule.SourceSelectionIPs.Computers.Add("$src",0) }
	}
	
	if ($ExcludeNetwork) {
		foreach ($exc in ([array]$ExcludeNetwork -split ",")) {
				$newrule.SourceSelectionIPs.Networks.Add("$exc",1) }
	}
	
	if ($ExcludeComputerSet) {
		foreach ($exc in ([array]$ExcludeComputerSet -split ",")) {
				$newrule.SourceSelectionIPs.ComputerSets.Add("$exc",1) }
	}
	
	if ($ExcludeComputer) {
		foreach ($exc in ([array]$ExcludeComputer -split ",")) {
				$newrule.SourceSelectionIPs.Computers.Add("$exc",1) }
	}
	
	if ($ProtocolNames) {
		foreach ($prt in ([array]$ProtocolNames -split ",")) {
				$newrule.AccessProperties.SpecifiedProtocols.Add("$prt",0) }
	}
	
	if ($UserSet) {
		$newrule.AccessProperties.UserSets.RemoveAll()
		$newrule.AccessProperties.UserSets.Add($UserSet,([int][IncludeStatus]::$IncludeStatus))
	}
	
	return $newrule
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
		if ($computerset.Name -Like $Filter) {
			$result += $computerset
		}
	}
	
	return $result
}

function New-TMGComputerSet {
<#
	.SYNOPSIS
	Adds a TMG Computer Set with the specified name.
	.DESCRIPTION
	Uses COM to create the specified TMG Computer Set on the array that this TMG server is a member of.
	
	New-TMGComputerSet can be executed consecutively to create new sets. Save-TMGComputerSet must then be executed to save the changes.
	.EXAMPLE
	New-TMGComputerSet -Name MySet
#>
	Param( 
		[parameter(Mandatory=$true)] [string]$Name
	)

	if (-not($ComputerSet)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:ComputerSet = $tmgarray.RuleElements.ComputerSets
	}

	$newcs = $ComputerSet.Add($Name)

	return $newcs
}

function Add-TMGComputerToSet {
<#
	.SYNOPSIS
	Adds an entry to the TMG Computer Set with the specified name.
	.DESCRIPTION
	Uses COM to add a name/address pair to the specified TMG Computer Set on the array that this TMG server is a member of.
	
	Add-TMGComputerToSet can be executed consecutively add new entries. Save-TMGComputerSet must then be executed to save the changes.
	.EXAMPLE
	Add-TMGComputerToSet -SetName MySet -ClientName MYSERVER -ComputerIP 192.168.1.1
	.PARAMETER ClientName
	Matches the Name field in the list of entries under a computer set.
	.PARAMETER ComputerIP
	Matches the IP Address field in the list of entries under a computer set.
#>
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

	return $newcmp
}

function New-TMGStaticRoute {
<#
	.SYNOPSIS
	Adds an entry to the TMG Network Topology Routes list.
	.DESCRIPTION
	Uses COM to add a route to the TMG Network Topology Routes list on the array that this TMG server is a member of.
	
	Accepts dot-decimal notation only for all address parameters.
	
	New-TMGStaticRoute can be executed consecutively to create new routes. Save-TMGStaticRoute must then be executed to save the changes.
	.EXAMPLE
	New-TMGStaticRoute -Destination 192.168.5.128 -Mask 255.255.255.128 -Gateway 192.168.1.254 -Metric 16
	.PARAMETER Destination
	The network address of the destination network.
	.PARAMETER Mask
	The netmask of the destination.
#>
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

	return $newstrt
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
		if ($protocol.Name -Like $Filter) {
			$result += $protocol
		}
	}
	
	return $result
}

function New-TMGProtocolDefinition {
<#
	.SYNOPSIS
	Adds a TMG User-Defined Protocol object with the specified name.
	.DESCRIPTION
	Uses COM to create the TMG Protocol on the array that this TMG server is a member of, with the specified name.
	
	New-TMGProtocolDefinition can be executed consecutively to create new objects. Save-TMGProtocols must then be executed to save the changes.
	.EXAMPLE
	New-TMGProtocolDefinition -Name MySpecialProtocol
#>
	Param( 
		[parameter(Mandatory=$true)] [string]$Name
	)

	if (-not($Protocol)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:Protocol = $tmgarray.RuleElements.ProtocolDefinitions
	}

	$newprot = $Protocol.Add($Name)

	return $newprot
}

function Add-TMGProtocolPort {
<#
	.SYNOPSIS
	Adds a TMG User-Defined Protocol port entry to the protocol with the specified name.
	.DESCRIPTION
	Uses COM to add a port to the specified TMG protocol on the array that this TMG server is a member of.
	
	Add-TMGProtocolPort can be executed consecutively to create new entries. Save-TMGProtocols must then be executed to save the changes.
	.PARAMETER Connection
	Primary | Secondary
	Places the protocol in the Primary or Secondary Connections box. A primary protocol must be defined before a secondary protocol can.
	.PARAMETER IPType
	ICMP | TCP | UDP | IPLevel
	.PARAMETER Direction
	If IPType is set to TCP - The options available are In | Out.
	If IPType is set to UDP - The options available are Receive | Send | ReceiveSend | SendReceive.
	If IPType is set to ICMP or IPLevel - The options available are Send | SendReceive.
	.PARAMETER IPLevelConnectionProtocol
	ICMP | IGMP | GGP | IP | ST | TCP | UDP | ICMPv6
	.EXAMPLE
	Add-TMGProtocolPort -Name MySpecialProtocol -Connection Primary -Direction In -IPType TCP -LowPort 110 -HighPort 120
	.EXAMPLE
	Add-TMGProtocolPort -Name MyRawProtocol -Connection Primary -Direction ReceiveSend -IPType IPLevel -IPLevelConnectionProtocol GGP
	.EXAMPLE
	Add-TMGProtocolPort -Name MyICMPProtocol -Connection Primary -Direction In -IPType ICMP -ICMPCode 0 -ICMPType 8
#>
	Param(
		[parameter(Mandatory=$true)][string]$Name,
		[parameter(Mandatory=$true)][ValidateSet("In","Out","Receive","Send","ReceiveSend","SendReceive")][string]$Direction,
		[parameter(Mandatory=$true)][ValidateSet("Primary","Secondary")][string]$Connection,
		[parameter(Mandatory=$true)][ValidateSet("ICMP","TCP","UDP","IPLevel")][string]$IPType,
		[ValidateSet("ICMP","IGMP","GGP","IP","ST","TCP","UDP","ICMPv6")][string]$IPLevelConnectionProtocol,
		[int]$LowPort,
		[int]$HighPort,
		[int]$ICMPCode,
		[int]$ICMPType
	)

	if (-not($Protocol)) {
		$fpcroot = New-Object -ComObject fpc.root
		$tmgarray = $fpcroot.GetContainingArray()
		$global:Protocol = $tmgarray.RuleElements.ProtocolDefinitions
	}
	
	$newprot = $Protocol.Item($Name)
	
	if ($Connection -eq "Primary") { $npcmd = $newprot.PrimaryConnections }
	if ($Connection -eq "Secondary") { $npcmd = $newprot.SecondaryConnections }
	
	switch ($IPType) {
		TCP { $npcmd.AddTCP(([int][ConnectionDirection]::$Direction),$LowPort,$HighPort) }
		UDP { $npcmd.AddUDP(([int][ConnectionDirection]::$Direction),$LowPort,$HighPort) }
		ICMP { $npcmd.AddICMP(([int][ConnectionDirection]::$Direction),$ICMPCode,$ICMPType) }
		IPLevel { $npcmd.AddRAW(([int][ConnectionDirection]::$Direction),([int][ConnectionProtocolType]::$IPLevelConnectionProtocol)) }
	}
	
	return $newprot
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
		if ($weblistener.Name -Like $Filter) {
			$result += $weblistener
		}
	}
	
	return $result
}

function New-TMGWebListener {
<#
	.SYNOPSIS
	Creates a TMG Web Listener with the specified name.
	.DESCRIPTION
	Uses COM to create the specified TMG Web Listener on the array that this TMG server is a member of.
	
	New-TMGWebListener can be executed consecutively to create new rules. Save-TMGWebListener must then be executed to save the changes.
	.EXAMPLE
	New-TMGWebListener -Name MyWL -ClientAuthentication NoAuth -ListeningIP 1.2.2.1 -HTTPPort 81 
	.PARAMETER ClientAuthentication
	Client Authentication Method.
	NoAuth | IfAuthenticated | Always
	.PARAMETER RedirectHTTPAsHTTPS
	Disabled | IfAuthenticated | Always
	.PARAMETER HTTPPort
	Client connections port number.
	If set connections are enabled on the port number.
	Set to 0 to disable.
	.PARAMETER SSLPort
	Client connections port number.
	If set connections are enabled on the port number.
	Set to 0 to disable.
	.PARAMETER SourceNetworkName
	Specify the name of the network object to listen on. If not specified, the new listener will bind to the External network and listen on all IPs.
	.PARAMETER ListeningForRequests
	Sets the listener IP address binding type.
	All | Default | Specified
	All - the listener will bind to all IPs on the SourceNetworkName network.
	Default - the default IP - eg. if load balancing is configured the VIP will be chosen.
	Specified - the listener binds to the address specified by ListeningIP.
	.PARAMETER ListeningIP
	Binds the listener to a specified IP. This must be used with the SourceNetworkName set and ListeningForRequests set to Specified.
#>
	Param( 
		[parameter(Mandatory=$true)] [string]$Name,
		[ValidateSet("NoAuth","HTTP","HTMLForm")] [string]$ClientAuthentication,
		[ValidateSet("Disabled","IfAuthenticated","Always")][string]$RedirectHTTPAsHTTPS,
		[ValidateSet("All","Default","Specified")][string]$ListeningForRequests,
		[string]$SourceNetworkName,
		[string]$ListeningIP,
		[string]$CustomFormsDirectory,
		[string]$SSODomainNames,
		[string]$CertThumbprint,
		[int]$SSLPort,
		[int]$HTTPPort = 80,
		[int]$MaxConnections,
		[int]$SSLClientCertificateTimeout,
		[int]$ConnectionTimeout,
		[bool]$UnlimitedNumberOfConnections,
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
	$newlistener.Properties.SSLPort = $SSLPort
	$newlistener.Properties.SSLClientCertificateTimeoutEnabled = $SSLClientCertificateTimeoutEnabled
		
	if ($MaxConnections) { $newlistener.Properties.NumberOfConnections = $MaxConnections }
	if ($SSLClientCertificateTimeout) { $newlistener.Properties.SSLClientCertificateTimeout = $SSLClientCertificateTimeout }
	if ($ConnectionTimeout) { $newlistener.Properties.ConnectionTimeout = $ConnectionTimeout }
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

	if (-not($SourceNetworkName)) {
		$newlistener.IPsOnNetworks.Add("External",0,"")
		} else {
		$newlistener.IPsOnNetworks.Add($SourceNetworkName,[int][IPSelectionMethod]::$ListeningForRequests,$ListeningIP)
	}
	
	if ($CertThumbprint) {
		$certhash = (gci cert:\LocalMachine\my\$CertThumbprint).getcerthash()
		$newlistener.Properties.AppliedSSLCertificates.Add($certhash,"")
	}

	if ($UnlimitedNumberOfConnections -ge 0) {
		$newlistener.Properties.UnlimitedNumberOfConnections = $UnlimitedNumberOfConnections
	}

	return $newlistener
}

function Add-TMGIPRangeToNetwork {
<#
	.SYNOPSIS
	Adds an IP range to the specified TMG Network object.
	.DESCRIPTION
	Uses COM to add an IP range to a TMG Network on the array that this TMG server is a member of.
	
	Add-TMGIPRangeToNetwork can be executed consecutively to create new entries. Save-TMGNetworkConfiguration must then be executed to save the changes.
	.EXAMPLE
	Add-TMGIPRangeToNetwork -NetworkName Internal -LowIP 192.168.6.12 -HighIP 192.168.6.80
	.EXAMPLE
	Add-TMGIPRangeToNetwork -NetworkName SecretNetwork -LowIP 192.168.7.12 -HighIP 192.168.8.90
#>
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

	return $newrange
}

function Add-TMGAdapterRangeToNetwork {
<#
	.SYNOPSIS
	Automatically adds an IP range taken from a network adaprot to the specified TMG Network object.
	.DESCRIPTION
	Uses COM to gather network data from the specified ethernet adapter then add it's IP range to a TMG Network on the array that this TMG server is a member of.
	
	Available adapter names can be gathered via the GUI - Networking > Network Adapters.
	
	Add-TMGAdapterRangeToNetwork can be executed consecutively to create new entries. Save-TMGNetworkConfiguration must then be executed to save the changes.
	.EXAMPLE
	Add-TMGAdapterRangeToNetwork -NetworkName Internal -AdapterName Ethernet
	.EXAMPLE
	Add-TMGAdapterRangeToNetwork -NetworkName Internal -AdapterName MyVLAN63Adapter
#>
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

	return $newrange
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