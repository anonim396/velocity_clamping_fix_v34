#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "velocity_clamping_fix",
	author = "",
	description = "",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart()
{
	ConVar convar = FindConVar("sv_sendtables");
	convar.AddChangeHook(SendTablesCvar_Hook);
	convar.BoolValue = true;

	GameData gamedata = new GameData("velocity_clamping_fix");
	if(gamedata == null)
		SetFailState("Failed to open gamedata file \"velocity_clamping_fix.txt\".");
	
	Address PlayerFlagBitsAddr = gamedata.GetAddress("PLAYER_FLAG_BITS");
	if(PlayerFlagBitsAddr == Address_Null)
		SetFailState("Failed to retrieve \"PLAYER_FLAG_BITS\" address.");
	
	Address FlagsAddr = gamedata.GetAddress("m_fFlags");
	if(FlagsAddr == Address_Null)
		SetFailState("Failed to retrieve \"m_fFlags\" address.");
	
	int m_nBits = gamedata.GetOffset("m_nBits");
	if(m_nBits == -1)
		SetFailState("Failed to retrieve \"m_nBits\" offset.");

	PatchSendProp(gamedata, "m_vecBaseVelocity", (1 << 2));
	PatchSendProp(gamedata, "m_vecVelocity[0]", 3076);
	PatchSendProp(gamedata, "m_vecVelocity[1]", 3076);
	PatchSendProp(gamedata, "m_vecVelocity[2]", 3076);

	if(!SendTablePatch(gamedata))
		SetFailState("SendTable Patch Failed");
	
	// PLAYER_FLAG_BITS patch
	StoreToAddress(PlayerFlagBitsAddr, 0xFFFFFFFF, NumberType_Int32);

	FlagsAddr = view_as<Address>(LoadFromAddress(FlagsAddr, NumberType_Int32));
	StoreToAddress(FlagsAddr + view_as<Address>(m_nBits), 32, NumberType_Int32);

	gamedata.Close();
}

public void SendTablesCvar_Hook(ConVar convar, const char[] oldValue, const char[] newValue)
{
	convar.BoolValue = true;
}

void PatchSendProp(GameData gamedata, const char[] szName, int flags)
{
	Address pointer = gamedata.GetAddress(szName);
	if(pointer == Address_Null)
		SetFailState("Failed to retrieve \"%s\" address.", szName);
	
	int m_nBits = gamedata.GetOffset("m_nBits");
	if(m_nBits == -1)
		SetFailState("Failed to retrieve \"m_nBits\" offset.");
	
	int m_fLowValue = gamedata.GetOffset("m_fLowValue");
	if(m_fLowValue == -1)
		SetFailState("Failed to retrieve \"m_fLowValue\" offset.");
	
	int m_fHighValue = gamedata.GetOffset("m_fHighValue");
	if(m_fHighValue == -1)
		SetFailState("Failed to retrieve \"m_fHighValue\" offset.");
	
	int m_fHighLowMul = gamedata.GetOffset("m_fHighLowMul");
	if(m_fHighLowMul == -1)
		SetFailState("Failed to retrieve \"m_fHighLowMul\" offset.");
	
	int m_Flags = gamedata.GetOffset("m_Flags");
	if(m_Flags == -1)
		SetFailState("Failed to retrieve \"m_Flags\" offset.");

	pointer = view_as<Address>(LoadFromAddress(pointer, NumberType_Int32));

	StoreToAddress(pointer + view_as<Address>(m_nBits), 0, NumberType_Int32);
	StoreToAddress(pointer + view_as<Address>(m_fLowValue), 0, NumberType_Int32);
	StoreToAddress(pointer + view_as<Address>(m_fHighValue), 0x3F800000, NumberType_Int32);
	StoreToAddress(pointer + view_as<Address>(m_fHighLowMul), 0x4F800000, NumberType_Int32);
	StoreToAddress(pointer + view_as<Address>(m_Flags), flags, NumberType_Int32);
}

bool SendTablePatch(GameData gamedata)
{
	Address patchAddr = gamedata.GetAddress("g_SendTableCRC");
	Address offsetAddr1 = view_as<Address>(gamedata.GetOffset("g_SendTableCRCOffset_1"));
	Address offsetAddr2 = view_as<Address>(gamedata.GetOffset("g_SendTableCRCOffset_2"));
	if (patchAddr == Address_Null || offsetAddr2 == Address_Null)
	{
		return false;
	}
	
	if (offsetAddr1 != Address_Null)
	{
		patchAddr += view_as<Address>(1);
		patchAddr = patchAddr + view_as<Address>(LoadFromAddress(patchAddr, NumberType_Int32)) + view_as<Address>(4);
	}
	patchAddr = view_as<Address>(LoadFromAddress(patchAddr + offsetAddr2, NumberType_Int32));
	StoreToAddress(patchAddr, 1337, NumberType_Int32);
	return true;
}
