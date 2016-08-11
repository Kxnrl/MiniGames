#if defined _zcore_mysql_included
 #endinput
#endif
#define _zcore_mysql_included

// Don't use this natives directly, use the stocks
native int ZCore_Mysql_RequestDatabase ( char[] name );
native Database ZCore_Mysql_GetConnection ( int index );

// Forwards
forward void ZCore_Mysql_OnDatabaseConnected ( int index, char[] config, Database connection_handle);
forward void ZCore_Mysql_OnDatabaseError ( int index, char[] config, char[] error );

public void __pl_zcore_mysql__SetNTVOptional() 
{
	MarkNativeAsOptional("ZCore_Mysql_RequestDatabase");
	MarkNativeAsOptional("ZCore_Mysql_GetConnection");
}

int g_iSQL = -1;
Database g_hSQL = null;

stock bool ZCore_Mysql_Connect(char config_name[64], bool force = false)
{
	if(!force && g_hSQL != null)
		return true;
	
	g_iSQL = ZCore_Mysql_RequestDatabase(config_name);
	g_hSQL = ZCore_Mysql_GetConnection(g_iSQL);

	return g_hSQL != null;
}