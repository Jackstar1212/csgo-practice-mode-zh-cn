#define REPLAY_NAME_LENGTH 128
#define REPLAY_ROLE_DESCRIPTION_LENGTH 256
#define REPLAY_ID_LENGTH 16
#define MAX_REPLAY_CLIENTS 5
#define DEFAULT_REPLAY_NAME "unnamed - use .namereplay on me!"

// Ideas:
// 1. ADD A WARNING WHEN YOU NADE TOO EARLY IN THE REPLAY!
// 2. Does practicemode-saved nade data respect cancellation?

// If any data has been changed since load, this should be set.
// All Set* data methods should set this to true.
bool g_UpdatedReplayKv = false;

bool g_RecordingFullReplay = false;
// TODO: find when to reset g_RecordingFullReplayClient
int g_RecordingFullReplayClient = -1;

bool g_StopBotSignal[MAXPLAYERS + 1];

float g_CurrentRecordingStartTime[MAXPLAYERS + 1];

int g_CurrentEditingRole[MAXPLAYERS + 1];
char g_ReplayId[MAXPLAYERS + 1][REPLAY_ID_LENGTH];
int g_ReplayBotClients[MAX_REPLAY_CLIENTS];
bool g_ReplayPlayRoundTimer[MAXPLAYERS + 1];  // TODO: add a client cookie for this

int g_CurrentReplayNadeIndex[MAXPLAYERS + 1];
ArrayList g_NadeReplayData[MAXPLAYERS + 1];

// TODO: cvar/setting?
bool g_BotReplayChickenMode = false;

public void BotReplay_MapStart() {
  g_BotInit = false;
  delete g_ReplaysKv;
  g_ReplaysKv = new KeyValues("Replays");

  char map[PLATFORM_MAX_PATH];
  GetCleanMapName(map, sizeof(map));

  char replayFile[PLATFORM_MAX_PATH + 1];
  BuildPath(Path_SM, replayFile, sizeof(replayFile), "data/practicemode/replays/%s.cfg", map);
  g_ReplaysKv.ImportFromFile(replayFile);

  for (int i = 0; i <= MaxClients; i++) {
    delete g_NadeReplayData[i];
    g_NadeReplayData[i] = new ArrayList(14);
    g_ReplayPlayRoundTimer[i] = false;
  }
}

public void BotReplay_MapEnd() {
  MaybeWriteNewReplayData();
  GarbageCollectReplays();
}

public void Replays_OnThrowGrenade(int client, int entity, GrenadeType grenadeType, const float origin[3],
                            const float velocity[3]) {
  if (!g_BotMimicLoaded) {
    return;
  }

  if (g_CurrentEditingRole[client] >= 0 && BotMimic_IsPlayerRecording(client)) {
    float delay = GetGameTime() - g_CurrentRecordingStartTime[client];
    float personOrigin[3];
    float personAngles[3];
    GetClientAbsOrigin(client, personOrigin);
    GetClientEyeAngles(client, personAngles);
    AddReplayNade(client, grenadeType, delay, personOrigin, personAngles, origin, velocity);
    if (delay < 1.27) {  // Takes 1.265625s to pull out a grenade.
      PM_Message(
          client,
          "{LIGHT_RED}警告: {NORMAL}开始录制时立即投掷投掷物可能无法正确保存投掷物。 {NORMAL}为了更好的效果，{LIGHT_RED}请在开始录制时稍等一会儿 {NORMAL}再开始投掷投掷物");
    }
  }

  if (BotMimic_IsPlayerMimicing(client)) {
    int index = g_CurrentReplayNadeIndex[client];
    int length = g_NadeReplayData[client].Length;
    if (index < length) {
      float delay = 0.0;
      GrenadeType type;
      float personOrigin[3];
      float personAngles[3];
      float nadeOrigin[3];
      float nadeVelocity[3];
      GetReplayNade(client, index, type, delay, personOrigin, personAngles, nadeOrigin,
                    nadeVelocity);
      TeleportEntity(entity, nadeOrigin, NULL_VECTOR, nadeVelocity);
      g_CurrentReplayNadeIndex[client]++;
    }
  }
}

public Action Timer_GetBots(Handle timer) {
  g_BotInit = true;

  for (int i = 0; i < MAX_REPLAY_CLIENTS; i++) {
    char name[MAX_NAME_LENGTH];
    Format(name, sizeof(name), "Replay Bot %d", i + 1);
    if (!IsReplayBot(g_ReplayBotClients[i])) {
      g_ReplayBotClients[i] = GetLiveBot(name);
    }
  }

  return Plugin_Handled;
}

