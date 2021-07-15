#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


enum SolidFlags_t
{
    FSOLID_CUSTOMRAYTEST        = 0x0001,    // Ignore solid type + always call into the entity for ray tests
    FSOLID_CUSTOMBOXTEST        = 0x0002,    // Ignore solid type + always call into the entity for swept box tests
    FSOLID_NOT_SOLID            = 0x0004,    // Are we currently not solid?
    FSOLID_TRIGGER              = 0x0008,    // This is something may be collideable but fires touch functions
                                             // even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
    FSOLID_NOT_STANDABLE        = 0x0010,    // You can't stand on this
    FSOLID_VOLUME_CONTENTS      = 0x0020,    // Contains volumetric contents (like water)
    FSOLID_FORCE_WORLD_ALIGNED  = 0x0040,    // Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
    FSOLID_USE_TRIGGER_BOUNDS   = 0x0080,    // Uses a special trigger bounds separate from the normal OBB
    FSOLID_ROOT_PARENT_ALIGNED  = 0x0100,    // Collisions are defined in root parent's local coordinate space
    FSOLID_TRIGGER_TOUCH_DEBRIS = 0x0200,    // This trigger will touch debris objects

    FSOLID_MAX_BITS             = 10
};


public void OnPluginStart()
{
    RegAdminCmd("sm_test", Command_Test, ADMFLAG_ROOT);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, Event_TrackAttack);
}

public Action Event_TrackAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    PrintToChatAll("Hit %N by %d<%d> => %d | %d | %d <%.1f>", victim, attacker, inflictor, 
                    damagetype, weapon, damagecustom, damage);
    return Plugin_Continue;
}

public Action Command_Test(int client, int args)
{
    //CreatePanel(client);
    return Plugin_Handled;
}

/*
void CreatePanel(int client)
{
    int entity = CreateEntityByName("vgui_world_text_panel");

    char buffer[64];
    FormatEx(buffer, 64, "<%N>", client);

    float vVec[3];

    DispatchKeyValue(entity, "displaytext", buffer);
    DispatchKeyValue(entity, "font", "DefaultLarge");
    DispatchKeyValue(entity, "angles", "0 0 0");
    DispatchKeyValue(entity, "height", "256");
    DispatchKeyValue(entity, "width", "256");
    DispatchKeyValue(entity, "textcolor", "255 255 255");
    DispatchKeyValue(entity, "textpanelwidth", "256");

    GetClientAbsOrigin(client, vVec); vVec[2] += 72.0;
    TeleportEntity(entity, vVec, NULL_VECTOR, NULL_VECTOR);

    DispatchSpawn(entity);
}
*/