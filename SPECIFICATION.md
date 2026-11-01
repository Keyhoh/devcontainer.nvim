# Neovim Dev Container LSP プラグイン

## 1. 目的

Neovim 本体はホスト上で動作し続けたまま、言語サーバ（Language Server）を Dev Container 内で実行できるようにする Neovim プラグインを作成する。

初期の目標は、既存の Neovim LSP 設定を最小の設定変更で Dev Container 内でも動作させること。

プラグインは LSP プロトコル自体を実装したりプロキシしたりしてはならない。

代わりに、言語サーバの起動コマンドを Dev Container CLI 経由で実行するコマンドに透過的に置き換える。

### 置換前

```text
Neovim
  │
  │ stdin/stdout
  ▼
Language Server
```

### 置換後

```text
Neovim
  │
  │ stdin/stdout
  ▼
devcontainer exec
  │
  ▼
Dev Container
  │
  ▼
Language Server
```

LSP の JSON-RPC メッセージは変更せずにそのまま通過する必要がある。

---

## 2. 範囲

### MVP（最小実用製品）

MVP は以下をサポートする必要がある：

1. Dev Container 設定を検出すること。
2. 必要なら Dev Container を起動すること。
3. LSP コマンドを `devcontainer exec` でラップすること。
4. stdin/stdout を保持し、Neovim が通常どおり言語サーバと通信できること。
5. 現在のプロジェクト／ワークスペースを Dev Container のワークスペースとして使うこと。
6. Neovim のネイティブ LSP API との最小限の統合。

例：

```lua
vim.lsp.config("gopls", {
  cmd = { "gopls" },
})
```

は次と同等に変換できるべきである：

```bash
devcontainer exec \
  --workspace-folder /path/to/project \
  gopls
```

プラグインは LSP の JSON-RPC メッセージを解析したり変更したりしてはならない。

---

## 3. MVP の明示的な対象外

初期段階で以下は実装しないこと：

* LSP JSON-RPC のプロキシング
* TCP のプロキシング
* コンテナ内でのカスタム TCP サーバ
* ホストとコンテナ間のパス変換
* LSP URI の自動変更
* DAP（デバッガ）統合
* フォーマッタ統合
* リンター統合
* ポートフォワーディング管理
* コンテナシェル管理
* コンテナイメージ管理
* カスタム言語サーバの実装

これらは将来的に検討できる。

---

## 4. 設計原則

### 4.1 LSP 層を透過的に保つ

プラグインは以下のような個々の LSP メソッドの中身を知るべきではない：

```text
textDocument/definition
textDocument/completion
textDocument/hover
textDocument/publishDiagnostics
```

プラグインは LSP プロトコルの下位で動作し、言語サーバの起動方法のみを変更する。

---

### 4.2 stdin/stdout を保持する（重要）

これは極めて重要である。

Neovim は LSP プロセスが stdin/stdout を通じて通信することを期待している。
結果として得られるプロセスチェーンは、Neovim が直接言語サーバを起動したかのように振る舞う必要がある：

```text
Neovim stdin
    ↓
devcontainer exec stdin
    ↓
Language Server stdin
```

および：

```text
Language Server stdout
    ↓
devcontainer exec stdout
    ↓
Neovim stdout
```

stdout に余計な出力を書いてはならない。

ログやデバッグ情報は stderr か Neovim のログ機構に出力すること。

---

## 5. Dev Container の検出

プラグインは現在のワークスペースが Dev Container を使っているかを検出する必要がある。

まず標準的な以下をサポートする：

```text
.devcontainer/devcontainer.json
```

可能なら単一ファイル形式の：

```text
.devcontainer.json
```

プロジェクトルートはカレントバッファ／ワークスペースから決定すべきであり、常にシェルの作業ディレクトリに依存してはならない。

Dev Container 設定が見つからない場合は、LSP コマンドを変更せずそのままにすること。

---

## 6. コンテナのライフサイクル

コンテナ内で LSP プロセスを起動する前に、Dev Container が起動していることを確認する。

公式の Dev Container CLI を使用すること。

