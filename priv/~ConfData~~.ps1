# Scalar data is overwited in derrived conf.
function m~ConfDataS~Inherit
(	[PSCustomObject]$ioDataParent
,	[PSCustomObject]$iData
,	[String]$iPropN
)
{	if ($null -ne $iData.$iPropN)
	{	if ($null -eq $ioDataParent.$iPropN)
		{	$ioDataParent | Add-Member -MemberType NoteProperty -Name $iPropN -Value ($iData.$iPropN)}
		else 
		{	$ioDataParent.$iPropN = $iData.$iPropN}
	}
}
#--------------------------------#
# Scalar list data is added at end of parent data
function m~ConfDataL~Inherit
(	[PSCustomObject]$ioDataParent
,	[PSCustomObject]$iData
,	[String]$iPropN
)
{	if ($null -ne $iData.$iPropN)
	{	if ($null -eq $ioDataParent.$iPropN)
		{	$ioDataParent | Add-Member -MemberType NoteProperty -Name $iPropN -Value ($iData.$iPropN)}
		else 
		{	[Collections.ArrayList]$Cll = @();
			$ioDataParent.$iPropN | % {[Void]$Cll.Add($_)};
			$iData.$iPropN | % {[Void]$Cll.Add($_)};
			$ioDataParent.$iPropN = $Cll.ToArray();
		}
	}
}
