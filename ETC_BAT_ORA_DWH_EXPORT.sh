#!/bin/sh
################################################################################
#
# システム名       :ハイブリッド書店システム
# サブシステム名   :マーケ
# 機能名           :OracleからDWHへ送る連携ファイル抽出
# ファイル名       :ETC_BAT_ORA_DWH_EXPORT.sh
# 作成者           :Lan-NT
#-------------------------------------------------------------------------
#
# c 2017 Dai Nippon Printing Co., Ltd. All rights reserved.
#
################################################################################
#
# 【概要】
# Oracleからデータを取得し、Google Cloud Strageへデータ連携する。
#
# 【引数】
#  第1引数 TARGET_DATE: 対象日(フォーマット：YYYYDDMM)
# 【返却値】
#    0 : 正常終了
#    1 : 異常終了
#
################################################################################

#
# 環境設定ファイル
#
. $(cd $(dirname $0); pwd)/ora_dwh.env

#
# 現在日時
#
CURRENT_TIMESTAMP=`date +%Y%m%d%H%M%S`
#
# ログ出力先ファイルパス
#
ORA_DWH_EXPORT_LOG=${LOCAL_BASEDIR}/log/ETC_BAT_ORA_DWH_EXPORT_${CURRENT_TIMESTAMP}.log
touch ${ORA_DWH_EXPORT_LOG}

#
# 引数設定
#
TARGET_DATE=$1
if [ "x$TARGET_DATE" = "x" ]; then
    # 未指定の場合：実行日を対象日とする
    TARGET_DATE=`date +%Y%m%d`
fi

#
# 引数チェック
#
if [ $(expr "$TARGET_DATE" : '^[0-9]\{8\}$') -eq 0 ]; then
    # ログ出力
    echo "`date '+%T'` 不正な引数：${TARGET_DATE}（正しくは「YYYYMMDD」フォーマットの日付です。）" | tee -a ${ORA_DWH_EXPORT_LOG}
    # 異常終了
    exit 1
fi

#
# リストファイルチェック（関数）
# リストファイルに有効行が存在するかどうかチェックを行う
#
function check_table_list_file() {
    ##
    ## ${LOCAL_BASEDIR}/work/tablelist_*.csv をブロック末尾でリダイレクトで読込
    ##
    while read line; do
        # リストの空行を飛ばす
        result=`echo ${line} | tr -d "\r" | tr -d "\n"`

        # コメント行や空行を読み飛ばす
        if [ `echo ${result} | egrep "^#" | wc -l` -gt 0 ] || [ "${result}" = "" ]; then
            continue
        else
            echo "`date '+%T'` 有効な設定を確認しました。" >> ${ORA_DWH_EXPORT_LOG}
            echo 1
            return
        fi
        echo 0
        return
    done <  ${LOCAL_BASEDIR}/work/tablelist_${TARGET_DATE}.csv
}

# リスト区切り文字
IFS=','

# リストファイルチェック（関数呼び出し）
LIST_CHECK=`check_table_list_file`

# 空ファイルだった場合はログにメッセージを出力
if [ ${LIST_CHECK} -eq 0 ]; then
    echo "`date '+%T'` データ連携対象テーブルリストにデータ処理内容が記述されていません。" >> ${ORA_DWH_EXPORT_LOG}
    exit -1
fi

## ${LOCAL_BASEDIR}/work/rawdatalist_${LIST_NAME_SUFFIX}.csv をブロック末尾でリダイレクトで読込
while read line; do
    # リストの空行を飛ばす
    result=`echo ${line} | tr -d "\r" | tr -d "\n"`

    # コメント行や空行を読み飛ばす
    if [ `echo ${result} | egrep "^#" | wc -l` -gt 0 ] || [ "${result}" = "" ]; then
        continue
    fi

    CSV_DATA_ROW=($line)

    # 処理対象のテーブル名を設定
    TABLE_NAME=${CSV_DATA_ROW[0]}

    # ファイル名を設定
    FILE_NAME=${CSV_DATA_ROW[1]}

    # Embulk設定ファイル用共通項目設定ファイル(_config.yml.liquid)をコピー
    cp ${LOCAL_BASEDIR}/yml/input/config/_config.yml.liquid ${LOCAL_BASEDIR}/yml/input/
    RETURN_CD=${?}
    if [ ${RETURN_CD} != 0 ]; then
        echo "`date '+%T'` Embulk設定ファイル用共通項目設定ファイルをコピーできませんでした。" >> ${GCS_SEND_LOG}
        exit -1
    fi

done < ${LOCAL_BASEDIR}/work/tablelist_${TARGET_DATE}.csv
