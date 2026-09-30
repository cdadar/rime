# Rime 配置（个人）

macOS 主力 Squirrel。三套方案：`double_pinyin_flypy`（雾凇的小鹤双拼，主力）、`rime_ice`（雾凇全拼，
与双拼共用词库）、`flypy`（小鹤音形，独立码表，来自 cubercsl/rime-flypy，与双拼零文件重叠）。
万象（amzxyz）全套已清掉，只剩它的 LTS 语法模型（双拼/全拼两套在用）。

## 更新上游：唯一机制是 plum，不要用 git pull

```bash
cd ~/project/source/plum/package/iDvel/ice \
  && no_update=1 bash ~/project/source/plum/rime-install iDvel/rime-ice
```

- *必须先 cd 进包目录再跑*：plum 的 recipe 通配符是在调用时的当前目录展开的，在
  `~/Library/Rime` 里直接跑会静默漏掉上游新增文件，还会刷一屏 `ls: ... No such file`。
  细节见 `README.org` 的「更新」一节。
- `no_update=1` 表示用当前包缓存；不加则 plum 自己 fetch（shallow clone 会 fallback 到
  `reset --hard origin/<branch>`）。
- 更新完在 Squirrel 菜单里「重新部署」，否则不生效。

## 约定

- 自定义只写 `*.custom.yaml`。直接改上游文件下次更新会被覆盖。
- `rime_ice.dict.yaml` 有 3 处本地自定义（启用 `cn_dicts/41448`、追加 `zhwiki`/`bible`），
  每次更新后必须重打 —— plum 会原样覆盖它。
