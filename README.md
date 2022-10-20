# SDBUS Host Info

linux 下 sdbus 程序, 通过 dbus 接口利用 i2c alert 获取主机侧数据

# 目录

- [1. DBUS 接口](#1-dbus-接口)
  - [1.1 DBUS 相关数据格式](#11-dbus-相关数据格式)
  - [1.2 method 接口](#12-method-接口)
  - [1.3 property 接口](#13-property-接口)
    - [1.3.1 property 返回示例](#131-property-返回示例)
- [2. 使用流程](#2-使用流程)
- [3. 调试命令](#3-调试命令)
  - [3.1 虚拟机使用命令](#31-虚拟机使用命令)
- [X. 参考文档](#x-参考文档)

# 1. DBUS 接口

| dbus注册接口 | 说明 |
| :---: | :---: |
| com.gxmicro.HostInfo | service名称 |
| /com/gxmicro/host_info | object名称 |
| com.gxmicro.HostInfo | interface名称 |

## 1.1 DBUS 相关数据格式

以下仅列出部分数据格式, 详细参阅官方文档
| 数据 | 使用编码 | 说明 |
| :---: | :---: | :---: |
| BYTE | y | 8位无符号数 |
| UINT16 | q | 16位无符号数 |
| ARRAY | a | 后续数据为数组, 数组长度为a表示的数据 |

## 1.2 method 接口

| method | 说明 |
| :---: | :---: |
| UpdateInfo | 用户获取数据前, 需要使用此接口更新property信息 |
| GetInfo | 隐藏接口不对外显示, 用于bmc每5s触发alert信号 |

## 1.3 property 接口

| property | 返回数据格式 | 说明 |
| :---: | :---: | :---: |
| CPUNum | y | CPU数量 |
| CPUUte | ay | 每个cpu利用率(%), 依次为CPU 0 ~ CPU n |
| DDRTotal | q | 内存容量(GB) |
| DDRUte | y | 内存利用率(%) |

### 1.3.1 property 返回示例

以下示例中
| property | 数据 | 说明 |
| :---: | :---: | :---: |
| CPUNum | 5 | CPU数量 |
| CPUUte | 5 44 90 139 255 99  | 5表示有5个cpu, cpu0 利用率为44%, cpu4利用率为99% |
| DDRTotal | 30755 | 内存容量(GB) |
| DDRUte | 26 | 内存利用率 |

```shell
NAME                                TYPE      SIGNATURE RESULT/VALUE       FLAGS
com.gxmicro.HostInfo                interface -         -                  -
.UpdateInfo                         method    -         i                  -
.CPUNum                             property  y         5                  const
.CPUUte                             property  ay        5 44 90 139 255 99 const
.DDRTotal                           property  q         30755              const
.DDRUte                             property  y         26                 const
org.freedesktop.DBus.Introspectable interface -         -                  -
.Introspect                         method    -         s                  -
org.freedesktop.DBus.Peer           interface -         -                  -
.GetMachineId                       method    -         s                  -
.Ping                               method    -         -                  -
org.freedesktop.DBus.Properties     interface -         -                  -
.Get                                method    ss        v                  -
.GetAll                             method    s         a{sv}              -
.Set                                method    ssv       -                  -
.PropertiesChanged                  signal    sa{sv}as  -                  -
```

# 2. 使用流程

```mermaid
graph LR

op_data[需要获取数据] --> op_method[调用UpdateInfo方法] --> op_property[获取对应的数据]

```

# 3. 调试命令

查找注册dbus中的 service, 以下命令省略--system
```shell
	busctl [--user | --system (default)]
```

根据 service 查找 object
```shell
	busctl tree [service]
```

根据 service 和 object 找到对应interface
```shell
	busctl introspect [service] [object]
```

获取 service 的 property 值
```shell
	busctl get-property [service] [object] [interface] [property]
```

设置 service 的 property 值
```shell
	busctl set-property [service] [object] [interface] [property] [signature] [argument]
```

访问 service 的 method
```shell
	busctl call [service] [object] [interface] [method] [signature] [argument]
```

## 3.1 虚拟机使用命令

查看 host-info 所有的 method 和 property
```shell
	busctl introspect com.gxmicro.HostInfo /com/gxmicro/host_info
```
调用更新property的方法
```shell
	busctl call com.gxmicro.HostInfo /com/gxmicro/host_info com.gxmicro.HostInfo UpdateInfo
```

# X. 参考文档

1. [D-Bus Specification](https://dbus.freedesktop.org/doc/dbus-specification.html)
