#include <vip_core>

#define PLUGIN_NAME 	"AutoGiveVIP"
#define PLUGIN_VERSION 	"0.0.1"

public Plugin myinfo = 
{ 
	name = PLUGIN_NAME, 
	author = "Quake1011",
	description = "Auto giving VIP for new players", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/Quake1011" 
};

ConVar cvGroup;
Database db;
char sGroup[256];

public void OnPluginStart()
{
	Database.Connect(SQLConnectCB, "autogivevip");
	
	HookConVarChange(cvGroup = CreateConVar("sm_autogive_group", "", "Группа для авто-выдачи новому игроку"), OnHookCV);
	cvGroup.GetString(sGroup, sizeof(sGroup));
	
	AutoExecConfig(true, "AutoGiveVIP");
}

public void OnHookCV(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar != INVALID_HANDLE && convar == cvGroup) convar.GetString(sGroup, sizeof(sGroup));
}

public void OnClientPostAdminCheck(int client)
{
	char sQuery[256], auth[22];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	if(db != INVALID_HANDLE)
	{
		SQL_FormatQuery(db, sQuery, sizeof(sQuery), "INSERT INTO `autogivevip` (`status`, `steam`) VALUES ('%i', '%s')", GetTime(), auth);
		SQL_FastQuery(db, sQuery);
		
		GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
		SQL_FormatQuery(db, sQuery, sizeof(sQuery), "SELECT * FROM autogivevip WHERE steam = '%s'", auth);
		db.Query(SQLCheck, sQuery, client, DBPrio_High);		
	}
}

public void SQLCheck(Database hdb, DBResultSet results, const char[] error, int client)
{
	if(!error[0] && results != INVALID_HANDLE)
		if(results.HasResults && results.RowCount > 0)
			if(results.FetchRow())
				if(results.FetchInt(0) == GetTime())
					VIP_GiveClientVIP(0, client, 1209600, sGroup, true);							
}

public void SQLConnectCB(Database hdb, const char[] error, any data)
{
	if(!error[0] && hdb != INVALID_HANDLE) 
	{
		db = hdb;
		LogMessage("AutoGive successfully connected");
		char sQuery[512];
		SQL_FormatQuery(db, sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `autogivevip` (\
													`status` INTEGER(20),\
													`steam`	VARCHAR(22) PRIMARY KEY)");
		db.Query(SQLCreateTable, sQuery, _, DBPrio_High);
	}
}

public void SQLCreateTable(Database hdb, DBResultSet results, const char[] error, any data)
{
	if(!error[0] && hdb != INVALID_HANDLE) LogMessage("Table AutoGiveVip successfully created or already exists");
}