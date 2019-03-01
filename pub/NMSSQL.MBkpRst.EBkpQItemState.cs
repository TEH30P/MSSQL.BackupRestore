namespace NMSSQL.MBkpRst
{	
    public enum EBkpQItemState
    {   Nil
    ,   NewItem 
    ,   Active  
    ,   Finished
    ,   Warning
    ,   Error
         
    ,   New = NewItem
    ,   Act = Active
    ,   Fin = Finished
    ,   Wrn = Warning
    ,   Err = Error
    };
}