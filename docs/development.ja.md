# 開発者向け：構成、作り方、クエリの決まり

[English](development.md)

リポジトリの構成、zip の作り方と試験、すべてのクエリが従う決まりをまとめます。
エージェントの導入と使い方は [setup.ja.md](setup.ja.md) を見てください。

## 構成

| 場所 | 中身 |
|---|---|
| `queries/` | サイジング用の SQL（01〜08）。ほかのツールはすべてここを正本にする |
| `queries/optional/` | クエリの文面の例を含む SQL。既定では使わない |
| `queries/advisor/` | アドバイザー用の SQL（10〜13） |
| `queries/progress/` | 日次のまとめ用の SQL（20〜28。22 以降は変化を拾い、26〜28 はエラー、バックグラウンドの処理、非同期 INSERT の書き出しを見る） |
| `queries/loadtest/` | 負荷試験の時間帯を見る SQL（30〜31）と、2回の試験を比べる SQL（32） |
| `queries/fitgap/` | サービスを設計と照らし合わせる SQL（40：ビュー、マテリアライズドビュー、辞書と、それぞれの読み元と書き先） |
| `reference/poc-criteria.md` | PoC の評価の観点と測り方。出典は公開資料（ClickHouse のドキュメントと clickhouse.com/blog の事例）だけ |
| `reference/architecture-platform.md` | 設計の段で決める基盤の層（提供の形、プロバイダとリージョン、接続経路、連携、セキュリティ、計算資源の分け方、バックアップ）。決めるための問い、条件による分かれ方、公式のページと、クラウドプロバイダのドキュメントのツールを使うときの決まり |
| `reference/checks-*.md` | 動いているサービスを見る観点。分野ごとに 1 ファイル（CPU と同時実行、読み取りとクエリ、INSERT とパーツ、エラーとバックグラウンドの処理、オートスケールと試験の組み方、Cloud のサービス）。観点ごとに、読む列、判断の基準、公開の出典を書く。同梱の設計のルール（`clickhouse-best-practices`）はテーブルと INSERT の作り方を扱い、こちらはワークロードが動き出してから見るものを扱う |
| `clickhouse-agents/skills/` | スキル（スキルごとの `SKILL.md`） |
| `export/` | ユーザーが自分で統計を書き出すための一式（`export.sh`（bash と curl）か SQL コンソールで実行） |
| `scripts/build.sh` | スキルの zip と書き出しの一式を `dist/` に作る |
| `scripts/fetch-public-skills.sh` | 公開スキルを、コミットを固定して変更せずに取得し、ライセンスと一緒に zip にする |
| `scripts/bundle.sh` | スキルの zip をまとめて `dist/poc-assistant-skills.zip` にする |
| `scripts/test-queries.sh` | 使い捨てのローカルの ClickHouse サーバーで、最小権限の DB ユーザーとして全クエリを実行する |
| `.github/workflows/build.yml` | CI とリリース（下記） |
| `docs/` | 導入の手順と通しの手順（画面は `docs/images/`） |
| `LICENSE` | Apache-2.0。どの zip にも写しを入れる。公開スキルの zip には ClickHouse/agent-skills のライセンスを入れる |

## 作り方

GitHub Actions が、push とプルリクエストのたびに次を実行します。SQL の構文の確認、使い捨てのサーバーでの全クエリの実行（`scripts/test-queries.sh`）、ShellCheck、zip の作成です。`v*` のタグを push すると、zip がリリースに載ります。手元で作る場合は次のとおりです。

```bash
scripts/build.sh                # dist/ch-sizing-export.zip と dist/<スキル名>-skill.zip
scripts/fetch-public-skills.sh  # dist/clickhouse-architecture-advisor-skill.zip
scripts/bundle.sh               # dist/poc-assistant-skills.zip
scripts/test-queries.sh         # PATH に clickhouse のバイナリが必要
```

スキルの zip には、`SKILL.md`、ライセンス、そこに名前が書かれたファイル（`queries/...sql`、`reference/...md`）だけが入ります。同梱した参照ファイルが名前を挙げた参照ファイルも入ります。
エージェントはフォルダーの中身を一覧できないので、スキルが使うファイルはすべて `SKILL.md` に書きます。
書かれたファイルが無いと、ビルドは失敗します。

## クエリの決まり

- 読むのは system テーブルだけです（スキルがユーザーの了承を得てユーザーのテーブルに流すクエリは、ここには置かず会話の中で書きます。そのクエリには `log_comment = 'poc-assistant'` を付け、ここにある `query_log` のクエリはすべてそれを除きます）。
- ClickHouse Cloud ではログがレプリカごとにあるので、`clusterAllReplicas('default', merge('system', '^<table>'))` で読みます。
- `query_log` からは、この接続自身による system テーブルの読み取り（`currentUser()` のクエリのうち、`tables` が空でなく、`system.*`、`information_schema.*`、`clusterAllReplicas`、`merge` だけのもの。開始前に失敗したクエリは `tables` が空なので残す）と、ClickHouse Cloud の監視用の DB ユーザー（名前が `-internal` で終わるもの）を除きます。除かないと、検証では SELECT の件数の大半が監視のクエリでした。接続している DB ユーザーのほかのクエリは残すので、負荷を同じ DB ユーザーで流しても数えられます。エージェントが `log_comment = 'poc-assistant'` を付けてユーザーのテーブルに流したクエリは除き、それ以外にその接続でユーザーのテーブルに流したクエリは数えられます。
- 必要なパーティションだけを読むよう、`event_time` に加えて `event_date` でも絞ります。
- ユーザー名は出さず、数だけを出します。`normalized_query_hash` は桁が落ちないよう `toString` で文字列にします。
- 期間は `30 /*days*/`、負荷試験の時間帯は `now() - INTERVAL 1 HOUR /*window_start*/` と `now() /*window_end*/` と書きます。ツールがこれらの印を置き換えます。
- compact parts だけで保存されている小さなテーブルは、マージされるまで圧縮後の容量が 0 と出ます。
- アドバイザー、負荷試験の振り返り、日次のまとめ、照合のスキルは、見つけたことを確かめるために、system テーブルを読むクエリを同じ絞り込みで自分で書いて実行できます。書いたクエリは、自分で書いたものとして出力に示します。サイジングのスキルは、数字を再現できるよう、渡したクエリだけを実行します。
