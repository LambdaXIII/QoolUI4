# Qool.Chat 模块

聊天域：消息值类型、频道集合、消息源（Beeper）与聊天室，以及配套的宿主应用基类。

Qool.Chat 提供聊天消息系统的基础组件面：

- 值类型：`Message`（qoolmessage——正文/附件/频道/身份）、`MsgChannelSet`
  （频道集合，可解码字符串形态）。
- 消息源：`Beeper`（消息发送者——定向/广播发送、信号转发）。
- 会话：`ChatRoom`（聊天室：成员管理、消息路由）、`ChatRoomManager`
  （C++ 侧会话管理）、`ChatRoomServer`（C++ 侧消息服务）。
- 宿主应用基类：`BasicBeeperApp`、`MessageLogger`（消息记录与去重）。

## 组件参考

- [Beeper](Beeper.md)
- [ChatRoom](ChatRoom.md)
- [Message](Message.md)
- [MsgChannelSet](MsgChannelSet.md)
- [MessageLogger](MessageLogger.md)

> 注：`ChatRoomManager` / `ChatRoomServer` / `BasicBeeperApp` 为纯 C++ 类型，
> 不暴露 QML，无 reference 文档（实现契约见各自源码注释）。
