# AskTao 1.4 经验系统分析

本文档记录当前对 AskTao 1.4 gameserver 经验、升级、卡级逻辑的静态分析结论。当前目录是解包后的运行对象和配置表，不是完整 C 源码；以下结论主要来自 `.o` 对象中的字符串、函数名、路径名和配置表关系。

## 目录结构

- `etc.pak/exp_user.list`：公测区人物经验表，1 到 181 级。
- `etc.pak/exp_user_test.list`：内测区人物经验表，1 到 181 级。
- `etc.pak/exp_pet.list`：宠物经验表，1 到 181 级。
- `etc.pak/exp_pet_test.list`：内测区宠物经验表。
- `etc.pak/exp_upgrade.list`：元婴、血婴经验表。
- `etc.pak/exp_upgrade_test.list`：内测区元婴、血婴经验表。
- `etc.pak/exp_godbook_skill.list`：宠物天书技能经验表，1 到 288 级。
- `etc.pak/exp.list`：旧版或备用人物经验表，只有 120 级；当前 `expd.o` 没有直接引用这个文件名。

## 核心对象职责

- `lib_gs32.pak/gs/daemons/expd.o`：经验表 daemon，对应源路径 `/gs/daemons/expd.c`。负责加载经验表，并提供 `query_exp`、`query_pet_exp`、`query_godbook_skill_exp` 等查询入口。
- `lib_gs32.pak/gs/feature/char/attrib.o`：角色属性与资源变化模块，对应 `/gs/feature/char/attrib.c`。包含 `add_experience`、`can_add_experience`、`get_max_level`，是人物获得经验后的关键入口。
- `lib_gs32.pak/gs/daemons/chard.o`：角色 daemon，对应 `/gs/daemons/chard.c`。包含 `check_exp`、`level_up`、`improve_level_user_direct`，负责判断并执行人物升级。
- `lib_gs32.pak/gs/daemons/bonusd.o`：奖励派发模块，对应 `/gs/daemons/bonusd.c`。任务、战斗等奖励最终会调用角色或宠物的加经验接口。
- `lib_gs32.pak/gs/daemons/char_upgraded.o`：飞升、元婴、血婴相关 daemon，对应 `/gs/daemons/char_upgraded.c`。包含 `pause_level_up`、`open_level_up`、`register_pause_level_up`、`task_pause_level_up`。

## 人物经验调用链

目前推断的人物经验流程如下：

```text
任务/战斗/活动奖励
-> bonusd.o 派发经验奖励
-> 角色对象 add_experience
-> attrib.o:can_add_experience
-> chard.o:check_exp
-> chard.o:level_up
-> chard.o:improve_level_user_direct
```

`expd.o` 不直接决定是否升级，它更像经验表查询服务。是否允许继续加经验或升级，主要在 `attrib.o` 和 `chard.o`。

## 经验表关系

`exp_user.list` 和 `exp_user_test.list` 都有 1 到 181 级数据，因此人物经验表本身支持 125 级以后继续升级。例如：

```text
125=49818240
126=53094000
```

这说明“125 级以后可以获得经验但不会升级”不是因为 126 级经验值缺失。

`exp_upgrade.list` 用于元婴、血婴经验，不应直接替换人物经验表。`exp_godbook_skill.list` 是宠物天书技能经验，和人物升级无直接关系。

## 125 级后不升级的当前判断

目前最可疑的限制点有两个。

第一，`attrib.o:can_add_experience` 同时引用了：

```text
is_pause_level_up
is_upgraded
get_max_level
is_upgrade_state
```

这说明加经验前会判断是否暂停升级、是否已经飞升、当前最大等级是多少。125 级卡住很可能来自 `get_max_level` 对未飞升角色返回 125，或者角色飞升状态 `is_upgraded` 没有正确保存。

第二，飞升、地劫、天劫任务会控制升级开关：

```text
pause_level_up
open_level_up
register_pause_level_up
task_pause_level_up
```

这些函数出现在 `char_upgraded.o`，并被地劫、天劫任务对象引用。地劫配置也能对应上高等级阶段：`dijie9.list` 怪物等级为 124，`dijie10.list` 怪物等级为 129；`tianjie.list` 天劫阶段从 134 开始，奖励门槛从 130 开始。

因此当前判断是：125 级不升级大概率不是经验表问题，而是飞升状态、地劫/天劫流程、或暂停升级状态没有满足。

## 排查建议

如果玩家 125 级后经验继续增加但不升级，优先检查玩家存档或数据库中的这些字段、路径或任务状态：

```text
is_upgraded
has_upgraded
upgrade/state
upgrade/type
pause_level_up
task
dijie
char_upgrade
```

如果角色已经完成飞升但仍然卡 125，重点确认 `is_upgraded` 或 `upgrade/state` 是否正确写入。若这些状态异常，`attrib.o:can_add_experience` 可能仍按未飞升角色最大等级处理。

## 无源码卡级方案

没有 `/gs/feature/char/attrib.c`、`/gs/daemons/chard.c` 等源码时，不建议优先二进制 patch `.o`。更稳妥的做法是通过人物经验表做兜底限制：把目标等级升到下一级所需经验改成极大值。

如果目标是“人物最高 109 级”，应修改 109 级这一行，而不是 110 级这一行。原因是 `chard.o` 中出现 `exp_to_next_level`，经验表更像“当前等级升下一级所需经验”。因此：

```text
109=2000000000
```

表示 109 升 110 需要 20 亿经验，实际运行中角色会长期停在 109 级。不要超过 `2147483647`，老服务端很可能使用 32 位有符号整数，超过后可能溢出。

建议同步修改：

```text
etc.pak/exp_user.list
etc.pak/exp_user_test.list
```

`etc.pak/exp.list` 当前没有被 `expd.o` 直接引用，内容等于 `exp_user_test.list` 的前 120 行，更像旧版或备用表。正常情况下不用改；如果希望保险，可以同步把 `exp.list` 的 `109=` 也改成同样的大值。

不要删除 110 到 181 的行。服务端或客户端可能仍会查询后续等级，删除行可能导致 `query_exp` 返回异常。保留后续数据，只提高 `109=` 的门槛，回滚也更简单。

这种方式不是严格的“最大等级开关”，只是把升级门槛拉到极高。已经超过 109 级的角色不会被自动降级，需要单独处理角色数据。

## 后续分析方向

要进一步确认源码级分支，需要找到或还原以下源码对象对应的 `.c`：

```text
/gs/feature/char/attrib.c
/gs/daemons/chard.c
/gs/daemons/char_upgraded.c
/gs/daemons/expd.c
```

如果没有源码，只能继续通过 `.o` 的字符串、偏移和运行时行为反推。下一步可以围绕 `get_max_level`、`can_add_experience`、`pause_level_up`、`open_level_up` 做更细的二进制或运行时验证。
