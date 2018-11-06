# Total size of files. 0 if it not exists.
function m~BkpFile~SizeGet
(	[String[]]$iaBkpFilePath)
{	
	[Int64]$Ret = 0;
				
	foreach($BkpFileIt in $iaBkpFilePath | % {[IO.FileInfo]::new($_)})
	{	if (-not $BkpFileIt.Exists)
		{	return 0}

		$Ret += $BkpFileIt.Length;
	}

	return $Ret;
}