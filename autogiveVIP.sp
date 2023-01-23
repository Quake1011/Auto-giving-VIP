#include <vip_core>

#define PLUGIN_NAME 	"AutoGiveVIP"
#define PLUGIN_VERSION 	"0.0.2"

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
Handle hNewTimer[MAXPLAYERS+1];

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
		SQL_FormatQuery(db, sQuery, sizeof(sQuery), "INSERT INTO `autogivevip` (`status`, `steam`) VALUES ('off', '%s')", auth);
		SQL_FastQuery(db, sQuery);
		hNewTimer[client] = CreateTimer(5.0, TimerAUTOGIVE, client);	
	}
}

public void OnClientDisconnect(int client)
{
	if(hNewTimer[client] != INVALID_HANDLE)
	{
		KillTimer(hNewTimer[client]);
		hNewTimer[client] = null;
	}
}

public Action TimerAUTOGIVE(Handle hTimer, int client)
{
	char sQuery[256], auth[22];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	SQL_FormatQuery(db, sQuery, sizeof(sQuery), "SELECT * FROM `autogivevip` WHERE steam = '%s'", auth);
	db.Query(SQLCheck, sQuery, client, DBPrio_High);
	return Plugin_Handled;
}

public void SQLCheck(Database hdb, DBResultSet results, const char[] error, int client)
{
	char tmp[22], sQuery[256];
	if(!error[0] && results != INVALID_HANDLE)
	{	
		if(results.HasResults && results.RowCount > 0)
		{	
			if(results.FetchRow())
			{	
				if(results.FetchString(0, tmp, sizeof(tmp)))
				{	
					if(StrEqual(tmp, "off"))
					{
						char temp[256];
						if(!VIP_GetClientVIPGroup(client, temp, sizeof(temp))) VIP_GiveClientVIP(0, client, 1209600, sGroup, true);
						results.FetchString(1, tmp, sizeof(tmp));
						SQL_FormatQuery(db, sQuery, sizeof(sQuery), "UPDATE `autogivevip` SET `status` = 'on' WHERE steam = '%s'", tmp);
						SQL_FastQuery(db, sQuery);
					}
				}
			}
		}
	}					
}

public void SQLConnectCB(Database hdb, const char[] error, any data)
{
	if(!error[0] && hdb != INVALID_HANDLE) 
	{
		db = hdb;
		LogMessage("AutoGive successfully connected");
		char sQuery[512];
		SQL_FormatQuery(db, sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `autogivevip` (\
													`status` VARCHAR(20),\
													`steam`	VARCHAR(22) PRIMARY KEY)");
		db.Query(SQLCreateTable, sQuery, _, DBPrio_High);
	}
}

public void SQLCreateTable(Database hdb, DBResultSet results, const char[] error, any data)
{
	if(!error[0] && hdb != INVALID_HANDLE) LogMessage("Table AutoGiveVip successfully created or already exists");
}
