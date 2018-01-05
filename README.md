# OracleからDWHへ送る連携ファイル抽出

Embulkを利用して、データベースからDWH送る連携ファイルを抽出する

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
cp ./config/_config.yml /nas/etl01/batch/ETC/ETC_BAT_EMBULK/yml/input/config
```

#### Embulk実行用のdocker-compose

Copy file template của docker-compose vào directory mà đã định nghĩa tại `LOCAL_BASEDIR` của file `ora_dwh.env`

例）

```bash
cp ./docker/docker-compose.yml /nas/etl01/batch/ETC/ETC_BAT_EMBULK/yml/
```

### シェルの実行

#### 引数

|引数|必須|説明|
|:-----|:-----|:-----|
|第1引数|○|Tên table của đối tượng trích xuất|
|第2引数|○|Tên file mà sẽ output|
|第3引数||Ngày đối tượng trích xuất(format: YYYY-MM-DD) ※ Trường hợp ko setting thì sẽ cho ngày 実行 là ngày đối tượng trích xuất|

#### 実行

- 対象日が設定されるでシェルを実行

```bash
sh ETC_BAT_ORA_DWH_EXPORT.sh TEST_TABLE TEST_FILE_NAME 2018-01-01
```

- 対象日が設定されないでシェルを実行

```bash
sh ETC_BAT_ORA_DWH_EXPORT.sh TEST_TABLE TEST_FILE_NAME
```