概念的には：

```bash
devcontainer up --workspace-folder <workspace>
```

既に稼働しているコンテナを不必要に再作成・再起動しないようにすること。

ライフサイクルの挙動は Dev Container CLI に委ね、独自にコンテナ管理ロジックを実装しないこと。

---

## 7. LSP コマンドのラップ

主要な抽象は以下のような関数であるべき：

```lua
devcontainer.wrap_cmd(cmd, workspace)
```

例：

```lua
local wrapped = devcontainer.wrap_cmd({
  "gopls",
}, "/home/user/project")
```

結果：

```lua
{
  "devcontainer",
  "exec",
  "--workspace-folder",
  "/home/user/project",
  "gopls",
}
```

引数は正確に保持されなければならない。

例えば：

```lua
{
  "typescript-language-server",
  "--stdio",
}
```

は次のように概念的に変換されるべきである：

```bash
devcontainer exec \
  --workspace-folder /project \
  typescript-language-server \
  --stdio
```

コマンドをシェル文字列に連結してはならない。

シェルのクォート問題を避けるため、argv スタイルの配列を使用すること。

---

## 8. Neovim との統合

Neovim のネイティブ LSP API を優先し、無関係な API をモンキーパッチすることは避ける。

プラグインは明示的な統合ポイントを提供するべきである。

例：

```lua
require("devcontainer").setup()
```

および：

```lua
require("devcontainer").wrap_lsp("gopls")
```

または同等の API。

具体的な API 設計は現行の Neovim LSP API に合わせて選べる。

既存の LSP 設定を大きく変えずに使えることが望ましい。

例えば次の設定がそのまま動作すること：

```lua
vim.lsp.config("gopls", {
  cmd = { "gopls" },
})
```

プラグインは利用者に全ての LSP コマンドを書き換えさせる（例：

```lua
cmd = {
  "devcontainer",
  "exec",
  ...
}
```

のように）ことを強制してはならない。

---

## 9. 推奨内部アーキテクチャ

小さく独立したモジュールを好む。

想定構成例：

```text
lua/
  devcontainer/
    init.lua
    detection.lua
    cli.lua
    lsp.lua
```

各モジュールの責務：

### `detection.lua`

* ワークスペースルートを見つける。
* `.devcontainer/devcontainer.json` を検出する。
* 必要なら `.devcontainer.json` も検出する。

### `cli.lua`

Dev Container CLI を呼び出す薄い抽象を提供する。

例：

```lua
M.up(workspace)
M.exec(workspace, cmd)
```

CLI 層は以下を呼び出す責務を持つ：

```bash
devcontainer up
devcontainer exec
```

### `lsp.lua`

LSP 固有の統合を提供する。

責務：

* LSP コマンドをラップする。
* コンテナが起動していることを保証する。
* 元の LSP コマンド引数を保持する。
* LSP プロトコルメッセージを変更しない。

### `init.lua`

公開 API と設定処理。

---

## 10. エラー処理

プラグインは次のような状況について明確なエラーを提示すること：

* `devcontainer` CLI がインストールされていない。
* Dev Container 設定が存在しない。
* Dev Container を起動できない。
* `devcontainer exec` が失敗する。
* 言語サーバ実行ファイルがコンテナ内に存在しない。

エラーは Neovim の通常の通知／ログ機構で見えるようにすること。

診断メッセージを stdout に書いてはならない（stdout は LSP プロトコル用であるため）。

---

## 11. ロギング

オプションのデバッグロギングを用意する。

例：

```lua
require("devcontainer").setup({
  log_level = "debug",
})
```

デバッグログは次のような情報を提供するべきである：

```text
Detected workspace: /home/user/project
Detected Dev Container: /home/user/project/.devcontainer/devcontainer.json
Starting Dev Container
Wrapping LSP command:
  gopls
With:
  devcontainer exec --workspace-folder /home/user/project gopls
```

デフォルトで LSP メッセージの内容をログしないこと。

---

## 12. 設定

設定は最小限に保つ。

想定される設定例：

