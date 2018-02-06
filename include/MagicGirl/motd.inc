/******************************************************************/
/*                                                                */
/*                  MagicGirl.NET Motd Extended                   */
/*                                                                */
/*                                                                */
/*  File:          motd.inc                                       */
/*  Description:   Interconnector of Game and Forum.              */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  MagicGirl.NET Dev Team                    */
/*  2017/01/23 19:41:45                                           */
/*                                                                */
/*  This code is licensed under the Apache License.               */
/*                                                                */
/******************************************************************/

#if defined _MagicGirl_MOTD_Include_
    #endinput
#endif

#define _MagicGirl_MOTD_Include_

native bool MG_Motd_ShowNormalMotd(int client, const char[] url);
native bool MG_Motd_ShowHiddenMotd(int client, const char[] url);
native void MG_Motd_RemoveMotd(int client);

public SharedPlugin __pl_mg_motd =
{
	name = "mg-motd",
	file = "mg-motd.smx",
#if !defined REQUIRE_PLUGIN
    required = 0
#else
    required = 1
#endif
}; 