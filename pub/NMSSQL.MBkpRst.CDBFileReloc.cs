namespace NMSSQL.MBkpRst
{	
    public enum EDBFileType
    {   Rows
    ,   TLog
    ,   FileStream

    ,   L = TLog
    ,   D = Rows
    ,   F = Rows
    ,   S = FileStream
    }

    public sealed class CDBFileReloc
    {   public System.Management.Automation.ScriptBlock PathTmpl;
		public System.Collections.IList ALogicNamePtrn;
        public System.Collections.IList APhysNamePtrn;
        public System.Collections.IDictionary DTypeRelStr;
    }
}