```lua
require("devcontainer").setup({
  auto_start = true,
  log_level = "error",
})
```

推奨デフォルト：

```text
auto_start = true
log_level = "error"
```

MVP に不要な設定オプションは避けること。

---

## 13. 重要な制約: ワークスペースパス

MVP では、ホスト側のワークスペースパスとコンテナ内のワークスペースパスが互換であると仮定する。

パス変換はまだ実装しない。

例えば推奨設定は：

```text
Host:
/home/user/project

Container:
/home/user/project
```

または Neovim が生成する LSP URI がコンテナ内でも有効になる設定。

パス変換は将来の機能として実装可能。

---

## 14. テスト

実装は純粋ロジックのためのテストを含むべきである。

最低限：

### コマンドラッピング

入力：

```lua
{ "gopls" }
```

期待：

```lua
{
  "devcontainer",
  "exec",
  "--workspace-folder",
  "/project",
  "gopls",
}
```

入力：

```lua
{
  "typescript-language-server",
  "--stdio",
}
```

期待：

```lua
{
  "devcontainer",
  "exec",
  "--workspace-folder",
  "/project",
  "typescript-language-server",
  "--stdio",
}
```

### 不変性

元のコマンド配列が予期せず変更されないこと。

### ワークスペース検出

テスト：

```text
/project/.devcontainer/devcontainer.json
```

が正しく検出されること。

### 設定不在

`.devcontainer` がないワークスペースは安全に処理されること。

---

## 15. 統合テスト

最小 Dev Container を使った統合テストまたは手順書を用意する。

例：

```text
/project/
├── .devcontainer/
│   └── devcontainer.json
├── go.mod
└── main.go
```

コンテナ内に `gopls` が含まれていること。

プロジェクト内で Neovim を起動し、次を検証する：

1. Dev Container が自動的に起動する。
2. Neovim が `devcontainer exec` 経由で `gopls` を起動する。
3. 診断が動作する。
4. 補完が動作する。
5. 定義へ移動が動作する。
6. ホバーが動作する。
7. LSP 接続が安定している。
8. `devcontainer` やプラグインの診断出力が LSP の stdout を破壊しない。

---

## 16. 対象外（Non-goals）

実装は全ての Dev Container 統合問題を解決しようとしてはならない。

MVP が特に答えるべき質問は：

> Neovim が既存の言語サーバを `devcontainer exec` で透過的にコンテナ内で実行できるか？

これに Yes と答えられれば MVP は成功である。

---

## 17. 将来の方向性

アーキテクチャは将来機能を許容する余地を残すべきであるが、今は実装しない。

将来の機能例：

```text
LSP
 │
 ├── stdio → devcontainer exec
 │
 └── TCP   → port forwarding

DAP
 │
 └── port forwarding

Formatter
 │
 └── devcontainer exec

Linter
 │
 └── devcontainer exec

Terminal
 │
 └── devcontainer exec
```

長期的な目標は、Neovim 自体はホストに残しつつ Dev Container を開発環境にすることである。

そのためコア実装を LSP に特化しすぎないこと。

---

## 18. 実装優先度

次の順で実装する：

1. プロジェクト／Dev Container 検出
2. Dev Container CLI ラッパー
3. `devcontainer up`
4. 汎用コマンドラッピング
5. LSP 統合
6. エラー処理
7. ロギング
8. 単体テスト
9. 統合テスト

MVP が動作するまで将来機能を実装しないこと。

---

## 19. 成功基準

次の設定が動作すること：

```lua
require("devcontainer").setup()

vim.lsp.config("gopls", {
  cmd = { "gopls" },
})

vim.lsp.enable("gopls")
```

プロジェクト内に次が含まれる場合：

```text
.devcontainer/devcontainer.json
```

Neovim は自動的に：

```text
1. Dev Container を検出する
2. 必要なら起動する
3. gopls をコンテナ内で起動する
4. Neovim の LSP クライアントを stdin/stdout を通じて gopls に接続する
```

Neovim 側から見て通常の LSP 接続と同様に振る舞うこと。

プラグインは LSP プロトコル自体を変更してはならない。

