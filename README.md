# 反恐精英：网页突击

> 一款基于 [Babylon.js] 开发的网页版第一人称射击游戏（FPS），旨在在浏览器中复刻经典的反恐精英核心体验。

## 📸 游戏截图（或演示）

> *即将更新，不要着急。*

![游戏截图1](./screenshots/demo1.png)
![游戏对战动图](./screenshots/demo.gif)

## ✨ 核心特性

- **核心玩法**：实现 WASD 移动 + 鼠标瞄准/射击，基础枪械（手枪/步枪）切换。
- **敌人 AI**：敌人会主动追击玩家，并具备简单的受击反馈和死亡动画。
- **交互反馈**：包含准星、生命值（HUD）、弹药数量、击杀得分等 UI 界面。
- **物理碰撞**：玩家与地图墙体、障碍物的基础碰撞检测。
- **视觉风格**：（填写你用的风格，如 Low Poly / 写实 / 赛博朋克等）。

## 🛠 技术栈

- **3D 引擎**：[Babylon.js](https://www.babylonjs.com/)
- **构建工具**：[Vite](https://vitejs.dev/)
- **开发语言**：TypeScript / JavaScript
- **物理引擎**：[Cannon-es](https://github.com/pmndrs/cannon-es)
- **包管理**：npm + GitHub Packages

## 🚀 快速开始（本地运行）

如果你想在本地跑起来这个项目，请按以下步骤操作：

### 前置条件
- Node.js (>= 16.x)
- npm 或 yarn

### 安装与启动
```bash
# 1. 克隆仓库
git clone https://github.com/scholardream/Web-version-CS1.6-like-game.git

# 2. 进入目录
cd Web-version-CS1.6-like-game

# 3. 安装依赖
npm install

# 4. 启动开发服务器
npm run dev
