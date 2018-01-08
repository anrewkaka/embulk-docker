# OracleからDWHへ送る連携ファイル抽出

Embulkを利用して、データベースからDWHへ送る連携ファイルを抽出する

## 概要

更新日時が「対象日の前日0時以降から対象日の0時前まで」の指定テーブルのレコードを抽出する。

※ 対象日は引数で指定される。指定されていない場合に対象日が実行日である。

出力ファイルの仕様
- ファイルの文字コード：UTF-8
- 改行コード：LF
- 区切文字："|"（半角パイプ） 、囲み文字なし（※データ内に半角パイプ、改行コード「CR」「LF」が存在した場合は削除）
- 圧縮前のファイル名：[ファイル名]_YYYYMMDDHHMMSS.csv（YYYYMMDDHHMMSSは処理開始日時(csv、zip、ctlでは同じ)）
- 圧縮後のファイル名：[ファイル名]_YYYYMMDDHHMMSS.csv.zip
- コントロールファイル（空ファイル）：[ファイル名]_YYYYMMDDHHMMSS.ctl

## デプロイ

### Dockerイメージのビルド

```bash
docker build -t [docker_image_name:tag] .
```

### 環境変数の変更

`ora_dwh.env`で定義されている以下の環境変数の値を変更する。

|変数名|説明|
|:-----|:-----|
|LOCAL_BASEDIR|シェル実行用の入出力ファイルを含む箇所|
|OUTPUT_DIR|DWHへ送る連携ファイルを含む箇所|
|DOCKER_IMAGE|Dockerイメージの名前|

### 設定ファイルの配置

#### Embulk設定用のテンプレートファイル

Embulk設定用のテンプレートファイルを、`ora_dwh.env`ファイルの`LOCAL_BASEDIR`で定義されたディレクトリにコピーする。

例）

```bash
cp ./config/_config.yml.liquid /nas/etl01/batch/ETC/ETC_BAT_EMBULK/yml/input/config
```

#### Embulk設定ファイル

lowercase型のあるテーブル名をファイル名としてEmbulk設定ファイルを作成して、`yml/input`フォルダに配置する。

例）
```bash
/nas/etl01/batch/ETC/ETC_BAT_EMBULK/yml/input/m_apcrd_mem_tmp_mch.yml.liquid
```

参考: [m_apcrd_mem_tmp_mch.yml.liquid](config/m_apcrd_mem_tmp_mch.yml.liquid)

#### Embulk実行用のdocker-compose

`ora_dwh.env`ファイルの`LOCAL_BASEDIR`で定義されたディレクトリに、docker-composeのテンプレートファイルをコピーする。

例）

```bash
cp ./docker/docker-compose.yml /nas/etl01/batch/ETC/ETC_BAT_EMBULK/yml/
```

### シェル実行

#### 引数

|引数|必須|説明|
|:-----|:-----|:-----|
|第1引数|○|抽出対象のテーブル名|
|第2引数|○|出力ファイル名|
|第3引数||抽出対象日(フォーマット: YYYY-MM-DD) ※ 設定されない場合に実行日を抽出対象日とする|

#### シェル実行

- 対象日を設定してシェルを実行する。

```bash
sh ETC_BAT_ORA_DWH_EXPORT.sh TEST_TABLE TEST_FILE_NAME 2018-01-01
```

- 対象日を設定せずにシェルを実行する。

```bash
sh ETC_BAT_ORA_DWH_EXPORT.sh TEST_TABLE TEST_FILE_NAME
```