void InitReplayFunctions() {
  ResetData();
  for (int i = 0; i < MAX_REPLAY_CLIENTS; i++) {
    g_ReplayBotClients[i] = -1;
  }

  GetReplayBots();

  g_BotInit = true;
  g_InBotReplayMode = true;
  g_RecordingFullReplay = false;

  // Settings we need to have the mode work
  ChangeSettingById("respawning", false);
  ServerCommand("mp_death_drop_gun 1");

  PM_MessageToAll("启动回放模式");
}

public void ExitReplayMode() {
  ServerCommand("bot_kick");
  g_BotInit = false;
  g_InBotReplayMode = false;
  g_RecordingFullReplay = false;
  ChangeSettingById("respawning", true);
  ServerCommand("mp_death_drop_gun 0");

  PM_MessageToAll("退出回放模式");
}

public void GetReplayBots() {
  ServerCommand("bot_quota_mode normal");
  for (int i = 0; i < MAX_REPLAY_CLIENTS; i++) {
    if (!IsReplayBot(i)) {
      ServerCommand("bot_add");
    }
  }

  CreateTimer(0.1, Timer_GetBots);
}

public Action Command_Replay(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  if (!g_BotMimicLoaded) {
    PM_Message(client, "你需要加载 botmimic 插件来使用回放功能");
    return Plugin_Handled;
  }

  if (!g_CSUtilsLoaded) {
    PM_Message(client, "你需要加载 csutils 插件来使用回放功能");
    return Plugin_Handled;
  }

  if (!g_BotInit) {
    InitReplayFunctions();
  }

  if (args >= 1) {
    char arg[128];
    GetCmdArg(1, arg, sizeof(arg));
    if (ReplayExists(arg)) {
      strcopy(g_ReplayId[client], REPLAY_ID_LENGTH, arg);
      GiveReplayEditorMenu(client);
    } else {
      PM_Message(client, "没有 id 为 %s 的回放存在", arg);
    }

    return Plugin_Handled;
  }

  GiveReplayMenuInContext(client);
  return Plugin_Handled;
}

void GiveReplayMenuInContext(int client) {
  if (HasActiveReplay(client)) {
    if (g_CurrentEditingRole[client] >= 0) {
      // Replay-role specific menu.
      GiveReplayRoleMenu(client, g_CurrentEditingRole[client]);
    } else {
      // Replay-specific menu.
      GiveReplayEditorMenu(client);
    }
  } else {
    // All replays menu.
    GiveMainReplaysMenu(client);
  }
}

public Action Command_Replays(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  if (!g_BotMimicLoaded) {
    PM_Message(client, "你需要加载 botmimic 插件来使用回放功能");
    return Plugin_Handled;
  }

  if (!g_CSUtilsLoaded) {
    PM_Message(client, "你需要加载 csutils 插件来使用回放功能");
    return Plugin_Handled;
  }

  if (!g_BotInit) {
    InitReplayFunctions();
  }

  GiveMainReplaysMenu(client);
  return Plugin_Handled;
}

public Action Command_NameReplay(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  if (!g_InBotReplayMode) {
    PM_Message(client, "您当前未处于BOT回放模式: 请先使用 .replays 命令");
    return Plugin_Handled;
  }

  if (!HasActiveReplay(client)) {
    return Plugin_Handled;
  }

  char buffer[REPLAY_NAME_LENGTH];
  GetCmdArgString(buffer, sizeof(buffer));
  if (StrEqual(buffer, "")) {
    PM_Message(client, "您还没有命名。 使用: .namereplay <name> 来命名");
  } else {
    PM_Message(client, "已保存回放名");
    SetReplayName(g_ReplayId[client], buffer);
  }
  return Plugin_Handled;
}

public Action Command_NameRole(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  if (!g_InBotReplayMode) {
    PM_Message(client, "您当前未处于BOT回放模式: 请先使用 .replays 命令");
    return Plugin_Handled;
  }

  if (!HasActiveReplay(client)) {
    return Plugin_Handled;
  }

  if (g_CurrentEditingRole[client] < 0) {
    return Plugin_Handled;
  }

  char buffer[REPLAY_NAME_LENGTH];
  GetCmdArgString(buffer, sizeof(buffer));
  if (StrEqual(buffer, "")) {
    PM_Message(client, "您还没有命名。 使用: .namerole <name> 来命名");
  } else {
    PM_Message(client, "已保存角色 %d 的名字", g_CurrentEditingRole[client] + 1);
    SetRoleName(g_ReplayId[client], g_CurrentEditingRole[client], buffer);
  }
  return Plugin_Handled;
}

