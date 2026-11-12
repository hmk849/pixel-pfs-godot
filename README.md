# Pixpfs

2v2 战术竞技 FPS（Godot 4.4）。泰坦陨落式机动（二段跳、蹬墙跑、滑铲跳）、CoD 风格滑铲、三角洲行动式射击手感、Valorant 风格简约 UI。

## 云端编译（GitHub Actions）

1. 在 GitHub 新建仓库，把本目录全部内容推送到 `main` 分支。
2. 仓库 Settings → Pages → Source 选择 **GitHub Actions**。
3. 推送后 Actions 自动构建：
   - Web 版：自动部署到 `https://<用户名>.github.io/<仓库名>/`
   - Windows 版 / Web 版压缩包：在 Actions 运行记录的 Artifacts 中下载
   - iOS 版（未签名 IPA）：在 Actions 运行记录的 Artifacts 中下载 `pixpfs-ios-ipa`，用自签工具签名后安装
4. 也可在 Actions 页面手动点击 Run workflow。

## 本地运行

用 Godot 4.4.x 打开 `project.godot`，按 F5 即可。

## 操作

| 按键 | 功能 |
|---|---|
| WASD | 移动 |
| 空格 | 跳跃（空中再按一次二段跳） |
| Shift | 疾跑 |
| C | 蹲下；疾跑中按 C 滑铲（滑铲中跳跃可保持速度） |
| 空中贴近墙壁 | 蹬墙跑，蹬墙跑中按空格蹬墙跳 |
| 鼠标左键 / 右键 | 开火 / 开镜 |
| R / F / Q | 换弹 / 检视 / 切换主副武器 |
| E | 训练场武器试验台 |
| ESC | 暂停 |

所有键位可在 设置 → 键位 中修改。

## 目录结构

- `scripts/autoload` 全局设置、输入、音频
- `scripts/core` 入口、开场动画、大厅
- `scripts/game` 玩家、武器、Bot、地图、对战、训练场
- `scripts/ui` HUD、设置、仓库、角色、触屏控制
- `scripts/data` 武器 / 干员数据表
- `tools` 资源生成脚本（贴图、音效、字体子集化）
