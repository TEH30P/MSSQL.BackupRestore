#--------------------------------#
# Data backup root path
# Generate data backup dir path
function m~BkpDirPathRoot~Data~Get
(	[Uri[]]$iaRepoPath)
{	foreach ($RepoIt in $iaRepoPath)
	{	if ($RepoIt.Scheme -ne [Uri]::UriSchemeFile)
		{	throw [InvalidOperationException]::new("Invalid repo path. Only 'UriSchemeFile' scheme supported, got $($RepoIt.Scheme).")}
		
		[IO.Path]::Combine($RepoIt.LocalPath, 'data'); #<--
	}
}
#--------------------------------#
# TLog backup root path
# Generate data backup dir path
function m~BkpDirPathRoot~TLog~Get
(	[Uri[]]$iaRepoPath)
{	foreach ($RepoIt in $iaRepoPath)
	{	if ($RepoIt.Scheme -ne [Uri]::UriSchemeFile)
		{	throw [InvalidOperationException]::new("Invalid repo path. Only 'UriSchemeFile' scheme supported, got $($RepoIt.Scheme).")}
		
		[IO.Path]::Combine($RepoIt.LocalPath, 'tlog'); #<--
	}
}
#--------------------------------#
# Generate data backup dir path
function m~BkpDirPath~Data~Gen
(	[String]$iSrvInst
,	[String]$iDBName
,	[Uri[]]$iaRepoPath
)
{	m~BkpDirPathRoot~Data~Get $iaRepoPath | % {"$_\$(m~FSName~SQLSrvInst~Convert $iSrvInst)\$(m~FSName~SQLObjName~Parse $iDBName)"}}
#--------------------------------#
# Generate tlog backup dir path
function m~BkpDirPath~TLog~Gen
(	[String]$iSrvInst
,	[String]$iDBName
,	[Uri[]]$iaRepoPath
)
{	m~BkpDirPathRoot~TLog~Get $iaRepoPath | % {"$_\$(m~FSName~SQLSrvInst~Convert $iSrvInst)\$(m~FSName~SQLObjName~Parse $iDBName)"}}
