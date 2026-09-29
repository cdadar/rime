# Rime 配置（个人）

macOS 主力 Squirrel。主力小鹤双拼（flypy）键位：`wanxiang_pro`（万象 + 辅助码）、
`double_pinyin_flypy`（小鹤双拼）；另挂 `rime_ice`（雾凇，全拼，与双拼共用词库）。

## 更新上游：唯一机制是 plum，不要用 git pull

```bash
# 雾凇 rime_ice ← iDvel/rime-ice
cd ~/project/source/plum/package/iDvel/ice \
  && no_update=1 bash ~/project/source/plum/rime-install iDvel/rime-ice

# 万象 ← amzxyz/rime_wanxiang（飞鹤辅助码分支）
cd ~/project/source/plum/package/amzxyz/rime_wanxiang \
  && no_update=1 bash ~/project/source/plum/rime-install amzxyz/rime_wanxiang@wanxiang-flypy-fuzhu:plum/full
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
- 文件归属：iDvel/rime-ice → `rime_ice.*`、`double_pinyin*`、`en_dicts/`；
  amzxyz/rime_wanxiang → `wanxiang_*`、`dicts/`、`lua/super_*`、`custom/`、`README.md`。
  两个包共写同一批文件名（`default.yaml`、`weasel.yaml`、`custom_phrase.txt`、
  `lua/*`、`opencc/*`）→ *最后装的赢*。
- `README.md` 是万象包随附文档的副本，会被 plum 覆盖，不要手改；本项目自己的文档是 `README.org`。
- `*.gram` 语法模型不进 git（已 ignore），靠 grammar 配方重下；仓库里不放几百 MB 的模型。
- `*.custom.yaml` 末尾带 `# Rx: <配方>` 标记的 `__patch:` 块是 plum 配方写的，重跑配方会替换；
  和手写的 `patch:` 参数重复时定不好谁生效，要按自己的值就得删掉那块。
- git 提交 / 推送由用户手动做，agent 不 push。

## 已知坑

- `*.custom.yaml` 里的 patch 可能**静默失效**：只要 `__include:` 指向不存在的节点，整份 patch 会被丢掉，
  不报错、部署也正常，只有部署产物里能看出来。验证：`grep <你改的键> build/<方案>.schema.yaml`。
  （2026-09-29 修过一次：双拼方案因 `__include: octagram` 导致 grammar 等全部没生效。）
- `.git/index` 变成 0 字节时（典型诱因：被中断的 `git pull`），`git status` 和 `git reset`
  都会报 `index file smaller than expected`；工作区没丢，修复：
  `rm .git/index && git read-tree HEAD`。

## 当前状态

- rime_ice 已同步到上游 `3aea6d3`（2026-09-25），已部署（2026-09-29 15:12），已提交未推送。
- 语法模型 `wanxiang-lts-zh-hans.gram`（413MB）不再进 git，靠 grammar 配方重下。
- 三个方案的 grammar 参数各自写在 `*.custom.yaml` / 万象 schema 里；双拼那套 2026-09-29 起才真正生效
  （此前 `__include: octagram` 让整份 patch 失效）。验证：`grep grammar build/double_pinyin_flypy.schema.yaml`。
- macOS 字体在 `squirrel.custom.yaml`（文楷 13）；`default.custom.yaml` 里那份只给 linux/windows 前端。
- 万象部分仍是 2026-01-20 快照，上游已到 `98e9887`（2026-09-28），是否更新待定。
