# コーディングエージェントで使う

スキルの中身は、Markdown と SQL のファイル、それに Python のスクリプト 1 本です。
そのため、ClickHouse Agents 以外のエージェントでも同じ手順で動きます。
このページでは、手元のコーディングエージェントにスキルを入れ、クエリは ClickHouse Cloud の Remote MCP サーバーで流す使い方を説明します。

モデルの提供元や推論の場所を自分で選びたい場合と、組織で ClickHouse Agents を使えない場合に向いています。
[ClickHouse Agents](setup.ja.md) を使えば、手元に何も入れずに同じ段を使えます。

Claude Code で動作を確かめました（2026-11-17）。
Agent Skills の形式（`SKILL.md` を置いたフォルダー）を読めて、リモートの MCP サーバーに接続できるエージェントなら同じように動く見込みですが、確かめていません。

## 必要なもの

- フォルダーからスキルを読めて、OAuth で HTTP のリモート MCP サーバーに接続できるコーディングエージェント
- Remote MCP サーバーを有効にした ClickHouse Cloud のサービス（[導入の手順 1](setup.ja.md#1-サービスで-remote-mcp-を有効にする)）
- 手元の Python 3。費用の試算で価格表を取得するのに使います。ない場合は、スキルに同梱した価格表の写しを使います。

## 1. スキルを入れる

[poc-assistant-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-assistant-skill.zip) をダウンロードし、エージェントのスキル用フォルダーに展開します。
zip の中身は `poc-assistant/` というフォルダー 1 つです。
段のファイルは `SKILL.md` と同じ階層の `queries/`、`reference/`、`tools/`、`vendor/` を参照するので、フォルダーの構成は変えないでください。

Claude Code では、プロジェクトのフォルダーに置いたスキルはそのプロジェクトだけで使われます。

```bash
mkdir -p .claude/skills
unzip poc-assistant-skill.zip -d .claude/skills/
```

入れ替えるときは、`.claude/skills/poc-assistant/` を消してから新しい zip を展開します。

## 2. ClickHouse Cloud の Remote MCP サーバーに接続する

`https://mcp.clickhouse.cloud/mcp` をリモートの MCP サーバーとして追加し、エージェントに求められたら ClickHouse Cloud のアカウントでサインインします。
Claude Code では次の 1 行です。

```bash
claude mcp add --transport http clickhouse-cloud https://mcp.clickhouse.cloud/mcp
```

接続は読み取り専用です。
サインインした本人として動くので、そのアカウントで見える組織とサービスがすべて見えます。
スキルは PoC のサービスを最初に 1 回たずね、以後はそのサービスだけを使います。

参考：https://clickhouse.com/docs/products/cloud/features/ai-ml/remote-mcp

## 3. PoC ごとにフォルダーを 1 つ用意する

その PoC 専用のフォルダーでエージェントを起動します。
スキルは計画（`poc-plan-<名前>.md`）と設計（`poc-design-<名前>.md`）をそのフォルダーから読み、計画、設計、CSV、共有レポートを同じフォルダーに書きます。
ファイルを添付する操作はありません。

日次ノートの結果の行と自分で測った値は、[導入の手順 5](setup.ja.md#5-poc-の計画を作って添付する) と同じく、計画の `## 結果` に貼ります。

## 4. 使う

ふつうの言葉で頼みます。最初の 1 回はスキルの名前を入れてください。

- 「poc-assistant スキルを使ってください。PoC を計画したいです。サービスは `<名前>`、期間は `<開始>` から `<終了>` です。判断したいのは…」
- 「サービスを設計と照らし合わせてください。」
- 「今日の日次ノートを書いてください。」

段は ClickHouse Agents と同じです。それぞれの段が何を返すかは [通しの手順](walkthrough.ja.md) を見てください。

## ClickHouse Agents との違い

| | ClickHouse Agents | コーディングエージェント |
|---|---|---|
| 計画と設計 | エージェントにファイルのコンテキストとして添付する | 作業フォルダーのファイル |
| スキルが渡すファイル | ダウンロードできるアーティファクト | 作業フォルダーに書かれるファイル |
| サービス | エージェントが接続しているサービス | 会話ごとに 1 回伝える |
| `clickhouse-best-practices` | 組み込み | [ClickHouse/agent-skills](https://github.com/ClickHouse/agent-skills) から自分で入れる。ない場合、スキルはドキュメントの URL を根拠にする |
| ドキュメント検索 | 組み込み | ClickHouse のドキュメントを検索するツールがつながっていれば使う。ない場合、スキルは参照ファイルにある URL だけを引用する |
| 価格表 | スキルに同梱した写し（コードのサンドボックスはネットワークに出られない） | Python がネットワークに出られれば clickhouse.com から取得する |
| 定期実行、メモリ、エージェントの共有 | ClickHouse Agents の機能として使える | 使えない。日次ノートは毎日頼む |
| `help` の段の導入案内 | ClickHouse Agents の画面の手順を示す | このページを案内する |

## 制約

- **エージェント自身のクエリが結果に混ざる。** Remote MCP サーバーは、system テーブルへの補助のクエリを別のデータベースユーザーで流します。スキルのクエリはこれを除けません。日次ノートに新しいクエリの型として出ることがあり、クエリの件数にも入ります。対象は `system.roles`、`system.role_grants`、`system.databases` への小さな `SELECT` です。
- **費用は組織全体が返る。** Cloud の費用のツールは、組織のすべてのサービスを返します。スキルが使うのは PoC のサービスの行だけですが、ほかの行も会話を通ります。
- **承認は利用者が行う。** 利用者のテーブルにクエリを流す前に、スキルはクエリと `EXPLAIN ESTIMATE` を示して承認を待ちます。この確認を飛ばす設定にはしないでください。
- **送り先を確かめる。** 依頼の文、クエリの結果、計画は、コーディングエージェントが使うモデルの提供元に送られます。PoC のデータを送ってよいか、その提供元の利用条件を確かめてください。
