/******************************************************************/
/*                                                                */
/*                  MagicGirl.NET User Manager                    */
/*                                                                */
/*                                                                */
/*  File:          stats.inc                                      */
/*  Description:   Interconnector of Game and Forum.              */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  MagicGirl.NET Dev Team                    */
/*  2017/01/21 19:14:57                                           */
/*                                                                */
/*  This code is licensed under the Apache License.               */
/*                                                                */
/******************************************************************/

#if defined _MagicGirl_Stats_Include_
    #endinput
#endif

#define _MagicGirl_Stats_Include_

native int MG_Stats_TodayOnlineTime(int client);
native int MG_Stats_TotalOnlineTime(int client);
native int MG_Stats_ObserveOnlineTime(int client);
native int MG_Stats_PlayOnlineTime(int client);
native int MG_Stats_Vitality(int client);

public SharedPlugin __pl_mg_stats =
{
	name = "mg-stats",
	file = "mg-stats.smx",
#if !defined REQUIRE_PLUGIN
    required = 0
#else
    required = 1
#endif
};