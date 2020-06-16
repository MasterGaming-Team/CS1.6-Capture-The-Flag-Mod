#include <amxconst>
#include <amxmisc>
#include <engine>

public plugin_precache()
{
    new lEnt = create_entity("info_map_parameters")

    DispatchKeyValue(lEnt, "buying", "3")
    DispatchSpawn(lEnt)
}

public pfn_keyvalue(ent)
{
    new lClassName[20], lPlaceHolder[2]

    copy_keyvalue(lClassName, charsmax(lClassName), lPlaceHolder, charsmax(lPlaceHolder), lPlaceHolder, charsmax(lPlaceHolder))

    if(equal(lClassName, "info_map_parameters"))
    {
        remove_entity(ent)
        return PLUGIN_HANDLED
    }

    return PLUGIN_CONTINUE
}