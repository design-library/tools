#!/bin/bash

##################################################################
# 前処理
##################################################################
set -e -o pipefail

# 引数チェック
if [ $# -ne 1 ]; then
  echo "The parameter of command del_logfile.sh is invalid."
  echo "Usage: sh del_logfile.sh logs_dirname(ex./hoge/logs)"
  exit 1
fi

# ディレクトリチェック
if [ ! -d $1 ]; then
  echo $1" dose not exist."
  echo "Usage: sh del_logfile.sh logs_dirname(ex.api_logs)"
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
# ls -ltr コマンドを実行し、以下の形式で出力されることを想定している。
# -rw-r--r-- 1 root root 52428800 Dec 21 00:06 api-log-20221221.log
# ^^^^^^^^^^ ^ ^^^^ ^^^^ ^^^^^^^^ ^^^ ^^ ^^^^^ ^^^^^^^^^^^^^^^^^^^^
# $1        $2 $3   $4   $5       $6  $7 $8    $9
##################################################################
trap 'err ${LINENO[0]} ${FUNCNAME[1]}' ERR
trap finally EXIT


echo "`date +'%Y-%m-%d %H:%M:%S:%3N'` started."

ls -ltr $1 | awk -v log_dir=$1 '
BEGIN {
  print "target log_dir=" log_dir;
  dsize=0;
}
NR != 1 { 
  if ( (total += $5) < 1000000000 ) {
    "rm "log_dir"/"$9"; echo $? | cut -c 1" | getline status;
    if ( status == 0 ) {
      print "Line=" NR-1 ":OK:delete_file=" log_dir "/" $9 ":size="$5;
    } else {
      #exit 1;
      print "Line=" NR-1 ":NG:target_file=" log_dir "/" $9 ":size="$5;
      total -= $5;
    }
    dsize = total;
  }
} 
END { 
  print "delete size=" dsize; 
}'
