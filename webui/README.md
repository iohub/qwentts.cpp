# Qwen TTS WebUI

一个**零依赖、零构建**的单文件网页控制台，对接本仓库自带的 OpenAI 兼容 TTS 服务（`tts-server`）。
所有 HTML / CSS / JavaScript 都内嵌在 `webui/index.html` 里，不引用任何外部 CDN，不需要 npm、打包或编译。

---

## 一、打开方式（二选一）

### 方式 1：直接双击打开

用浏览器打开 `webui/index.html` 即可（地址栏是 `file://...`）。
服务端已设置 `Access-Control-Allow-Origin: *`，所以 `file://` 页面也能直接跨域调用接口，**不需要代理服务器**。

### 方式 2：跑本地静态服务器

```bash
./webui/serve.sh          # 默认 http://127.0.0.1:5173/
./webui/serve.sh 8000     # 自定义端口
```

然后在浏览器访问终端里打印的地址。这个脚本只是把 `webui/` 目录当静态文件托管，与语音合成本身无关。

---

## 二、必须先启动 tts-server

WebUI 只负责界面，合成要靠 `tts-server` 常驻进程。先编译（见仓库根 README / `buildall.sh`），再启动：

```bash
./build/tts-server \
    --model models/qwen-talker-1.7b-customvoice-Q8_0.gguf \
    --codec models/qwen-tokenizer-12hz-Q8_0.gguf \
    --port 8080
```

可选参数：`--host`、`--alias`（覆盖 `/v1/models` 里显示的模型名）、`--lang`（请求未带 `language` 时的默认语言）、`--device`、`--max-batch`。

启动后在 WebUI 顶部点「刷新」，指示灯变绿显示「已连接」、右侧出现模型名即为打通。
如果服务端口不是 8080，改顶部「服务地址」输入框（会自动记到 localStorage）。

---

## 三、页面能做什么

- **合成文本**：大号输入框 + 实时字数；超过 2000 字会提示 wav 模式的 120s 写超时风险。`Cmd/Ctrl + Enter` 直接生成。
- **流式 pcm**：边生成边用 Web Audio 播放，实时显示「已接收 X KB / 约 Y 秒音频」；按钮变「停止」可随时中断（abort + 停掉所有已排程音频）。
- **wav**：整句返回后给原生播放器和「下载 .wav」链接。
- **采样参数**：seed / max_new_tokens / temperature / top_k / top_p / repetition_penalty 以及 subtalker 的三项。
  **只有勾选左侧复选框的参数才会写进请求 JSON**，不勾选 = 不发送 = 保留引擎默认值；面板顶部的灰字就是这个意思。
  另有「全部默认 / 贪心 / 稳定 / 创意」四个预设。
- **音色与语言**：音色按「内置音色 / 已注册音色」分组；语言可选常用项或自定义。
- **克隆音色注册**：上传 `.wav`（服务端自己抽 latents）或 `.spk` + `.rvq` 预算好的 latents；勾选参考文本可启用 ICL 克隆。已注册音色可逐个删除。
- **历史记录**：最近 20 条，点击可回填文本与全部参数。

所有设置（服务地址、上次的参数、历史）都存在 localStorage，键名统一 `qwentts.` 前缀。

---

## 四、常见问题

**1. 指示灯一直是「连接失败」**

- `tts-server` 没启动，或端口不一致：确认 `--port` 与页面上的服务地址一致。
- 服务只监听 `127.0.0.1`：从别的机器访问要加 `--host 0.0.0.0`。
- 浏览器控制台（F12）里会有具体的 `net::ERR_CONNECTION_REFUSED`。

**2. 生成报 `HTTP 502`**

服务端推理失败（模型/显存/输入问题），页面上会显示服务端返回的 `error.message` 原文，按提示排查。`HTTP 400` 多半是参数越界（例如 `top_p` 传了 0）。

**3. wav 模式长文本断连 / 报网络错误**

wav 是合成完再一次性返回，服务端写超时 120s。长文本请改用 **pcm 流式**，或调小 `max_new_tokens`（1 token ≈ 0.08 秒，2048 ≈ 163 秒上限）。页面在文本超过 2000 字时也会提示。

**4. 注册克隆音色报 `voice registration is only valid for base models`**

克隆只支持 **base 类型模型**。customvoice / voicedesign 模型（例如 `qwen-talker-1.7b-customvoice`）不支持，换个 base 模型的 GGUF 再启动服务即可。

**5. 音色下拉里没有 `vivian`**

`/v1/audio/voices` 返回的是当前模型的内置 speaker 列表；没有 `vivian` 时页面会自动选第一个内置音色。模型里确实没有 speaker 时，下拉只剩「（不指定）」。

**6. 改了参数但听不出区别 / 请求里没有该字段**

先确认那个参数左侧的复选框已勾选——未勾选时不会出现在请求体里。可以在浏览器 F12 → Network 里查看 `/v1/audio/speech` 的 Request Payload。

**7. 页面样式/行为异常**

硬刷新（`Cmd/Ctrl + Shift + R`）清缓存；或在 F12 → Application → Local Storage 删掉 `qwentts.*` 键恢复默认。
