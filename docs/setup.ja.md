# 導入の手順：スキルの導入とエージェントの作成

[ClickHouse Agents](https://clickhouse.com/docs/products/cloud/features/ai-ml/agents) にエージェント「PoC アシスタント」を作る手順です。
ClickHouse Agents（ベータ）を使える ClickHouse Cloud の組織と、評価に使うサービスが必要です。

## 手順の一覧

1. サービスで Remote MCP を有効にする（[1](#1-サービスで-remote-mcp-を有効にする)）
2. `poc-assistant-skill.zip` をダウンロードする（[2](#2-スキルをダウンロードする)）
3. zip をスキルとしてアップロードする（[3](#3-スキルをアップロードする)）
4. エージェントを作り、指示文を貼る（[4](#4-エージェントを作る)）
5. エージェントとのチャットで PoC の計画を作り、エージェントに添付する（[5](#5-poc-の計画を作って添付する)）
6. 設計、設計との照合、統計、見直し、日次のまとめを頼む（[6](#6-使う)）

エージェントを作ったあとの設定は、エージェント自身が案内します。
「何ができますか」「MCP サーバーの足し方を教えて」と聞いてください。

## 1. サービスで Remote MCP を有効にする

エージェントは ClickHouse の Remote MCP を通してサービスにクエリを実行します。
Remote MCP はサービスごとに有効にします。

1. Cloud コンソールで対象のサービスを開きます。
2. **Connect** を押し、**Connect with** で **MCP** を選び、**Enable Model Context Protocol** をオンにします。

参考：https://clickhouse.com/docs/products/cloud/features/ai-ml/remote-mcp

2026-10-15 の試験では、新しいサービスで、エージェントのクエリが「Generative AI features are not enabled for service …」で失敗しました。
サービスの **Settings** で **Enable Generative AI features** をオンにすると通りました。
オンにするときは、組織の管理者が組織を代表して AI 機能の利用条件に同意します。

## 2. スキルをダウンロードする

最新のリリースから [poc-assistant-skill.zip](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/releases/latest/download/poc-assistant-skill.zip) をダウンロードします。
GitHub CLI なら次の 1 行です。

```bash
gh release download -R tkykenmt-at-ch/clickhouse-poc-assistant -p poc-assistant-skill.zip
```

PoC の段ごとの手順を 1 つにまとめたスキルで、公開スキル `clickhouse-architecture-advisor`（[ClickHouse/agent-skills](https://github.com/ClickHouse/agent-skills)、Apache-2.0、変更なし）も同梱しています。
`clickhouse-best-practices` は ClickHouse Agents に組み込まれているので、ダウンロードは不要です。
リリースにある `ch-sizing-export.zip` は、ユーザーが自分でクエリを実行するための一式で、エージェントには使いません。
ソースから zip を作る場合は、[開発者向けの作り方](development.ja.md#作り方)を見てください。

## 3. スキルをアップロードする

1. Cloud コンソールの左のメニューから **ClickHouse agents** を開きます。
2. ClickHouse Agents の左のバーで **スキル** を開きます。
3. **スキルを作成**（＋）→ **スキルをアップロードする** → `poc-assistant-skill.zip` を選びます。
4. 一覧に `poc-assistant` が並んだことを確かめます。

参考：https://clickhouse.com/docs/products/cloud/features/ai-ml/agents/builder/skills

## 4. エージェントを作る

**エージェントビルダー** を開き、**新しいエージェントを作成** を選んで、次の値を入れます。

| 項目 | 値 |
|---|---|
| 名前 | PoC アシスタント |
| 説明 | ClickHouse Cloud の PoC を手伝う。計画、設計、設計との照合、サイジング用の統計、テーブル設計とクエリの見直し、日次の進捗（読み取りのみ） |
| モデル | プロバイダー **Claude**、モデル `claude-sonnet-5-5`（一覧にあるほかのモデルでも動くはずですが、検証したのはこのモデルです） |
| 指示文 | 下の英語の文 |
| ツール | **ツールを追加** → **ClickHouse**（MCP サーバー）、**アーティファクト**、**コードインタープリター** |
| スキル | **Selected** にして、`poc-assistant` と `clickhouse-best-practices` を追加 |

指示文には次の英語の文を貼ります。エージェントはユーザーの言葉で答えます。

```text
You are an assistant that helps run a ClickHouse Cloud PoC. For every request, load the poc-assistant skill first and follow the stage it points to; this includes questions about what you can do and how to set up or use this agent. You run in ClickHouse Agents: MCP servers are added in its MCP settings and Agent Builder screens, never in a configuration file, so do not give steps for other MCP clients. The PoC target and success criteria are in the PoC plan file (a file starting with poc-plan) and the design in the design file (a file starting with poc-design), both in the file context. The user builds the service, tables and ingest; you do not run DDL or loads. For every PoC request, read system tables. Query the user's own tables only to confirm a finding, after showing the queries with their EXPLAIN ESTIMATE and getting the user's approval; return aggregates, not rows. Write numbers only from query results, the plan's ## Results or the sources the skill names; do not guess. When you state how ClickHouse behaves, confirm it with documentation search and attach the URL. Do not recommend a service size, a tier or a price; a cost projection uses the user's assumptions and is not a quote. Do not output user names or e-mail addresses. Never ask for or accept passwords, API keys, client secrets or tokens. Present improvements as candidates to verify, not as decisions. Once per conversation, and at the end of a summary, cost projection or share report, add one line saying the assistant can make mistakes and findings should be checked with the ClickHouse SA. Answer in the user's language.
```

<details>
<summary>指示文の日本語訳（参考。貼るのは上の英語の文）</summary>

あなたは ClickHouse Cloud の PoC を手伝うアシスタントです。どの依頼でも、まず poc-assistant スキルを読み込み、そこが示す段の手順に従います。何ができるか、このエージェントの設定や使い方についての質問も同じです。PoC の対象と成功基準は PoC 計画（poc-plan で始まるファイル）に、設計は設計ファイル（poc-design で始まるファイル）に書いてあり、どちらもファイルのコンテキストにあります。サービス、表、流し込みはユーザーが構築します。DDL や流し込みは実行しません。PoC の依頼では system テーブルを読みます。ユーザーのテーブルにクエリを流すのは、見つけたことを確かめるときだけで、クエリと EXPLAIN ESTIMATE の見込みを示してユーザーの了承を得てからにします。返すのは集計で、行そのものは返しません。数字は、クエリの結果、計画の ## 結果、スキルが挙げる出典だけから書き、推測しません。ClickHouse の振る舞いを述べるときは、ドキュメント検索で確かめて URL を付けます。サービスの規模、ティア、金額の推奨はしません。費用試算はユーザーが決めた前提で計算するもので、見積もりではありません。ユーザー名やメールアドレスは出しません。パスワード、API キー、クライアントシークレット、トークンを求めたり受け取ったりしません。改善の案は決定ではなく、確かめる候補として出します。アシスタントは誤ることがあるので担当 SA に確認してほしい旨を、会話の最初の回答と、まとめ・費用試算・共有用レポートの最後に 1 行だけ添えます。ユーザーの言葉で答えます。

</details>

ツールはこの 3 つだけにします。
コードインタープリターは、費用試算の段が同梱のスクリプトを動かすのに使います。
検証ではそのサンドボックスからネットワークに出られなかったので、スキルは同梱している価格表の写し（毎日更新）を読みます。
組み込みの ClickHouse Agent はスキルが Off になっているので、チャットはこのエージェントで始めます。
正しく設定できていれば、回答の最初に `poc-assistant` を読み込む表示が出ます。

**作成** を押します。あとで変えるときは **保存** を押し、「正常に更新されました」の表示が出るまで待ってください。表示を待たないと、変更が消えることがあります。

初めて ClickHouse のツールを使うときに、接続を求められます。求められない場合は、左のバーの **MCP設定** で **ClickHouse** を探し、**接続** を押します。エージェントから見えるのは、Cloud のユーザーがアクセスできる組織とサービスだけです。

### 任意で足す MCP サーバー

あとから足せるサーバーは 2 種類あり、どちらも足し方をエージェントが案内します（たとえば「AWS のドキュメントを引けるようにしたい」と聞きます）。
案内に使う手順と値は [stages/help.md](https://github.com/tkykenmt-at-ch/clickhouse-poc-assistant/blob/main/clickhouse-agents/skills/poc-assistant/stages/help.md#adding-an-mcp-server) にあります。

- ClickHouse Cloud のリモート MCP（`https://mcp.clickhouse.cloud/mcp`、OAuth）：費用、tier、バックアップ、ClickPipes を読めるようになります。組み込みの **ClickHouse** サーバーにはこれらを読むツールがありません。足さない場合は、エージェントが Cloud コンソールを案内します。
- クラウドプロバイダのドキュメント（AWS Knowledge、Microsoft Learn、Google Developer Knowledge）：プライベート接続、リージョンごとの提供状況、データ源側の IAM など、設計の段で要るプロバイダ側の事実を調べられます。足すのは PoC で使うクラウドの 1 つだけです。足さない場合は、エージェントがプロバイダのドキュメントの URL を案内します。Google のサーバーには、自分の Google Cloud プロジェクトで作った API キーが要ります。キーは Developer Knowledge API だけに使えるよう制限し、`X-Goog-Api-Key` ヘッダーで渡します。

サーバーを足すたびに、エージェントの検索の文の送り先が増えます。
エージェントが送るのは一般的な問い（プロバイダのサービス名、リージョン、機能名）だけで、会社名、テーブル名・列名、データの値、アカウント ID、サービス名は入れません。
サインインが要るサーバーを足すと、そのサーバーにサインインするまで、どのチャットも先へ進みません。
資格情報は **MCP設定** にだけ入れます。クライアント ID とシークレットはチャットにも、リポジトリにも、指示文にも入れません。

エージェントが統計に使うクエリは、この接続自身による system テーブルの読み取りを除き、同じ DB ユーザーのほかのクエリは数に入れます。PoC の負荷をエージェントや書き出しと同じ DB ユーザーで流しても、負荷は数えられます。エージェントがユーザーのテーブルに流すクエリには `log_comment = 'poc-assistant'` を付けるので、数えられません。接続が設定を変えられないときは数えられ、エージェントがそのことを書きます。

参考：https://clickhouse.com/docs/products/cloud/features/ai-ml/agents/quickstart 、https://clickhouse.com/docs/products/cloud/features/ai-ml/agents/builder/mcp-servers

## 5. PoC の計画を作って添付する

1. エージェントとのチャットで、たとえば「PoC の計画を作りたい。サービスは <名前>、期間は <開始> から <終了>。決めたいのは …」と頼みます。エージェントはデータ、クエリ、目標を聞き、出典つきで成功基準の案を出し、合格ラインを聞き返します。
2. エージェントが計画を `poc-plan-<名前>.md` として出力するので、ダウンロードします。
3. エージェントビルダーでエージェントを開き、**ファイルのコンテキスト** の **追加** からファイルをアップロードし、**保存** を押します。

計画には `## 対象` と `## 成功基準` の見出しが必要で、`## 準備`、`## 結果`、`## 経緯` は任意です（英語の `## Target`、`## Success criteria`、`## Setup`、`## Results`、`## Log` でも読めます）。`## 準備` には、つないだものと、この PoC で足す MCP サーバーが並びます。日次のまとめが出す結果の行と、自分で測った結果を `## 結果` に貼り、ファイルを添付し直します。
エージェントを使える人は全員このファイルを読めるので、PoC ごとにエージェントを分けます。

## 6. 使う

| 頼み方 | 段 |
|---|---|
| 「何ができますか」「MCP サーバーの足し方を教えて」 | `help` |
| 「PoC のアーキテクチャと表の設計を考えてください。移行元のスキーマ、サンプル行、主なクエリはこれです」 | `architecture-design` |
| 「表を作りました。設計どおりにできているか見て、次に何をすればいいか教えてください」 | `fit-gap` |
| 「直近 7 日のサイジング用の統計を出してください」 | `sizing-stats` |
| 「PoC 計画のサービスのテーブル設計とクエリを、直近 7 日の記録で見直してください」 | `schema-query-advisor` |
| 「今日の 10:00〜10:20（JST）の負荷試験を振り返ってください。Locust で利用者 10、25、50、100 人の段階です」 | `load-test-review` |
| 「今日の PoC のまとめを書いてください」 | `daily-progress` |
| 「今日の 10:00〜10:20 と 14:00〜14:20（JST）の負荷試験を比べてください。間で並び替えのキーを変えました」 | `load-test-review` |
| 「今週のレビュー用に PoC のまとめを書いてください」 | `summary` |
| 「本番の月額費用を試算してください。Enterprise、AWS ap-northeast-1、2 レプリカ × 32 GiB、24 時間稼働、圧縮後 5 TB」 | `cost-projection` |
| 「今日わかったことを、担当 SA に送る共有用レポートにしてください」 | `share-report` |

日次のまとめは毎朝（出てくる結果の行は計画の `## 結果` に貼ります）、総点検と全体のまとめは週に 1 回、最後にもう一度全体のまとめを目安にします。

画面つきで 1 件の PoC を最後まで追った例は、[通しの手順](walkthrough.ja.md)にあります。

## 新しいリリースへの入れ替え

スキルはその場で差し替えられず、スキルを削除するとエージェントからも外れます。次の順で入れ替えます。

1. 新しい `poc-assistant-skill.zip` をダウンロードします。
2. **スキル** で `poc-assistant` を開いて削除します。同じ名前のスキルが残っていると、アップロードは失敗します。
3. 新しい zip をアップロードします。
4. エージェントビルダーでエージェントを開き、**スキル** に `poc-assistant` をもう一度追加して **保存** を押します。「正常に更新されました」の表示を待ちます。

v0.5.0 以前から移るときは、`poc-*` のスキルすべてと `clickhouse-architecture-advisor` を削除し、`poc-assistant-skill.zip` をアップロードします。
そのうえで、エージェントの指示文を[4](#4-エージェントを作る)の文に差し替え、**スキル** で `poc-assistant` と `clickhouse-best-practices` を選びます。

## 制約（2026-10-08 時点）

- 定期実行（Scheduled chats）：機能はありますが、ClickHouse のツールを付けたエージェントで予定を作ると、再接続したあとも「Reconnect this MCP server before enabling the schedule.」が出続けます。変わるまでは、日次のまとめと週次の総点検はエージェントに頼んで実行します。
- メモリ：メモリの画面で手で作った項目は、検証では会話に渡りませんでした。そのため、計画はファイルのコンテキストで渡します。
- Agent API：使えないので、外からエージェントを呼べません。
- ClickHouse Agents はベータなので、画面や動きが変わることがあります。
