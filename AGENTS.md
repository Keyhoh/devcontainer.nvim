# AGENTS.md — リポジトリ向けエージェント指示

目的
- このリポジトリは、Neovim 用プラグイン（Dev Container 内で言語サーバを実行するラッパー）と devcontainer 設定を実装します。Copilot などの自動化エージェントがリポジトリの目的、想定アーキテクチャ、テスト、規約を理解するためのガイダンスを提供します。

1) ビルド・テスト・リンティングのコマンド
- 現在、リポジトリルートにプロジェクトのビルド／テスト／リンティング設定は検出されていません。
- テストランナーを追加したら、このファイルに標準コマンドと単一テスト実行例を追記してください。Lua/Neovim プラグイン向けの一般的選択肢:
  - 単体テスト: busted や plenary.nvim
    - 例（busted）: busted path/to/spec.lua --pattern "specific_test_name"
    - またはプロジェクトのテストランナーで単一の plenary テストを実行
  - 統合/手動テスト（手順記載）: devcontainer を起動し、Neovim を開いて devcontainer exec 経由で LSP が起動し、補完や診断が動作することを確認。

2) 高レベルアーキテクチャ（概観）
- 目的: 元の LSP コマンドを `devcontainer exec` でラップして、言語サーバを Dev Container 内で透過的に実行する。stdin/stdout を保持して Neovim の LSP クライアントが変更なく通信できることを保証する。
- 実行フロー: ワークスペース検出 → コンテナ起動確認（devcontainer up） → argv スタイル配列で LSP コマンドを devcontainer exec でラップ → stdin/stdout を接続してプロセスを起動

3) 主要な慣習（リポジトリ固有）
- argv 配列を保持: コマンドを単一のシェル文字列に連結しない。クォート問題を避けるため argv スタイル配列を使用すること。
- 元の LSP コマンド引数を正確に保持し、入力配列を不意に変更しない。
- LSP の stdout を汚染しない: プラグインや環境のログを stdout に出力しないこと。デバッグ/情報は stderr または Neovim のログ機構を使用する。
- Dev Container 検出はまず `.devcontainer/devcontainer.json` を確認し、可能なら `.devcontainer.json` もサポートする。
- ライフサイクル操作は公式の Dev Container CLI（devcontainer up / devcontainer exec）を使用すること。コンテナ管理ロジックを独自実装しない。
- エラーやデバッグログは Neovim の通知/ログで提示する（stdout は使用しない）。log_level（例: debug/error）設定を提供すること。
- MVP ではホストとコンテナのワークスペースパスが互換であると仮定し、パス変換は実装しない。

4) 確認済みファイルとドキュメント

エージェントの振る舞い方
- プラグイン本体と devcontainer 設定に関する編集や提案に集中してください。
- 実行環境に影響する変更（feature、image、postCreateCommand 等）の場合、コンテナ内で実行する検証手順（コマンドと期待される出力）を明記してください。
- 追加コードは検出/cli/lsp/init のような小さくテストしやすいモジュールに分けることを優先してください。
- リポジトリの目的と無関係なアプリケーションコードを勝手に作成しないでください。

改善希望がある場合
- 追加したテストコマンド、CI ジョブ名、README の該当箇所を教えていただければ本ファイルに反映します。