- 文件归属（按上游来源分层；改了上游文件下次 plum 更新就被覆盖，所以自定义只写 `*.custom.yaml`）：
  - iDvel/rime-ice（配方 `all`）：`rime_ice.*`、`double_pinyin*`、`melt_eng.*`、`radical_pinyin.*`、
    `t9.schema.yaml`、`symbols_v.yaml`、`symbols_caps_v.yaml`、`custom_phrase.txt`、`default.yaml`、
    `squirrel.yaml`、`weasel.yaml`、`cn_dicts/`、`en_dicts/`、`lua/`、`others/`、`opencc/`（emoji 三件除外）。
  - rime/* 官方预置（`prelude` → `key_bindings.yaml`/`punctuation.yaml`/`symbols.yaml`；`luna-pinyin` →
    `luna_*`/`pinyin.yaml`；`cangjie` → `cangjie5*`；`wubi` → `wubi*`；`pinyin-simp` → `pinyin_simp*`；
    `stroke` → `stroke*`；`terra-pinyin` → `terra_pinyin*`；`bopomofo` → `bopomofo*`/`detenele`/`zhuyin.yaml`；
    `emoji` → `emoji_suggestion.yaml` + `opencc/emoji{,_category,_word}.*`；`essay` → `essay.txt`）。
  - 单独装的 rime 包：`radical-pinyin` → `radical.schema.yaml`、`radical_flypy.dict.yaml`；
    `xhup` → `xhup*.schema.yaml`；`kaomoji` → `kaomoji.{schema,dict}.yaml`。
  - cubercsl/rime-flypy（小鹤音形，配方 `flypy`）：`flypy.schema.yaml`、`flypy.dict.yaml`、`flypydz.*`、
    `flypyok.*`、`flypy/*.dict.yaml`、`lua/flypy_{date,time}_translator.lua`、`lua/calculator_translator.lua`。
  - 本地手写、不属于任何上游：本文件、`README.org`、所有 `*.custom.yaml`、`custom_phrase_double.txt`、
    `rime.lua`、`flypy.user.txt`/`flypy.user.top.txt`（音形用户词库，运行时生成）、
    `installation.yaml`/`user.yaml`/`*.userdb`（后三者不入 git）。
  - `default.yaml`/`squirrel.yaml`/`weasel.yaml` 多个包都带同名文件，以最后跑的那个配方为准（当前 = ice 版）。
  - 万象（amzxyz/rime_wanxiang）：文件 2026-09-29 已全删（`wanxiang_*`、`dicts/`、`lua/super_*`、
    `custom/`、`README.md`）。
- `*.gram` 语法模型不进 git（已 ignore），靠 grammar 配方重下；仓库里不放几百 MB 的模型。
- `*.custom.yaml` 末尾若被 plum 配方追加了根层 `__patch:` 块，那层优先级高于手写 `patch:`，跑完要把值搬进
  `patch:` 再删块 —— 见「patch 语法」的 `__patch:` 一节。
- git 提交 / 推送由用户手动做，agent 不 push。

## patch 语法（`*.custom.yaml` 里 `patch:` 的可用写法）

| 写法 | 含义 |
| --- | --- |
| `一级/二级/三级: 新值` | 按路径覆盖叶子节点的值 |
| `含列表的项/@n` | 覆盖列表第 n 个元素（n 从 0 起计数） |
| `含列表的项/@last` | 覆盖列表最后一个元素 |
| `含列表的项/@before 0` | 在列表第一个元素之前插入（不建议在补丁中使用） |
| `含列表的项/@after last` | 在列表最后一个元素之后插入（不建议在补丁中使用） |
| `含列表的项/@next` | 在列表最后一个元素之后插入（不建议在补丁中使用） |
| `含列表的项/+: [...]` | 与列表合并的设定值（必须为列表） |
| `含字典的项/+: {...}` | 与字典合并的设定值（必须为字典，注意 YAML 字典无序） |

- `@before` / `@after` / `@next` 依赖下标与元素位置，上游插入元素后即失效——优先用 `/+` 或改 `@n`；
  本仓库已有实例：双拼 `engine/filters/@before 5`。

### `__patch:`（两种，别混）

| 位置 | 谁写的 | 语义 |
| --- | --- | --- |
| 某个节点内（含根层） | Rime / 上游配置 | Rime 伪键：值是**补丁引用列表**，逐条 `文件:/节点?` 套用到所在节点。尾部 `?` = 节点不存在则跳过；文件名可省 `.yaml` |
| 根层 + `# Rx:` 标记 | plum 配方 | 同上语法，但内容是 `patch/+: {...}`，等于往本文件 `patch` 再叠一层 |

- Rime 侧实例：`luna_pinyin.schema.yaml` 根层 `__patch: - luna_pinyin.custom:/patch?`（方案拉自己的 custom 文件）；
  `pinyin.yaml` 教用户写 `speller/algebra/__patch: - pinyin:/zh_z_bufen` 往前叠模糊音规则。
- plum 侧：`scripts/recipe.sh` 的 `patch_file()` 往 `*.custom.yaml` 末尾追加根层 `__patch:` 块，
  重跑同一配方按 `# Rx: <包>:<配方>:<参数>` 标记先删旧块再写。*这层优先级高于手写 `patch:`*，同名键被它顶掉
  （实测会把手写 `schema_list` 从两项顶成一项）；所以配方跑完要把值搬进 `patch:` 再删整块。
- 同族伪键只在被引用的补丁节点里有意义：`__append:` 追加列表、`__merge:` 合并字典（见 `pinyin.yaml` 的模糊音定义）。
- 引用的节点名写错不报错，整份 patch 会静默失效 —— 见「已知坑」。

## 已知坑

- 双拼方案的 filters 不能照抄全拼：`v_filter` 依赖全拼的 `v`=ü，而双拼里 `v`=zh，会让 `va/vi/vu`
  这类码的候选乱序（上游双拼没挂它是对的）；`long_word_filter`（长词优先）上游只给全拼挂了，
  双拼 2026-09-29 用 `engine/filters/@before 5` 补上（下标 0 起，上游往前插 filter 时要跟着改）。
- `*.custom.yaml` 里的 patch 可能**静默失效**：只要 `__include:` 指向不存在的节点，整份 patch 会被丢掉，
  不报错、部署也正常，只有部署产物里能看出来。验证：`grep <你改的键> build/<方案>.schema.yaml`。
  踩过三次：`__include: octagram`（雾凇/万象都没有这个节点）、`algebra_flypy`（真名是
  `algebra_double_pinyin_flypy`；错名字来自 fork 时代的旧示例目录，2026-09-29 已删）。
- `.git/index` 变成 0 字节时（典型诱因：被中断的 `git pull`），`git status` 和 `git reset`
  都会报 `index file smaller than expected`；工作区没丢，修复：
  `rm .git/index && git read-tree HEAD`。

## 当前状态

- 小鹤音形（`flypy`，cubercsl/rime-flypy）2026-09-30 装好并部署：`flypy`/`flypydz`/`flypyok` 三份 schema +
  `flypy/` 码表 + 三个 lua。与双拼零文件重叠（`git status` 只有新增，双拼源文件与 build 产物字节不变，
  差异只在 `__build_info/timestamps/default.custom` 这个 mtime 字段）。验证：`grep -A6 '^schema_list'
  build/default.yaml` 有三项；`ls build/flypy.{schema.yaml,prism.bin,table.bin,reverse.bin}`；
  日志 `dictionary 'flypy' is ready` 且无 E 行。用户词库 = `flypy.user.txt` / `flypy.user.top.txt`（Tab 分隔）。
- rime_ice 已同步到上游 `3aea6d3`（2026-09-25），已部署（鼠须管），已推送到 origin/master。
- 语法模型 `wanxiang-lts-zh-hans.gram`（413MB）不再进 git，靠 grammar 配方重下；万象包本身已清掉，
  但两个方案都还在用它。
- 两个方案的 grammar 参数各自写在 `*.custom.yaml` 里；双拼那套 2026-09-29 起才真正生效
  （此前 `__include: octagram` 让整份 patch 失效）。验证：`grep grammar build/double_pinyin_flypy.schema.yaml`。
- macOS 字体在 `squirrel.custom.yaml`（文楷 13）；`default.custom.yaml` 里那份只给 linux/windows 前端。
- 仓库里还留着一批 rime 预置方案（`luna_pinyin*`/`cangjie5*`/`wubi*`/`pinyin_simp*`/`bopomofo*`/`stroke*`/
  `terra_pinyin*`/`xhup*`/`kaomoji*`/`radical.schema.yaml`+`radical_flypy.dict.yaml` 等，都不在 `schema_list` 里，
  ≈13M），未清理。
