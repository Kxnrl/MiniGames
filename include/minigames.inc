#if defined _MiniGames_INCLUDED
    #endinput
#endif

#define _MiniGames_INCLUDED

#define COMMITS  <commit_counts>
#define MYBUILD "<commit_counts>"

public SharedPlugin __pl_MiniGames = 
{
	name = "MiniGames",
	file = "minigames.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

enum struct team_t
{
	int client;
	int currentTeam;
	int nextTeam;
}

native int MG_SetSpecHudContent(int client, const char[] vformat, any ...);
native int MG_GetTotalScores(int client);
native int MG_GetTotalKills(int client);
native int MG_GetTotalAssists(int client);
native int MG_GetTotalDeaths(int client);
native int MG_GetTotalHeadshots(int client);
native int MG_GetTotalKnifeKills(int client);
native int MG_GetTotalTaserKills(int client);
native int MG_GetRanks(int client);
native int MG_GetLevel(int client);

native void MG_IgnoreRoundStats();

forward bool MG_OnRandomTeam(int       terrorists, int       counterTerrorists, ArrayList array_players); // team_t;
forward bool MG_OnVacEnabled(int Alive_terrorists, int Alive_counterTerrorists);
forward void MG_OnScoreIncreased(int client, int score);

forward Action MG_OnPublicMessages(int client, bool disconnected, char buffer[256]);
forward Action MG_OnRenderModelColor(int client);