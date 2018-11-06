#--------------------------------#
function m~ConfFile~Load
(	[String]$iPath
,	[String]$iKeyRoot
)
{	switch -Exact ([IO.Path]::GetExtension($iPath))
	{	'.xml'
		{	([xml]$RawRoot = [xml]::new()).Load($iPath);
			[String]$Mode = 'xml';
		}
		'.json'
		{	[PSCustomObject]$RawRoot = [IO.File]::ReadAllText($iPath, [Text.Encoding]::UTF8) | ConvertFrom-Json;
			[String]$Mode = 'json';
		}
		'.psd1'
		{	[PSCustomObject]$RawRoot = [PSCustomObject]::new();
			Import-LocalizedData -BindingVariable RawRoot -BaseDirectory ([IO.Path]::GetDirectoryName($iPath)) -FileName ([IO.Path]::GetFileName($iPath));
			[String]$Mode = 'psd';
		}
		default
		{	throw [Exception]::new('Confg file extension not supported.')}
	}
	
	[PSCustomObject]$Ret = [PSCustomObject]::new();
	[System.Collections.Queue]$MainCll = @();

	$MainCll.Enqueue($Ret);
	$MainCll.Enqueue($RawRoot.$iKeyRoot);

	while ($MainCll.Count)
	{	[PSCustomObject]$Val = $MainCll.Dequeue();
		[object]$RawVal = $MainCll.Dequeue();

		foreach ($PropIt in $RawVal | Get-Member -MemberType Properties -Name 'O?-*', 'S?-*', 'V-Is')
		{	switch -Exact -Casesensitive ($PropIt.Name.Substring(0, 2))
			{	'V-' # V-Is
				{	if ($null -eq $Val.Is)
					{	throw [FormatException]::new("Invalid config format. File: '$iPath'")}
					
					$Val.Is = $RawVal.'V-Is';
				}
				'OV'
				{	[Object]$RawSubVal = $RawVal."$($PropIt.Name)";
					[object]$SubVal = [PSCustomObject]::new();

					if ($RawSubVal | Get-Member -MemberType Properties -Name 'O?-*', 'S?-*')
					{	$MainCll.Enqueue($SubVal);
						$MainCll.Enqueue($RawSubVal);
						$Val | Add-Member -MemberType NoteProperty -Name ('V' +  $PropIt.Name.Substring(3)) -Value $SubVal;
					}
				}
				'OL'
				{	[Object[]]$RawValArr = $RawVal."$($PropIt.Name)";
					[PSCustomObject[]]$SubValArr = @();
					[Object]$RawSubVal = $null;
					
					foreach ($RawSubVal in $RawValArr)
					{	if ($RawSubVal | Get-Member -MemberType Properties -Name 'O?-*', 'S?-*')
						{	$SubValArr += ([object]$SubVal = [PSCustomObject]::new());
							$MainCll.Enqueue($SubVal);
							$MainCll.Enqueue($RawSubVal);
						}
					}

					if ($SubValArr.Count)
					{	$Val | Add-Member -MemberType NoteProperty -Name ('L' +  $PropIt.Name.Substring(3)) -Value $SubValArr}
				}
				'SV'
				{	[Object]$RawSubVal = $RawVal."$($PropIt.Name)";
					[object]$SubVal = $null;

					if ($RawSubVal | Get-Member -MemberType Properties -Name 'S?-*')
					{	[object]$SubVal = [PSCustomObject]@{'Is'=[String]::Empty};
						$MainCll.Enqueue($SubVal);
						$MainCll.Enqueue($RawSubVal);
					}
					elseif ($RawSubVal | Get-Member -MemberType Properties -Name 'V-Is')
					{	$SubVal = [PSCustomObject]@{'Is'=[String]$RawSubVal.'V-Is'}}
					elseif (-not [String]::IsNullOrEmpty($RawSubVal))
					{	$SubVal = [PSCustomObject]@{'Is'=[String]$RawSubVal}}

					if ($null -ne $SubVal)
					{	$Val | Add-Member -MemberType NoteProperty -Name ('V' +  $PropIt.Name.Substring(3)) -Value $SubVal}
				}
				'SL'
				{	[Object[]]$RawValArr = $RawVal."$($PropIt.Name)";
					[PSCustomObject[]]$SubValArr = @();
					[Object]$RawSubVal = $null;

					foreach ($RawSubVal in $RawValArr)
					{	if ($RawSubVal | Get-Member -MemberType Properties -Name 'S?-*')
						{	$SubValArr += ([object]$SubVal = [PSCustomObject]@{'Is'=[String]::Empty});
							$MainCll.Enqueue($SubVal);
							$MainCll.Enqueue($RawSubVal);
						}
						elseif ($RawSubVal | Get-Member -MemberType Properties -Name 'V-Is')
						{	$SubValArr += [PSCustomObject]@{'Is'=[String]$RawSubVal.'V-Is'}}
						elseif (-not [String]::IsNullOrEmpty($RawSubVal))
						{	$SubValArr += [PSCustomObject]@{'Is'=[String]$RawSubVal}}
					}

					if ($SubValArr.Count)
					{	$Val | Add-Member -MemberType NoteProperty -Name ('L' +  $PropIt.Name.Substring(3)) -Value $SubValArr}

				}
				default
				{	throw [FormatException]::new("Invalid config format. File: '$iPath'")}
			} 
		}	
	}

	return $Ret;
}
#--------------------------------#
function m~ConfFilePropChild~Get
(	[object]$iRawVal
,	[String]$iMode
)
{
	
}
