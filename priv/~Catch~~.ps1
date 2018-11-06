# Default error handler.
function m~Catch~ToMsgCllStd
(	[object]$iXXX
,	[Collections.Generic.List[String]]$iMsgCll
)
{try 
{	if ($null -eq $iMsgCll)
	{	return}

	if ($null -ne $iXXX.InvocationInfo)
	{	$iMsgCll.Add($iXXX.InvocationInfo.PositionMessage)}

	$iXXX = $iXXX.Exception;

	while ($null -ne $iXXX)
	{	if ([String]::IsNullOrEmpty($iXXX.Message))
		{	$iMsgCll.Add("[$($iXXX.GetType().FullName)]: $($iXXX.ToString())")}
		else
		{	$iMsgCll.Add("[$($iXXX.GetType().FullName)]: $($iXXX.Message)")}

		$iXXX = $iXXX.InnerException;
	}
}
catch
{	}
}
