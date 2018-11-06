# base-32 numbers.
#                          00000000001111111111222222222233
#                          01234567890123456789012345678901
[String]${m~DHex~Digit} = '0123456789ABCDEFGHJKMNPRSTUVWXYZ';
#--------------------------------#
function m~DHex~ToInt
(	[String]$iValue)
{	[Numerics.BigInteger]$Ret = 0;
	
	foreach($ChDigit in $iValue.GetEnumerator())
	{	[Int32]$Digit = ${m~DHex~Digit}.IndexOf([Char]::ToUpper($ChDigit));

		if ($Digit -lt 0)
		{	throw [System.FormatException]::new('Input DHEX string was not in a correct format.')}

		$Ret = ($Ret -shl 5) + $Digit;
	}

	return $Ret;
}
#--------------------------------#
function m~DHex~ToString
(	[Numerics.BigInteger]$iValue)
{	[String]$Ret = '';
	
    if ($iValue.Sign -lt 0)
    {	[Numerics.BigInteger]$i = -bnot $iValue;

		while ($i -ge 32)
		{	$Ret = ${m~DHex~Digit}.Substring(-bnot [Int32]($i % 32) -band 0x1F, 1) + $Ret;
			$i = $i -shr 5;
		}
		
		$Ret = ${m~DHex~Digit}.Substring(-bnot [Int32]($i) -band 0x1F, 1) + $Ret;
	}
	else 
	{	[Numerics.BigInteger]$i = $iValue;
		
		while ($i -ge 32)
		{	$Ret = ${m~DHex~Digit}.Substring([Int32]($i % 32), 1) + $Ret;
			$i = $i -shr 5;
		}
		
		$Ret = ${m~DHex~Digit}.Substring([Int32]($i), 1) + $Ret;
	}

	return $Ret;
}
##################################
