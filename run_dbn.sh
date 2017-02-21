#!/bin/bash 
# set -x;
# trap read debug;

stage=$1

. ./path.sh

nj=20 # number of parallel jobs
###
# LID dataset feature extraction
###
# root folder with audio files to scan
dataset_dir=/data3/pums/LRE2015/LDC2015E87E88_LRE15_Training_Data
# subfolders to scan
scan_sub_dir="spa-car spa-eur spa-lac por-brz"

# output folder for audio lists, fbanks, attribute scores ...
out_dir=/home1/ivan/projects_data/mulan_extractor
out_sub_dir=$scan_sub_dir

# 0. prepare data
# scan Spanish cluster subfolders of LID dataset
if [ $stage -eq 0 ]; then
  for sub in $scan_sub_dir; do    
    # steps/data_prep_by_list.sh ${scan_sub_dir[i]} $dataset_dir $out_dir/${out_sub_dir[i]}
    steps/data_prep.sh $dataset_dir/$sub "pcm" $out_dir/$sub
  done
fi

# 1. extract log mel-filter bank features for DBN
if [ $stage -eq 1 ]; then
  for sub in $scan_sub_dir; do
    # DONT DO CMVN!
    lists_dir=$out_dir/$sub/lists
    fbank_dir=$out_dir/$sub/dbn-fbank
    steps/make_fbank.sh $nj $lists_dir $fbank_dir
  done  
fi

# NOTE: compile last KALDI src with MFoM UvZ loss
# 2. forward data through the Neural Network and producing scores
if [ $stage -eq 2 ]; then
  # NOTE: you can fix number of threads for calculate jobs at a time
  echo "LID dataset"
  # echo "*** Manner extraction ***"
  # for sub in $scan_sub_dir; do
  #   fbank_dir=$out_dir/$sub/dbn-fbank
  #   trans=model/manner/fbank_to_splice_dbn.trans
  #   nnet=model/manner/rbm_dbn_2_1024.nnet
  #   manner_out=$out_dir/$sub/res/dbn/manner
  #   steps/forward_dbn_parallel.sh $nj $fbank_dir $trans $nnet $manner_out
  # done

  echo "*** Place extraction ***"
  for sub in $scan_sub_dir; do
    fbank_dir=$out_dir/$sub/dbn-fbank
    trans=model/place/fbank_to_splice_dbn.trans
    nnet=model/place/rbm_dbn_5_1024.nnet
    place_out=$out_dir/$sub/res/dbn/place
    steps/forward_dbn_parallel.sh $nj $fbank_dir $trans $nnet $place_out
  done
fi
