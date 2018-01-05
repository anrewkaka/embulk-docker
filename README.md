# OracleからDWHへ送る連携ファイル抽出

Embulkを利用して、データベースからDWH送る連携ファイルを抽出する

## デプロイ

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
