csgo-practice-mode
CSGO 练习模式插件 汉化版

此说明文档由RoyZ翻译，仅做介绍搬运
===========================
FOR ORIGINAL [EN VERSION](https://github.com/splewis/csgo-practice-mode/)


从Github[下载](https://github.com/RoyZ-CSGO/csgo-practice-mode-zh-CN/releases)

## 功能
- 如果启用了``sv_grenade_trajectory``，插件将为所有玩家绘制投掷物轨迹。
- 添加了新的cvar以提供额外的练习设置（无限金钱，无需启用sv_cheats的noclip）
- 可以保存用户的投掷物位置/角度及其名称和描述（投掷物数据保存到服务器上的``addons / sourcemod / data / practicemode / grenades``目录中的文件中）
- 用户可以转到任何玩家保存的投掷物来学习或重新访问他们
- 显示带有切换设置的菜单，以设置在[addons / sourcemod / configs / practicemode.cfg]（configs / practicemode.cfg）中定义的练习cvar
- 在当前地图上保持您的投掷物历史记录，因此您可以使用.back和.forward来查看您在当前会话中投掷的所有投掷物点
- 可以单独或在完全定时执行的情况下重放投掷物测试以进行测试

## 指令大全

### 常规命令

- ``.setup``显示练习模式菜单
- ``.prac``启动练习模式并显示``.setup``菜单
- ``.help``：显示此页面
- ``.settings``：打开客户端设置菜单

### 保存投掷物位置
- ``.nades [过滤器]``：显示一个菜单来选择已保存的投掷物位置。 ``.nades``不带参数显示所有投掷物。 ``过滤器``可以是以下任何一种：投掷物ID，类别名称，玩家名称或投掷物名称的一部分
- ``.cats``：按类别显示所有已保存投掷物的菜单
- ``.save <名称>``：使用给定名称将当前位置保存为投掷物位置
- ``.goto <投掷物id>``：将您传送到玩家已保存的投掷物（如果没有命名玩家则为您自己的投掷物）
- ``.delete``：删除您使用.goto（或.nades）传送到的最后一个投掷物
- ``.find <文本>``：在所有投掷物名称中搜索文本匹配项

### 修改已保存的投掷物
以下所有命令只能在_your_投掷物上使用。它们将应用于您上次保存的投掷物，无论是通过.save，.nades还是.goto。
- ``.desc <描述>``：在最后一个投掷物上添加一个投掷物描述
- ``.rename <新名称>``：重命名您的最后一枚投掷物
- ``.addcat <类别> ...``：将类别添加到您的最后一枚投掷物
- ``.removecat <分类>``：从上一个投掷物中删除一个类别
- ``.clearcats``：删除最后一个投掷物上的所有类别
- ``.deletecat <类别>``：从所有保存的投掷物中删除一个类别
- ``.copy <用户名> <投掷物id>``：复制另一个用户的投掷物并将其保存为您
- ``.setdelay <延迟>``：设置最后一个投掷物的延迟时间。仅在对类别使用.throw时使用

### 测试投掷物
- ``.last``：将你传送回你投掷最后一枚投掷物的地方
- ``.back``：传送您回到投掷物历史记录中的位置（例如，您也可以执行``.back 5``转到所投掷的第5颗投掷物）
- ``.forward``：传送你在投掷物历史上的位置
- ``.flash``：保存您的位置以对其进行测试。在您想致盲的地方使用此命令，然后移动并扔出闪光灯。您将被传送回该位置，并查看闪光灯的效果。使用``.stop``取消。
- ``.throw [过滤器]``：自动抛出所有与过滤器匹配的投掷物。没有过滤器，投掷您投掷的最后一枚投掷物。
- ``.noflash``：使其不会让闪光弹使您蒙蔽（他们仍然使其他人蒙蔽）

### Spawn命令
- ``.respawn``：使您在站立的位置重生（``.stop``取消）
- ``.spawn <出生点ID>``：使用团队的出生（CT或T）将您传送到出生点。如果没有给出出生点ID，则使用最近的出生
- ``.ctspawn <出生点ID>``：与.spawn相同，但是无论您在哪个团队中，仅用于CT
- ``.tspawn <出生点ID>``：与.spawn相同，但是无论您在哪个团队中，仅用于T
- ``.namespawn <名称>``：将最接近的出生保存在一个名称下，然后可以通过``.spawn <名称>``进入
- ``.bestspawn``：将您从当前位置传送到团队中最接近的副本
- ``.worstspawn``：从当前位置传送到团队中最远的出生

### Bot命令
- ``.bots``：打开bot菜单以便更轻松地访问以下大多数命令
- ``.bot``：在您站立的地方添加一个机器人（或蹲伏）; ``.crouchbot``强制蹲伏机器人
- ``.ctbot``，``.tbot``：与``.bot``相同，但是将机器人的团队强制为CT或T
- ``.botplace``：在您要查看的位置添加一个机器人（类似于``bot_place``命令）
- ``.boost``：出生一个机器人来提升你的能力（如果你蹲伏的话会蹲下来）; ``.crouchboost``强制蹲伏机器人
- ``.swapbot``：与最近的机器人交换您的位置（临时，该机器人仍会在原始位置重新出生）
- ``.movebot``：将您放置的最后一个机器人移动到当前位置
- ``.nobot``：删除您瞄准的机器人（也可以使用``.kickbot``或``.removebot``）
- ``.nobots``：清除所有机器人（``.clearbots``，``.removebots``，``.kickbots``也可以使用）
- ``.savebots``：将所有当前的机器人保存到文件中
- ``.loadbots``：从文件中加载机器人（由最后的``.savebots``编写）

### 其他命令
- ``.timer``：当您开始沿任何方向移动时启动一个计时器，当您停止移动时停止计时器，告诉您启动/停止之间的时间间隔
- ``.timer2``：立即启动一个计时器并在再次键入.timer2时将其停止，告诉您持续时间
- ``.countdown <duration>``：在指定的持续时间（以秒为单位）中启动倒数计时器，默认为舍入持续时间（`mp_roundtime` cvar）。
- ``.fastfoward``（或``.ff``）：短暂地加快服务器时钟速度，以使烟雾迅速消散
- ``.repeat <interval> <command>``：给出一个秒数和一个聊天命令，该命令将以给定的间隔自动重复。例如：``.repeat 3 .throw``每3秒扔出一次
- ``.delay <duration> <command>``：在给定的持续时间（以秒为单位）后运行给定的聊天命令
- ``.map``：更改地图（您可以使用地图名称，例如``.map de_dust2``或仅使用``.map``来获取菜单）
- ``.dryrun``：禁用大多数练习模式设置（保留无限资历），重新开始回合，并将冻结时间设置为``sm_practicemode_dry_run_freeze_time``（默认6）-您也可以使用``.dry``
- ``.enable <arg>``：启用部分命名的设置或“所有”设置。
- ``.disable <arg>``：禁用部分命名的设置或“所有”设置。
- ``.savepos``：临时保存一个位置，以便您可以对其进行``.back``（这会将位置添加到您抛出的投掷物位置列表中）
- ``.god``：切换上帝模式（控制台中``god``命令的别名;要求打开sv_cheats）
- ``.endround``：结束回合（控制台中``endround``命令的别名;要求打开sv_cheats）
- ``.break``：中断所有func_breakable实体（大多数窗口）
- ``.stop``：取消当前操作（这可以停止很多事情：.flash命令，.repeat命令和.timer命令）
- ``.spec``，``.t``，``.ct``：加入团队

### Bot重放命令
**注意：**机器人重放支持目前正在进行中。还没有准备好用于一般用途。如果计划使用这些命令，则安装[dhooks扩展]（http://users.alliedmods.net/~drifter/builds/dhooks/2.2/）也是一个好主意。如果使用这些随机崩溃。

- ``.replays``：打开重放模式菜单
- ``.replay``：打开重放模式菜单，或者您打开的最后一个重放/角色菜单
- ``.namereplay``：命名您当前正在处理的重放
- ``.namerole``：命名您当前正在处理的角色
- ``.finish``：完成并保存当前录音
- ``.cancel``：取消当前的重放/记录
- ``.play <id> [role]``：播放重放ID（所有角色），或重放中的单个角色

## 可控制变量
您可以在``cfg / sourcemod / practicemode.cfg``文件中编辑这些文件，该文件在插件首次启动时会自动生成。

注意，这并不一定是详尽的。 检查``cfg / sourcemod / practicemode.cfg``以获得更多的cvar，甚至考虑检查源代码以获取最新列表。

- ``sm_practicemode_alphabetize_nades``：以字母顺序而不是id顺序显示投掷物
- ``sm_practicemode_share_all_nades``：让所有用户编辑所有nade，并隐藏创建它们的人
- ``sm_practicemode_autostart``：是否自动启动练习模式
- ``sm_practicemode_max_grenades_saved``：用户可以通过.save保存的最大投掷物数量
- ``sm_infinite_money``：是否给予无限金钱
- ``sm_allow_noclip``：是否启用.noclip命令
- ``sm_grenade_trajectory_use_player_color``：是否使用cl_color获取投掷物轨迹颜色
- ``sm_practicemode_can_be_started``：是否可以启动练习模式