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
- `*.custom.yaml` 末尾带 `# Rx: <配方>` 标记的 `__patch:` 块是 plum 配方写的，重跑配方会替换；
  和手写的 `patch:` 参数重复时定不好谁生效，要按自己的值就得删掉那块。
- git 提交 / 推送由用户手动做，agent 不 push。

## 已知坑

- `.git/index` 变成 0 字节时（典型诱因：被中断的 `git pull`），`git status` 和 `git reset`
  都会报 `index file smaller than expected`；工作区没丢，修复：
  `rm .git/index && git read-tree HEAD`。

## 当前状态

- rime_ice 已同步到上游 `3aea6d3`（2026-09-25）；语法模型已换成新 LTS 版（413MB）。
- 改动已 stage（46 个文件）+ 未跟踪的新文件，尚未 commit。
- 万象部分仍是 2026-01-20 快照，上游已到 `98e9887`（2026-09-28），是否更新待定。
- 同步后尚未「重新部署」，待验证。
