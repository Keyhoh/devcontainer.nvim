# devcontainer.nvim

Neovim プラグイン: Dev Container 内で言語サーバを透過的に実行し、Neovim はホスト上で動作し続けることを目的とします。

概要
- 言語サーバ起動コマンドを `devcontainer exec` でラップし、stdin/stdout を保持して LSP 通信を壊さないことを目標にします。

クイックスタート（想定）
1. `devcontainer` CLI をインストールする。
2. プラグインをインストール（例: packer 等で `devcontainer.nvim` を追加）。
3. Neovim 設定で有効化:

```lua
require("devcontainer").setup()
require("devcontainer").wrap_lsp("gopls")
```

手動検証（最小手順）
- プロジェクトに `.devcontainer/devcontainer.json` を置く。
- コンテナを起動: `devcontainer up --workspace-folder .`
- Neovim を開き、LSP（例: gopls）が `devcontainer exec` 経由で起動し、補完や診断が動作することを確認。

開発とテスト
- コードは `lua/devcontainer/` 以下を想定します（init.lua, detection.lua, cli.lua, lsp.lua）。
- 単体テスト: busted または plenary.nvim を推奨。
  - busted で単一テスト実行例: `busted spec/command_spec.lua --pattern "wrap_cmd"`
  - plenary の単一テストはプロジェクトのテストランナーに従ってください。
- 統合テストは最小 Dev Container を使った手動検証を推奨します。

設定例
```lua
require("devcontainer").setup({
  auto_start = true,
  log_level = "error",
})
```

仕様とエージェント向けガイダンス
- 実装方針や要件は `SPECIFICATION.md` を参照してください。
- 自動化エージェント向けの指示は `AGENTS.md` にあります。

貢献
- まず ISSUE で相談してください。重要な変更はテストとドキュメントを添えて PR を作成してください。

