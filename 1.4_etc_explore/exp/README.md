# AskTao 1.4 经验系统说明

本目录保存人物、宠物、元婴/血婴、宠物天书技能相关经验表，以及经验奖励相关对象文件。

## 文件说明

- `expd.o`：经验表守护模块对象，来自 `/gs/daemons/expd.c`。
- `user_exp.o`：玩家获得经验的奖励逻辑对象，来自 `/gs/daemons/bonus/user_exp.c`。
- `bonusd.o`：通用奖励分发中心，来自 `/gs/daemons/bonusd.c`。
- `formulad.o`：公式计算中心，来自 `/gs/daemons/formulad.c`。
- `exp_user.list`：公测区人物经验列表，181 级。
- `exp_user_test.list`：内测区人物经验列表，181 级。
- `exp_pet.list`：公测区宠物经验列表，181 级。
- `exp_pet_test.list`：内测区宠物经验列表，181 级。
- `exp_upgrade.list`：公测区元婴、血婴经验列表，181 级。
- `exp_upgrade_test.list`：内测区元婴、血婴经验列表，181 级。
- `exp_godbook_skill.list`：宠物天书技能经验列表，288 级。
- `exp.list`：旧版或备用人物经验表，120 级；`expd.o` 中没有直接引用这个文件名。

## expd.o 的作用

`expd.o` 负责加载经验表并按等级查询经验。对象中能看到这些文件名和函数：

```text
exp_user.list
exp_user_test.list
exp_pet.list
exp_pet_test.list
exp_godbook_skill.list
exp_upgrade.list
exp_upgrade_test.list

load_exp_user_list
load_exp_pet_list
load_exp_godbook_skill_list
load_exp_upgrade_list

query_exp
query_pet_exp
query_godbook_skill_exp
```

按 GBK 解码 `expd.o` 中的提示字符串，可以推断：

- `exp_user.list` 是“公测区人物经验列表”。
- `exp_user_test.list` 是“内测区人物经验列表”。
- `exp_pet.list` 是“公测区宠物经验列表”。
- `exp_pet_test.list` 是“内测区宠物经验列表”。
- `exp_godbook_skill.list` 是“宠物天书技能经验列表”。
- `exp_upgrade.list` 是“元婴、血婴经验列表”。

## 奖励计算链

`user_exp.o` 不直接读取 `.list` 文件。它负责玩家经验奖励入口，能看到：

```text
do_bonus
def_do_bonus
double_bonus
forbid_bonus
calculate
```

`bonusd.o` 是通用奖励分发中心，不只处理经验，还处理金钱、代金券、潜能、道行、宠物武学、亲密度、物品、装备、宠物等奖励。

`formulad.o` 提供公式计算能力，核心函数是：

```text
calculate
```

整体关系可以理解为：

```text
经验表文件
  -> expd.o 加载并提供等级经验查询

玩家获得经验
  -> user_exp.o 处理经验奖励入口
  -> bonusd.o 统一发放奖励
  -> formulad.o 计算经验公式
  -> 玩家对象 add_exp / add_experience
```

## 表格式

经验表使用简单的 `等级=经验值` 格式：

```text
1=0
2=40
3=108
```

修改时保持纯文本格式，不要添加多余列。部分文件使用 CRLF 换行，批量处理时注意不要无意改变整文件换行风格。

## 表之间的关系

`exp_user.list` 是公测区人物经验主表。`exp_user_test.list` 是内测区人物经验表。

`exp.list` 和 `exp_user_test.list` 在 1-120 级范围内完全一致，因此更像旧版或备用人物经验表：

```text
exp.list = exp_user_test.list 的 1-120 级
```

`exp_user.list` 和 `exp_user_test.list` 在 1-65 级一致；从 66 级开始，公测区人物经验明显高于内测区人物经验。

`exp_upgrade.list` 的每一级经验值等于 `exp_user.list` 对应等级的一半，向下取整：

```text
exp_upgrade[level] = int(exp_user[level] / 2)
```

例如：

```text
exp_user.list:    120=34620231
exp_upgrade.list: 120=17310115
```

`exp_pet.list` 和 `exp_upgrade.list` 前期接近，但不是完全相同；从 46 级开始出现差异，后段数值又趋于一致。不要直接用其中一个覆盖另一个。

`exp_pet_test.list` 和 `exp_upgrade_test.list` 也不是简单的一半关系，修改时应分别处理。

## bonusd.o 关联模块

`bonusd.o` 中还能看到这些外部模块路径，说明奖励系统会和多个守护模块协作：

```text
/gs/daemons/moneyd.c
/gs/daemons/petd.c
/gs/daemons/formulad.c
/gs/daemons/gamecfgd.c
/gs/daemons/taskd.c
/gs/daemons/upgraded.c
/gs/daemons/named.c
/gs/daemons/scand.c
/gs/daemons/artifactd.c
/daemons/filed.c
/feature/daemon/register.c
```
