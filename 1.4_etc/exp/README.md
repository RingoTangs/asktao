# AskTao 1.4 经验表说明

本目录保存人物、宠物、元婴/血婴、宠物天书技能相关经验表，以及负责加载这些经验表的对象文件。

## 文件说明

- `expd.o`：经验表守护模块对象，来自 `/gs/daemons/expd.c`。
- `user_exp.o`：玩家获得经验的奖励逻辑对象，来自 `/gs/daemons/bonus/user_exp.c`。
- `exp_user.list`：公测区人物经验列表，181 级。
- `exp_pet.list`：公测区宠物经验列表，181 级。
- `exp_upgrade.list`：元婴、血婴经验列表，181 级。
- `exp_godbook_skill.list`：宠物天书技能经验列表，288 级。
- `exp.list`：旧版或备用人物经验表，120 级；`expd.o` 中没有直接引用这个文件名。

## expd.o 中能看到的信息

`expd.o` 里能看到这些文件名和加载/查询函数：

```text
exp_user.list
exp_pet.list
exp_godbook_skill.list
exp_upgrade.list

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
- `exp_pet.list` 是“公测区宠物经验列表”。
- `exp_godbook_skill.list` 是“宠物天书技能经验列表”。
- `exp_upgrade.list` 是“元婴、血婴经验列表”。

`expd.o` 还包含测试区文件名，例如 `exp_user_test.list`、`exp_pet_test.list`、`exp_upgrade_test.list`，但当前目录没有这些测试表。

## 表格式

经验表使用简单的 `等级=经验值` 格式：

```text
1=0
2=40
3=108
```

修改时保持纯文本格式，不要添加多余列。部分文件使用 CRLF 换行，批量处理时注意不要无意改变整文件换行风格。

## 表之间的关系

`exp_user.list` 是当前人物经验主表。`exp_upgrade.list` 的每一级经验值等于 `exp_user.list` 对应等级的一半，向下取整：

```text
exp_upgrade[level] = int(exp_user[level] / 2)
```

例如：

```text
exp_user.list:    120=34620231
exp_upgrade.list: 120=17310115
```

`exp.list` 和 `exp_user.list` 在 1-65 级基本一致；从 66 级开始，`exp_user.list` 数值明显更高，并扩展到 181 级。因此 `exp.list` 更像旧版或备用人物经验表。

`exp_pet.list` 和 `exp_upgrade.list` 前期接近，但不是完全相同；从 46 级开始出现差异，后段数值又趋于一致。不要直接用其中一个覆盖另一个。

## user_exp.o 的作用

`user_exp.o` 中可以看到：

```text
do_bonus
def_do_bonus
double_bonus
forbid_bonus
calculate
```

这说明它更像“给玩家发经验/计算经验奖励”的逻辑模块，不是经验表加载模块。经验表加载和按等级查询主要由 `expd.o` 负责。
