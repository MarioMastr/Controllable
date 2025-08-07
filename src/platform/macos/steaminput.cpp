#include "steaminput.hpp"
#include <Geode/Geode.hpp>
#include <dlfcn.h>

SteamInput_t _SteamInput = nullptr;
Init_t _Init = nullptr;
RunFrame_t _RunFrame = nullptr;
GetConnectedControllers_t _GetConnectedControllers = nullptr;
GetInputTypeForHandle_t _GetInputTypeForHandle = nullptr;
ShowBindingPanel_t _ShowBindingPanel = nullptr;

$execute {
    void *steam = dlopen(NULL, RTLD_NOW);

    _SteamInput = (SteamInput_t)dlsym(steam, "SteamAPI_SteamInput_v006");
    _Init = (Init_t)dlsym(steam, "SteamAPI_ISteamInput_Init");
    _RunFrame = (RunFrame_t)dlsym(steam, "SteamAPI_ISteamInput_RunFrame");
    _GetConnectedControllers = (GetConnectedControllers_t)dlsym(steam, "SteamAPI_ISteamInput_GetConnectedControllers");
    _GetInputTypeForHandle = (GetInputTypeForHandle_t)dlsym(steam, "SteamAPI_ISteamInput_GetInputTypeForHandle");
    _ShowBindingPanel = (ShowBindingPanel_t)dlsym(steam, "SteamAPI_ISteamInput_ShowBindingPanel");

    if (!_Init) {
        geode::log::error("no steam? pirata?");
    }

    if (steam)
        dlclose(steam);
}
