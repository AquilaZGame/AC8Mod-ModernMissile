Modern Missile Mod 1.0.0  -  ACE COMBAT 8: Wings of Theve
=========================================================

EN  Missile parameter overhaul for the player's aircraft. Single-player / offline only.
ZH  玩家导弹参数重制。仅限单人 / 离线模式。

INSTALL / 安装
--------------
Copy this folder into:  ACE COMBAT 8\Game\Binaries\Win64\ue4ss\Mods\
将本文件夹复制到：      ACE COMBAT 8\Game\Binaries\Win64\ue4ss\Mods\

You should end up with:
  ue4ss\Mods\ModernMissileMod\enabled.txt
  ue4ss\Mods\ModernMissileMod\Scripts\main.lua

REQUIREMENTS / 前置要求
-----------------------
- ACE COMBAT 8 (Steam), single-player / offline
- UE4SS 3.0.1 or newer in Game\Binaries\Win64\
- No-EAC offline launcher

SETTINGS / 设置
---------------
All values are in Scripts\config.lua. Restart the game after editing.
全部数值位于 Scripts\config.lua，修改后重启游戏。

NOTES / 注意
------------
- Cycle the weapon once after entering a mission to refresh the HUD lock ring.
  进入任务后请切换一次武器，以刷新 HUD 锁定圈。
- Values are re-applied at the start of every mission; the mod is idle afterwards.
  每局开始时会重新写入，之后完全空闲。
- Enemy missiles are not changed. 敌方导弹不修改。
- Nothing is written to the save file. 不写入存档。

LOG / 日志
----------
ModernMissileMod.log in this folder. 本文件夹下的 ModernMissileMod.log。

LICENCE / 授权
--------------
MIT
