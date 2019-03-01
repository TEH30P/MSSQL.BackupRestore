namespace NMSSQL.MBkpRst
{	public enum EBkpJobType
    {   FullFlag = 0x20
	,	DiffFlag = 0x10
	
	,	TLog     = 0x00
    ,	Data     = 0x01

	,	DBCode   = 0x01
	,	FGCode   = 0x02
	,	FlCode   = 0x03
	,	CodeMask = 0x0F

	,	DBFull = DBCode | FullFlag
    ,   DBDiff = DBCode | DiffFlag
    ,   FGFull = FGCode | FullFlag
    ,   FGDiff = FGCode | DiffFlag
    ,   FlFull = FlCode | FullFlag
    ,   FlDiff = FlCode | DiffFlag

	,	DBF = DBFull
    ,   DBD = DBDiff
    ,   FGF = FGFull
    ,   FGD = FGDiff
    ,   FlF = FlFull
    ,   FlD = FlDiff
    };
}