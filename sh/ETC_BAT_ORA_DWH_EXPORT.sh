#!/bin/bash
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
# Oracleからデータを取得し、DWHへ送る連携ファイルを抽出する。
#
# 【引数】
#  第1引数【必須】 TABLE_NAME: テーブル名
#  第2引数【必須】 FILE_NAME: ファイル名
#  第3引数【任意】 TARGET_DATE: 対象日(フォーマット：YYYY-MM-DD)
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

#  第1引数 TABLE_NAME
TABLE_NAME=$1

#  第2引数 FILE_NAME
FILE_NAME=$2

# 第3引数 TARGET_DATE
TARGET_DATE=$3
if [ "x$TARGET_DATE" = "x" ]; then
    # 未指定の場合：実行日を対象日とする
    TARGET_DATE=`date +%Y-%m-%d`
fi

#
# 引数チェック
#
# TABLE_NAMEの必須チェック
if [ "x$TABLE_NAME" = "x" ]; then
    # ログ出力
    echo "`date '+%T'` テーブル名を入力してください。" | tee -a ${ORA_DWH_EXPORT_LOG}
    # 異常終了
    exit 1
fi

# FILE_NAMEの必須チェック
if [ "x$FILE_NAME" = "x" ]; then
    # ログ出力
    echo "`date '+%T'` ファイル名を入力してください。" | tee -a ${ORA_DWH_EXPORT_LOG}
    # 異常終了
    exit 1
fi

# TARGET_DATEの形式チェック
if [ $(expr "$TARGET_DATE" : '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$') -eq 0 ]; then
    # ログ出力
    echo "`date '+%T'` 不正な引数：${TARGET_DATE}（正しくは「YYYY-MM-DD」フォーマットの日付です。）" | tee -a ${ORA_DWH_EXPORT_LOG}
    # 異常終了
    exit 1
fi

date --date="${TARGET_DATE}"
RETURN_CD=${?}
if [ ${RETURN_CD} != 0 ]; then
    # ログ出力
    echo "`date '+%T'` 対象日を正しく値で入力してください。" | tee -a ${ORA_DWH_EXPORT_LOG}
    # 異常終了
    exit 1
fi

# EXPORT_TARGET_DATEの設定
EXPORT_TARGET_DATE=`date --date="${TARGET_DATE} -1 day" +%Y-%m-%d`

# Embulk設定ファイル用共通項目設定ファイル(_config.yml.liquid)をコピー
cp ${LOCAL_BASEDIR}/yml/input/config/_config.yml.liquid ${LOCAL_BASEDIR}/yml/input/
RETURN_CD=${?}
if [ ${RETURN_CD} != 0 ]; then
    # ログ出力
    echo "`date '+%T'` Embulk設定ファイル用共通項目設定ファイルをコピーできませんでした。" | tee -a ${ORA_DWH_EXPORT_LOG}
    # 異常終了
    exit 1
fi

# 抽出データ取得期間の条件を設定
sed -i -e "s|<TARGET_DATE>|${EXPORT_TARGET_DATE}|g" ${LOCAL_BASEDIR}/yml/input/_config.yml.liquid
sed -i -e "s|<CURRENT_TIMESTAMP>|${CURRENT_TIMESTAMP}|g" ${LOCAL_BASEDIR}/yml/input/_config.yml.liquid
sed -i -e "s|<FILE_NAME>|${FILE_NAME}|g" ${LOCAL_BASEDIR}/yml/input/_config.yml.liquid

# Docker用ファイル(docker-compose.yml)をコピー
cp ${LOCAL_BASEDIR}/yml/docker-compose.yml ./
RETURN_CD=${?}
if [ ${RETURN_CD} != 0 ]; then
    # ログ出力
    echo "`date '+%T'` Docker用ファイルをコピーできませんでした。" | tee -a ${ORA_DWH_EXPORT_LOG}
    # 異常終了
    exit 1
fi

LOWER_CASE_TABLE_NAME=`echo ${TABLE_NAME} | tr [:upper:] [:lower:]`

# Docker用ファイルの共通項目を設定
sed -i -e "s|<DOCKER_IMAGE>|${DOCKER_IMAGE}|g" ./docker-compose.yml
sed -i -e "s|<LOWERCASE_TABLE_NAME>|${LOWER_CASE_TABLE_NAME}|g" ./docker-compose.yml
sed -i -e "s|<FILE_SUBFIX>|${CURRENT_TIMESTAMP}|g" ./docker-compose.yml
sed -i -e "s|<LOCAL_BASEDIR>|${LOCAL_BASEDIR}|g" ./docker-compose.yml

# Embulkを実行し、Oracleからデータを抽出
docker-compose up
RETURN_CD=${?}
if [ ${RETURN_CD} != 0 ]; then
    # ログ出力
    echo "`date '+%T'` Docker実行に失敗しました。" | tee -a ${ORA_DWH_EXPORT_LOG}
    # 異常終了
    exit 1
fi

OUTPUT_FILE_NAME=${FILE_NAME}_${CURRENT_TIMESTAMP}

# 出力したファイルを移動
mv -f ${LOCAL_BASEDIR}/work/${OUTPUT_FILE_NAME}.csv.zip ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}.csv.zip
RETURN_CD=${?}
if [ ${RETURN_CD} != 0 ]; then
    # ログ出力
    echo "`date '+%T'` ファイル移動に失敗しました。" | tee -a ${ORA_DWH_EXPORT_LOG}
    # 異常終了
    exit 1
fi

# コントロールファイルを作成
touch ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}.ctl
RETURN_CD=${?}
if [ ${RETURN_CD} != 0 ]; then
    # ログ出力
    echo "`date '+%T'` コントロールファイル作成に失敗しました。" | tee -a ${ORA_DWH_EXPORT_LOG}
    # 異常終了
    exit 1
fi

# 正常終了
exit 0
