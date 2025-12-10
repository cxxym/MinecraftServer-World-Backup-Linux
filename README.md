# Minecraft Fabric 自动备份脚本 

#脚本AI写的，文档AI写的

支持 **本地 + 远程服务器** 双备份，安全开源版本（无敏感信息）。

该脚本适用于 Minecraft **Fabric 服务端**（或任何基于文件的 Minecraft 服务器）。  
通过 **rsync 双遍复制** 避免存档损坏，并支持 **ZIP 压缩、本地/远程保留数量、自动上传**。

---

## ✨ 功能特点

- ✔ 稳定安全：双遍 rsync，避免半写入导致的损坏  
- ✔ ZIP 压缩（可调压缩级别）  
- ✔ 自动清理本地旧备份  
- ✔ 自动上传至远程服务器（密码登录）  
- ✔ 远程服务器备份也会自动清理  
- ✔ 支持 crontab 定时运行  
- ✔ 完全无人值守

---

## 📌 依赖安装

脚本依赖：

- rsync  
- zip  
- sshpass  
- openssh-client  

缺啥装啥：

```bash
sudo apt install rsync zip sshpass openssh-client -y
