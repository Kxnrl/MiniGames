/* Zombie:Reloaded additional native tools
*
* Copyright © 2013, FrozDark
*
* This file is provided as is (no warranties).
*
*/

/**
 * Gets client class section name in the config
 *
 * @param client		Client index.
 * @param buffer		Buffer to store the class section name in.
 * @param maxlen		Max length to store.
 *
 * @return				Number of bytes written to the buffer.
 * @error				If the client is not in game or invalid.
 */
native ZRT_GetClientClassSectionName(client, String:buffer[], maxlen);

/**
 * Gets attribute string of the player's class
 *
 * @param client		Client index.
 * @param attrib		Attribute name.
 * @param buffer		Buffer to store the attribute string in.
 * @param maxlen		Max length to store.
 * @param defvalue		Optional default value to use if the attribute is not found.
 *
 * @return				Number of bytes written to the buffer.
 * @error				If the client is not in game or invalid.
 */
native ZRT_GetClientAttributeString(client, const String:attrib[], String:buffer[], maxlen, const String:defvalue[] = "");

/**
 * Gets attribute numeric value of the player's class
 *
 * @param client		Client index.
 * @param attrib		Attribute name.
 * @param defvalue		Optional default value to use if the attribute is not found.
 *
 * @return				Retrieves the numeric value.
 * @error				If the client is not in game or invalid.
 */
native ZRT_GetClientAttributeValue(client, const String:attrib[], defvalue = 0);

/**
 * Gets attribute floating value of the player's class
 *
 * @param client		Client index.
 * @param attrib		Attribute name.
 * @param defvalue		Optional default value to use if the attribute is not found.
 *
 * @return				Retrieves the floating value.
 * @error				If the client is not in game or invalid.
 */
native Float:ZRT_GetClientAttributeValueFloat(client, const String:attrib[], Float:defvalue = 0.0);

/**
 * Whether the player has attribute
 *
 * @param client		Client index.
 * @param attrib		Attribute name.
 *
 * @return				True on success, false otherwise.
 * @error				If the client is not in game or invalid.
 */
native bool:ZRT_PlayerHasAttribute(client, const String:attrib[]);

/**
 * Whether the round is active
 *
 * @noparams
 *
 * @return				True on round active, false otherwise
 * @noerror
 */
native bool:ZRT_IsRoundActive();




/*----------------------------------
***********************************
**  Don't edit below this line!  **
***********************************
-----------------------------------*/

public SharedPlugin:__pl_zr_tools = 
{
	name = "zr_tools",
	file = "zr_tools.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_zr_tools_SetNTVOptional()
{
	MarkNativeAsOptional("ZRT_GetClientClassSectionName");
	MarkNativeAsOptional("ZRT_GetClientAttributeString");
	MarkNativeAsOptional("ZRT_GetClientAttributeValue");
	MarkNativeAsOptional("ZRT_GetClientAttributeValueFloat");
	MarkNativeAsOptional("ZRT_PlayerHasAttribute");
	MarkNativeAsOptional("ZRT_IsRoundActive");
}
#endif