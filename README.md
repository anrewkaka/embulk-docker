# OracleからDWHへ送る連携ファイル抽出

Embulkを利用して、データベースからDWH送る連携ファイルを抽出する

## 概要

Trích xuất các record của table được chỉ định mà có 更新日時 là từ sau 0時 của ngày trước ngày đối tượng đến trước 0時 của ngày đối tượng.

※ Ngày đối tượng thì sẽ được chỉ định bằng tham số, trường hợp chưa được chỉ định thì ngày đối tượng sẽ là ngày thực thi

出力するファイルの仕様
- ファイルの文字コード：UTF-8
- 改行コード：LF
- 区切文字："|"（半角パイプ） 、囲み文字なし（※データ内に半角パイプ、改行コード「CR」「LF」が存在した場合は削除）
- 圧縮前のファイル名：[ファイル名]_YYYYMMDDHHMMSS.csv（YYYYMMDDHHMMSSは処理開始日時。csv,zip,ctlで同じ）
- 圧縮後のファイル名：[ファイル名]_YYYYMMDDHHMMSS.csv.zip
- コントロールファイル（空ファイル）：[ファイル名]_YYYYMMDDHHMMSS.ctl

## デプロイ

### Build Docker Image

```bash
docker build -t [docker_image_name:tag] .
```

### Thay đổi biến môi trường

Thực hiện thay đổi giá trị của các biến môi trường bên dưới tại mà đang được định nghĩa tại `ora_dwh.env`

|変数名|説明|
|:-----|:-----|
|LOCAL_BASEDIR|Nơi chứa các file input/output dùng cho việc thực thi shell|
|OUTPUT_DIR|Nơi chứa file DWHへ送る連携ファイル|
|DOCKER_IMAGE|Tên của DockerImage|

### Bố trí file setting

#### file template của Embulk設定

Copy file template của Embulk設定 vào directory mà đã định nghĩa tại `LOCAL_BASEDIR` của file `ora_dwh.env`

例）

```bash
cp ./config/_config.yml.liquid /nas/etl01/batch/ETC/ETC_BAT_EMBULK/yml/input/config
```

#### file Embulk設定

Tạo file Embulk設定 có tên file là tên table dưới dạng lowercase và bố trí tại folder `yml/input`

例）
```bash
/nas/etl01/batch/ETC/ETC_BAT_EMBULK/yml/input/m_apcrd_mem_tmp_mch.yml.liquid
```

参考: [m_apcrd_mem_tmp_mch.yml.liquid](config/m_apcrd_mem_tmp_mch.yml.liquid)

#### Embulk実行用のdocker-compose

Copy file template của docker-compose vào directory mà đã định nghĩa tại `LOCAL_BASEDIR` của file `ora_dwh.env`

例）

```bash
cp ./docker/docker-compose.yml /nas/etl01/batch/ETC/ETC_BAT_EMBULK/yml/
```

### シェル実行

#### 引数

|引数|必須|説明|
|:-----|:-----|:-----|
|第1引数|○|Tên table của đối tượng trích xuất|
|第2引数|○|Tên file mà sẽ output|
|第3引数||Ngày đối tượng trích xuất(format: YYYY-MM-DD) ※ Trường hợp ko setting thì sẽ cho ngày 実行 là ngày đối tượng trích xuất|

#### シェル実行

- 対象日が設定されるでシェルを実行

```bash
sh ETC_BAT_ORA_DWH_EXPORT.sh TEST_TABLE TEST_FILE_NAME 2018-01-01
```

- 対象日が設定されないでシェルを実行

```bash
sh ETC_BAT_ORA_DWH_EXPORT.sh TEST_TABLE TEST_FILE_NAME
```
