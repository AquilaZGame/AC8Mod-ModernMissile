# 开发记录 / 逆向结论

本文件记录在 **游戏版本 25201480（2026-10）** 上实测得到的结论，供后续维护参考。

## 1. 数据位置

### 1.1 飞行 / 导引 / 锁定参数 —— 武器蓝图的 CDO

```
/Game/Blueprints/Weapons/MSL/Player/<弹种>/BP_plwp_<弹种>_<变体>.BP_plwp_<弹种>_<变体>_C
  → GetCDO() → Default__BP_plwp_<弹种>_<变体>_C
```

类继承链：`BP_plwp_*_C` → `BP_wp_msl_BaseClass_C` → `/Script/Live.LiveMissile` → `LiveExplosiveWeapon` → `LiveWeaponBase` → `LiveObjectPoolItem` → `Actor`。

字段（除注明外均为 `FloatProperty`）：

| 字段 | 含义 | 单位 | 原版样例（MSL / 4AAM / QAAM） |
| --- | --- | --- | --- |
| `LockonRange` | 锁定圈半径 | **厘米** | 200000 / 400000 / 240000 |
| `LockonAngle` | 锁定圆锥角 | 度 | 32.5 / 32.5 / 120 |
| `MaxHomingAngle` | 导引头视场 | 度 | 75 / 65 / 120 |
| `MaxRotationAngle` | 转向速率 | 度/秒 | 40 / 45 / 75 |
| `HomingForesightAmount` | 比例制导提前量 | 0–1 | 0 / 0 / 0.4 |
| `LifeTime` | 飞行寿命 | 秒 | 9 / 20 / 15 |
| `SpeedMaximum` | 最大速度 | 厘米/秒 | 108333 / 133333 / 116667 |
| `Acceleration` | 加速度 | 厘米/秒² | 13888 / 16666 / 13888 |
| `InitialSpeed` | 初速 | 厘米/秒 | 11111 / 0 / 16666 |
| `damage` | 伤害 | — | 40 / 80 / 80 |
| `ExplosionRadius` | 爆炸半径 | 厘米 | 0 / 0 / 0 |
| `MaxLoadedCount` | 一次齐射发数（**不是备弹**） | 发 | 2 / 4 / 2 |

> 米与厘米的换算：`LockonRange 200000` = 2.0 km。`PropNav` 的 ini 注释写「米」是错的。

### 1.2 备弹 —— 机型参数表

```
/Game/Datatables/Player/Parameter/DT_PlayerParameter_<机型代码>.DT_PlayerParameter_<机型代码>
  Row.SpWeaponID1..4                  ← 该机型的 4 个特殊武器槽（武器 ID）
  Row.LevelParameter[1..31]           ← 31 个改装等级
    .GunLoadCount / MainWeaponLoadCount / FlareLoadCount
    .SPWeaponInfo<k>.SpWeaponLoadCount1 / SpWeaponLoadCount2
                                       ← 武器 k 放在 SP1 / SP2 时的备弹
```

例：F-22A `SpWeaponID1=21(QAAM) SpWeaponID2=4(4AAM) SpWeaponID3=31(XSDB)`，L1 时 `SPWeaponInfo1=24/12`、`SPWeaponInfo2=32/16`。

注意：嵌套结构体有时以**副本**返回，单字段写入不生效；需要回读校验，失败时整结构体赋值。

### 1.3 锁定圈模板表（未被游戏读取）

`/Game/Datatables/Player/DT_WeaponSettings` 只有 3 行（`LockonAngle` 40 / 36.25 / 120，`LockonRangeInMeters` 2850 / 2000 / 2400）。改这张表**不影响**实际锁定圈，实际值来自武器 CDO。

### 1.4 敌方武器

`/Game/Datatables/AI/NPC/Weapon/DT_NPC_Weapon`（`LiveNpcWeaponDataTable`）是另一套，字段名几乎一样但不带 `LockonRange`（敌机不锁定）。本 Mod 不修改。

## 2. 变体（`_a0` / `_a1` / `_f0` / `_r0` …）

同一种导弹按**挂载模型**分成多个蓝图，飞机决定用哪一个（F-22A 用 `_a0`，F-35C 用 `_a1`）。变体之间是**蓝图继承**关系：父变体 CDO 被改后，之后创建的变体会继承到已修改的值。

因此：

- 必须覆盖所有变体，不能只写 `_a0`。
- 原值要按**武器类型**缓存一份，不能按 CDO 缓存，否则子变体会拿「已乘过的值」再乘一次（伤害 100 → 250）。

## 3. 时机

- 武器 CDO 在主菜单通常**不存在**；进入任务、武器整备界面之前才会加载。
- 游戏**每次进关卡都会把武器 CDO 重置回原值**，所以每局都要重新写入。
- 写入必须发生在**武器装配（Setup）之前**：在飞机生成后才发现并改写，当次任务不生效。
- 实测安全窗口：关卡 `LoadMapPost` 之后的约 15 秒内，分 4 次写入即可稳定生效。

## 4. 崩溃与卡顿的两个教训

**一、不要每 2 秒重写全部 CDO。**

曾用 2 秒轮询做「持续校验」，结果有两个问题：

- 每次重写都会造成一次明显掉帧（玩家能感知的周期性卡顿）。
- 在换关卡、武器选择界面反复写资源，最终导致崩溃。

**二、不要在菜单 / 机库地图写入。**

用 `PlayerController:GetWorld():GetFullName()` 判断地图，只处理 `Maps/Ingame/...`；`Maps/Menu`、`Maps/Hangar`、`Maps/Transition` 一律跳过。`UWorld:GetMapName()` 在这个 UE4SS 构建里读不到，返回 nil。

另外，`FindAllOf('PlayerController')` 会遍历整个对象数组，**不能每秒调用**，这是周期性卡顿的经典来源。改成 `NotifyOnNewObject('/Script/Engine.PlayerController')` 缓存控制器，再读 `Pawn` 即可。

## 5. 其它坑

- `FindAllOf('BlueprintGeneratedClass')` / `FindAllOf('Class')` 在本构建里找不到 `BP_plwp_*`，枚举类不可靠；用已知路径加常见后缀（`a0/a1/f0/f1/r0/r1`）更稳。
- `DataTable` 行负载（`row.Data`）上读 `StructProperty` / `SoftObjectProperty` 会**直接闪退**，只读标量字段；嵌套数组 / 结构体（如 `LevelParameter`）可以读。
- `enabled.txt` 必须只有一个字符（`printf '1'`，不要 `echo`）。
- `print()` 会进 UE4SS.log，但日志文件建议写到 Mod 根目录，**不要写进 `Scripts\`**（会被热重载监视）。
