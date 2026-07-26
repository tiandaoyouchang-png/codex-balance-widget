# Codex Balance Widget

一个原生 macOS WidgetKit 小组件，自动识别当前 Codex 账号返回的额度计费方式，并选择对应布局。

双窗口账号（例如 5 小时额度＋7 天额度）：
![Codex Balance Widget](QA/implementation-dual-window-option-2-final.png)

单窗口账号（例如月度额度）：
![Codex Monthly Balance Widget](QA/implementation-scheme-4-final.png)

## 特点

- 原生 WidgetKit，不创建悬浮窗口。
- 自动读取服务端返回的额度窗口数量和周期长度，无需手动选择模式。
- 单窗口使用大数字月度／周期卡片；双窗口使用两条独立额度轨道。
- 显示每个真实额度窗口的剩余、已用和重置时间。
- 无界面的后台宿主每 10 分钟刷新一次，不占用 Dock 或顶部状态栏。
- 只向 App Group 写入规范化额度数据，不保存或复制 Codex 登录令牌。
- 支持 macOS 小号与中号小组件。

> [!NOTE]
> 这是非官方项目，依赖本机 Codex 的实验性 `app-server` 接口。实际可见的额度窗口取决于账号、套餐和服务端返回值；应用不会伪造账号没有的额度。

## 自动识别

应用不提供手动模式开关，而是直接使用当前账号的真实额度数据：

- 返回一个窗口：显示单窗口卡片，并根据周期长度标注“5 小时额度”“7 天额度”“月度额度”等真实周期。
- 返回两个窗口：按周期从短到长显示双轨卡片，每条轨道独立显示剩余、已用和重置时间。
- 返回其他周期组合：沿用相同规则自适应，不把多个额度合并成虚假的总百分比。

## 环境要求

- macOS 14 或更高版本
- Xcode 15 或更高版本
- 已安装并登录 ChatGPT、Codex App，或可用的 Codex CLI
- 可用于 App Group 的 Apple Developer Team

## 构建

1. 用 Xcode 打开 `CodexBalance.xcodeproj`。
2. 在 `CodexBalance` 和 `CodexBalanceWidgetExtension` 两个 Target 中选择同一个 Signing Team。
3. 如有 Bundle ID 冲突，将两个 Bundle ID 改成自己的唯一标识。
4. 运行 `CodexBalance` Scheme。
5. 在桌面空白处右键，选择“编辑小组件”，搜索“Codex 余额”并添加。

项目使用 `$(TeamIdentifierPrefix)codexbalance.shared` 作为 App Group，因此两个 Target 必须使用同一个 Team 签名。

## 数据与隐私

宿主应用从本机 Codex 进程读取额度，只把以下字段写入共享容器：

- 套餐名称
- 已用百分比
- 额度周期长度
- 重置时间
- 重置额度次数
- 最近更新时间

Codex 登录令牌不会进入 Widget 扩展或共享 JSON。

## 目录

- `App/`：无界面后台宿主与本机 Codex 数据读取。
- `Widget/`：自动识别单／双窗口状态的 WidgetKit 视图与共享快照模型。
- `References/`：双窗口与月度单窗口的视觉参考。
- `QA/`：两种状态的原生尺寸预览、对照图和可复现渲染源码。
- `DESIGN.md`：产品和视觉规范。
- `design-qa.md`：最后一次视觉还原检查。

## License

[MIT](LICENSE)
