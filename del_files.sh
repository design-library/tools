#!/bin/bash

##################################################################
# 前処理
##################################################################
set -e -o pipefail

# 入力確認
read -p "引数の確認をしてください。処理を進めてよろしいですか？  (y/n) :" YN
if [ ! "${YN}" = "y" ]; then
  echo "Usage: sh del_logfile.sh logs_dirname limit_date"
  echo "(ex. sh del_logfile.sh /hoge/logs 2022/12/26) (1)"
  exit 1;
fi

# 引数チェック
if [ $# -ne 2 ]; then
  echo "The parameter of command del_logfile.sh is invalid."
  echo "Usage: sh del_logfile.sh logs_dirname limit_date"
  echo "(ex. sh del_logfile.sh /hoge/logs 2022/12/26) (2)"
  exit 1
fi

# ディレクトリチェック
if [ ! -d $1 ]; then
  echo $1" dose not exist."
  echo "Usage: sh del_logfile.sh logs_dirname limit_date"
  echo "(ex. sh del_logfile.sh /hoge/logs 2022/12/26) (3)"
  exit 1
fi

# 日付妥当チェック
if [[ ! $2 = $(date --date="$2" '+%Y/%m/%d') ]]; then
  echo "Usage: sh del_logfile.sh logs_dirname limit_date"
  echo "(ex. sh del_logfile.sh /hoge/logs 2022/12/26) (4)"
  exit 1
fi


##################################################################
# 後処理関数
# Arguments:
#   None
# Returns:
#   None
##################################################################
function finally() {
  echo "`date +'%Y-%m-%d %H:%M:%S:%3N'` finished."
  return 0;
}


##################################################################
# エラー処理関数
# Arguments:
#   行番号, 関数（コマンド）名
# Returns:
#   None
##################################################################
err_buf=""
function err() {
  # Usage: trap 'err ${LINENO[0]} ${FUNCNAME[1]}' ERR
  status=$?
  lineno=$1
  func_name=${2:-main}
  err_str="ERROR"
  err_str="ERROR: [`date +'%Y-%m-%d %H:%M:%S:%3N'`] ${SCRIPT}:${func_name}() returned non-zero exit status ${status} at line ${lineno}"
  echo ${err_str} 
  err_buf+=${err_str}
  return 0;
}


##################################################################
# 主処理
# ls -ltr --time-style="+%Y-%m-%d %H:%M:%S" コマンドを実行し、
# 以下の形式で出力されることを想定している。
# -rw-r--r-- 1 root root 566231040 2022/12/20 11:56:00 api-log-20221220.log
# ^^^^^^^^^^ ^ ^^^^ ^^^^ ^^^^^^^^ ^^^^^^^^^^^ ^^^^^^^^ ^^^^^^^^^^^
# $1        $2 $3   $4   $5       $6          $7       $8
##################################################################
trap 'err ${LINENO[0]} ${FUNCNAME[1]}' ERR
trap finally EXIT


echo "`date +'%Y-%m-%d %H:%M:%S:%3N'` started."

ls -ltr --time-style="+%Y/%m/%d %H:%M:%S" $1 | awk -v log_dir=$1 -v lmt_date=$2 '
BEGIN {
  print "target log_dir=" log_dir;
  print "limit date is " lmt_date;
  dsize=0;
}
NR != 1 { 
  if (lmt_date < $6) {
    exit 0;
  } else {
    if ( (total += $5) < 2000000000 ) {
      "rm "log_dir"/"$8"; echo $? | cut -c 1" | getline status;
      if ( status == 0 ) {
        print "Line=" NR-1 ":OK:delete_file=" log_dir "/" $8 ":size="$5;
      } else {
        exit 1;
      }
      dsize = total;
    }
  }
} 
END { 
  print "delete size=" dsize; 
}'
