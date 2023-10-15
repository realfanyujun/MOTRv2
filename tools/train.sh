#!/usr/bin/env bash
# ------------------------------------------------------------------------
# Copyright (c) 2022 megvii-research. All Rights Reserved.
# ------------------------------------------------------------------------

#所有命令执行前打印到std err,debug模式
set -x

PY_ARGS=${@:2}
#管道命令仅当全部子命令正确退出，$？返回0
set -o pipefail
#exps/motrv2
OUTPUT_BASE=$(echo $1 | sed -e "s/configs/exps/g" | sed -e "s/.args$//g")
mkdir -p $OUTPUT_BASE
#从1到100,创建100个run文件夹
for RUN in $(seq 1); do
  ls $OUTPUT_BASE | grep run$RUN && continue
  OUTPUT_DIR=$OUTPUT_BASE/run$RUN
  #exps/motrv2/run1
  mkdir $OUTPUT_DIR && break
done

# clean up *.pyc files
rmpyc() {
  rm -rf $(find -name __pycache__)
  rm -rf $(find -name "*.pyc")
}

# run backup，把一些文件夹保存到exps/motrv2/run1
echo "Backing up to log dir: $OUTPUT_DIR"
rmpyc && cp -r models datasets util main.py engine.py submit_dance.py $1 $OUTPUT_DIR
echo " ...Done"

# tar src to avoid future editing
cleanup() {
  echo "Packing source code"
  rmpyc
  # tar -zcf models datasets util main.py engine.py eval.py submit.py --remove-files
  echo " ...Done"
}

args=$(cat $1)

pushd $OUTPUT_DIR
trap cleanup EXIT

# log git status
echo "Logging git status"
git status > git_status
git rev-parse HEAD > git_tag
git diff > git_diff
echo $PY_ARGS > desc
echo " ...Done"

python main.py ${args} --output_dir . |& tee -a output.log
