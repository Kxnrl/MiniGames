#if defined _zcore_voice_included
 #endinput
#endif
#define _zcore_voice_included

forward Action ZCore_Voice_OnListenOverride(int receiver, int sender, bool listen, int immunity);

native bool ZCore_Voice_SetListenOverride(int receiver, int sender, bool listen, int immunity);

public void __pl_zcore_voice_SetNTVOptional() 
{
	MarkNativeAsOptional("ZCore_Voice_SetListenOverride");
}