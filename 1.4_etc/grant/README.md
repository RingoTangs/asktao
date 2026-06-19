# AskTao 1.4 权限配置说明

本目录保存 GM/后台操作权限相关文件，路径为 `1.4_etc/grant/`。

- `grant.list`：当前修改后的权限配置文件，GBK 编码。
- `grantd.o`：权限守护模块对象，来自 `/gs/daemons/grantd.c`，负责解析 `grant.list`。
- `grant.original.list`：原始权限配置备份文件。

## grant.list 格式

`grant.list` 顶部定义权限代号和权限名称：

```text
$GA = ADMINISTRATOR
$GA1= OBSERVER
$GB = BEHOLDER
$GC = CONTROLLER
$GD = DEBUGGER
$G1 = GM_GROUP1
...
$G9 = GM_GROUP9
```

后面的操作授权格式如下：

```text
admin_operation_name    (GA), (GB), (GC)
```

`grantd.o` 中可以看到 `grant.list`、`$%s=%s`、`(%s)`、`Bad privilege %s of operation %s in grant.list.` 等字符串，说明权限代号会从 `grant.list` 中读取并校验。

## 当前配置状态

当前 `grant.list` 已将 64 条 `admin_` 操作统一授权给下面这些权限组：

```text
(GA), (GB), (GC), (GD), (G1), (G2), (GA1)
```

也就是说，拥有 `GA`、`GA1`、`GB`、`GC`、`GD`、`G1`、`G2` 这些权限组的角色，可以执行 `grant.list` 中列出的全部 GM/后台操作。

当前配置没有给 `G3-G9` 授权。如果需要让 `G3-G9` 也能执行这些操作，需要把它们显式加入每条操作的授权列表。

## 权限等级

`grant.list` 注释中记录的权限等级关系为：

```text
GD > GC > GB > GA1 > GA
```

其中 `GD` 权限最高，`GA` 是最低一级基础管理权限。

## 反推的权限代码

从 `grantd.o` 字节码常量和 `grant.list` 权限等级注释可以反推出以下权限代码。这个表是二进制分析结论，不是源码级确认。

| 权限代号 | 权限名称 | 反推代码 | 说明 |
| --- | --- | ---: | --- |
| `GD` | `DEBUGGER` | `1000` | 最高权限 |
| `GC` | `CONTROLLER` | `300` | 高级控制权限 |
| `GB` | `BEHOLDER` | `200` | 中级查看/管理权限 |
| `GA1` | `OBSERVER` | `130` | 观察权限 |
| `GA` | `ADMINISTRATOR` | `120` | 基础管理权限 |
| `G1` | `GM_GROUP1` | `101` | 特权组 |
| `G2` | `GM_GROUP2` | `102` | 特权组 |
| `G3` | `GM_GROUP3` | `103` | 特权组 |
| `G4` | `GM_GROUP4` | `104` | 特权组 |
| `G5` | `GM_GROUP5` | `105` | 特权组 |
| `G6` | `GM_GROUP6` | `106` | 特权组 |
| `G7` | `GM_GROUP7` | `107` | 特权组 |
| `G8` | `GM_GROUP8` | `108` | 特权组 |
| `G9` | `GM_GROUP9` | `109` | 特权组 |

推断依据是 `grantd.o` 尾部出现的一组整数常量：

```text
109, 108, 107, 106, 105, 104, 103, 102, 101, 1000, 300, 200, 130, 120
```

这组数值和 `grant.list` 中定义的 `G9-G1`、`GD-GA` 顺序能够对应。

## 修改建议

修改 `grant.list` 时注意：

- 保持 GBK 编码。
- 只使用顶部已经定义过的权限代号。
- 操作授权建议保持现有格式，例如：

```text
admin_query_name_to_account                 (GA), (GB), (GC), (GD), (G1), (G2), (GA1)
```

如果写入未定义权限代号，`grantd.o` 可能报错：

```text
Bad privilege xxx of operation yyy in grant.list.
```
