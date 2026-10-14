# Changelog

Lineshot is an independent fork of [Tendedero](https://github.com/alejandrobujan/tendedero) by Alejandro Buján. Dates use Asia/Shanghai.

## 0.1.1 — 2026-10-14

- Fixed Command-V not pasting in the to-do editor, which runs in a menu-bar app without a standard Edit menu.
- Added focused text editing support for Command-C/X/A/Z and Shift-Command-Z across new tasks, existing tasks, and notes. Other shortcuts and ordinary text input keep their normal behavior.
- Clarified the fork's additions, upstream credit, development branch, and availability of installation packages in both README languages.

修复待办编辑窗口无法用 ⌘V 粘贴的问题，并补齐复制、剪切、全选、撤销和重做。完善中英文 Fork 说明。

## 0.1.0 — 2026-10-13

- Added opt-in plain-text clipboard cards, preserving Unicode, whitespace, and the complete original text when copied.
- Added a persistent first-card to-do notebook with editing, completion, deletion, and free-form notes.
- Centered the notebook and clipping group, expanding toward both edges as content is added; the notebook remains first during scrolling.
- Introduced the Lineshot name, maintainer-supplied icon, separate app identifier and screenshot directory, and one-time import of the earlier personal build's saved notebook.
- Retained the upstream screenshot interactions, automatic hiding, Git history, copyright notice, and license.

首版新增文本卡片、固定待办与随手记、整体居中布局，并采用独立名称和图标。保留原作来源、交互风格与历史。
