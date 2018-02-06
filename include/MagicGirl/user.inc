/******************************************************************/
/*                                                                */
/*                  MagicGirl.NET User Manager                    */
/*                                                                */
/*                                                                */
/*  File:          user.inc                                       */
/*  Description:   Interconnector of Game and Forum.              */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  MagicGirl.NET Dev Team                    */
/*  2017/01/04 13:51:42                                           */
/*                                                                */
/*  This code is licensed under the Apache License.               */
/*                                                                */
/******************************************************************/

#if defined _MagicGirl_User_Manager_Include_
    #endinput
#endif

#define _MagicGirl_User_Manager_Include_

enum Authentication
{
    Spt,  //Supporter
    Vip,  //VIP
    Ctb,  //Contributor
    Opt,  //Operator
    Adm,  //Administrator
    Own   //Owner
}


forward void OnClientAuthChecked(int client, bool Spt, bool Vip, bool Ctb, bool Opt, bool Adm, bool Own);
forward void OnClientDataChecked(int client, int UserIdentity);
native int  MG_Users_UserIdentity(int client);
native bool MG_Users_IsAuthorized(int client, Authentication auth);
native void MG_Users_BanClient(int admin,  int target, int banType, int banLength, const char[] banReason);
native void MG_Users_BanIdentity(int admin, const char[] steamIdentity, int banType, int banLength, const char[] banReason);

public SharedPlugin __pl_mg_user =
{
	name = "mg-user",
	file = "mg-user.smx",
#if !defined REQUIRE_PLUGIN
    required = 0
#else
    required = 1
#endif
};