public Action Command_PlayRecording(int client, int args) {
  if (!g_InPracticeMode) {
    return Plugin_Handled;
  }

  if (!g_InBotReplayMode) {
    PM_Message(client, "您当前未处于BOT回放模式: 请先使用 .replays 命令");
    return Plugin_Handled;
  }

  if (IsReplayPlaying()) {
    PM_Message(client, "请先等待当前回放完成");
    return Plugin_Handled;
  }

  if (args < 1) {
    PM_Message(client, "用法: .play <id> [role]");
    return Plugin_Handled;
  }

  GetCmdArg(1, g_ReplayId[client], REPLAY_ID_LENGTH);
  if (!ReplayExists(g_ReplayId[client])) {
    PM_Message(client, "没有 id 为 %s 的回放存在", g_ReplayId[client]);
    g_ReplayId[client] = "";
    return Plugin_Handled;
  }

  if (args >= 2) {
    // Get the role number(s) and play them.
    char roleBuffer[32];
    GetCmdArg(2, roleBuffer, sizeof(roleBuffer));
    char tmp[32];
    ArrayList split = SplitStringToList(roleBuffer, ",", sizeof(tmp));
    for (int i = 0; i < split.Length; i++) {
      split.GetString(i, tmp, sizeof(tmp));
      if (StrEqual(tmp, "")) {
        continue;
      }

      int role = StringToInt(tmp) - 1;
      if (role < 0 || role > MAX_REPLAY_CLIENTS) {
        PM_Message(client, "无效的角色: %s: 必须处于 1 和 %d 之间", tmp, MAX_REPLAY_CLIENTS);
        return Plugin_Handled;
      }

      ReplayRole(g_ReplayId[client], g_ReplayBotClients[role], role);
      if (split.Length == 1) {
        g_CurrentEditingRole[client] = role;
      }
    }
    delete split;
    PM_MessageToAll("使用角色 %s ，在回放 %s 中", roleBuffer, g_ReplayId[client]);

  } else {
    // Play everything.
    PM_MessageToAll("运行回放 %s.", g_ReplayId[client]);
    RunReplay(g_ReplayId[client]);
  }

  return Plugin_Handled;
}

public void ResetData() {
  for (int i = 0; i < MAX_REPLAY_CLIENTS; i++) {
    g_StopBotSignal[i] = false;
  }
  for (int i = 0; i <= MaxClients; i++) {
    g_CurrentEditingRole[i] = -1;
    g_ReplayId[i] = "";
  }
}

public void BotMimic_OnPlayerMimicLoops(int client) {
  if (!g_InPracticeMode) {
    return;
  }

  if (g_StopBotSignal[client]) {
    BotMimic_ResetPlayback(client);
    BotMimic_StopPlayerMimic(client);
    RequestFrame(Timer_DelayKillBot, GetClientSerial(client));
  } else {
    g_StopBotSignal[client] = true;
  }
}

public Action Timer_CleanupLivingBots(Handle timer) {
  if (!g_InPracticeMode) {
    return Plugin_Continue;
  }

  if (g_InBotReplayMode) {
    for (int i = 1; i <= MaxClients; i++) {
      if (IsReplayBot(i) && !BotMimic_IsPlayerMimicing(i)) {
        KillBot(i);
      }
    }
  }

  return Plugin_Continue;
}

public Action Event_ReplayBotDamageDealtEvent(Event event, const char[] name, bool dontBroadcast) {
  if (!g_InPracticeMode || !g_InBotReplayMode || !g_BotMimicLoaded) {
    return Plugin_Continue;
  }

  int attacker = GetClientOfUserId(event.GetInt("attacker"));
  int victim = GetClientOfUserId(event.GetInt("userid"));

  if (IsReplayBot(victim) && IsPlayer(attacker) && BotMimic_IsPlayerMimicing(victim)) {
    int damage = event.GetInt("dmg_health");
    int postDamageHealth = event.GetInt("health");
    PM_Message(attacker, "对 %N 造成 ---> %d 伤害 (剩余 %d HP)", victim, damage, postDamageHealth);
  }

  return Plugin_Continue;
}
