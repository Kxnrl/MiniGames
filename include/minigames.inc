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

