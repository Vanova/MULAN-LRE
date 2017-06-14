#!/bin/bash 
# set -x;
# trap read debug;

# ===
# Extract manner, place and these fusion features 
# from evaluation part of LRE'15 dataset
# ===

### run: ./run_cnn.sh 1 # with number of stage

stage=$1

. ./path.sh

nj=20 # number of parallel jobs

# root folder with audio files to scan
dataset_dir=/data3/pums/LRE2015/lre15-N-01/data/
# subfolders to scan
scan_sub_dir="" # scan dataset_dir itself

# output folder for audio lists, fbanks, attribute scores ...
out_dir=/home1/ivan/projects_data/mulan_extractor

# 0. prepare data
# scan Spanish cluster subfolders of LID dataset
if [ $stage -eq 0 ]; then
  for sub in $scan_sub_dir; do        
    steps/data_prep.sh $dataset_dir/$sub "pcm" $out_dir/$sub
  done
fi

# 1. extract log mel-filter bank features, binary encoding
if [ $stage -eq 1 ]; then
  for sub in $scan_sub_dir; do
    lists_dir=$out_dir/$sub/lists
    fbank_dir=$out_dir/$sub/cnn-fbank
    steps/make_fbank_pitch.sh $nj $lists_dir $fbank_dir
    steps/compute_cmvn_stats.sh $fbank_dir $fbank_dir  
  done  
fi

# 2. forward data through the Neural Network and producing scores
if [ $stage -eq 2 ]; then
  # NOTE: you can fix number of threads for calculate jobs at a time
  echo "LRE dataset"
  echo "*** Manner extraction ***"
  for sub in $scan_sub_dir; do
    fbank_dir=$out_dir/$sub/cnn-fbank
    trans=model/manner/fbank_to_splice_cnn4c_128_3_uvz_mfom.trans
    nnet=model/manner/cnn4c_128_3_uvz_mfom.nnet
    manner_out=$out_dir/$sub/res/manner
    steps/forward_cnn_parallel.sh $nj $fbank_dir $trans $nnet $manner_out
  done

  echo "*** Place extraction ***"
  for sub in $scan_sub_dir; do
    fbank_dir=$out_dir/$sub/cnn-fbank
    trans=model/place/fbank_to_splice_cnn4c_128_7_uvz_mfom.trans
    nnet=model/place/cnn4c_128_7_uvz_mfom.nnet
    place_out=$out_dir/$sub/res/place
    steps/forward_cnn_parallel.sh $nj $fbank_dir $trans $nnet $place_out
  done
  
  echo "*** Fusion extraction ***"
  for sub in $scan_sub_dir; do
    fbank_dir=$out_dir/$sub/cnn-fbank
    trans=model/fusion/fbank_to_splice_cnn4c_128_5_uvz_mfom.trans
    nnet=model/fusion/cnn4c_128_5_uvz_mfom.nnet
    fusion_out=$out_dir/$sub/res/fusion
    steps/forward_cnn_parallel.sh $nj $fbank_dir $trans $nnet $fusion_out
  done
fi

# 3. split fusion on fusion_manner and fusion_place parts
if [ $stage -eq 3 ]; then
  echo "*** Select MANNER part from FUSION scores ***"
  feat_select="2,4,9,10,12,13,15,16" # with 'other' and 'sil'
  for sub in $scan_sub_dir; do
    fusion_in=$out_dir/$sub/res/fusion
    fusion_out=$out_dir/$sub/res/fusion_manner
    log=$fusion_out/log
    steps/select_features.sh $nj $feat_select $fusion_in $fusion_out $log
  done
  
  echo "*** Select PLACE part from FUSION scores ***"
  feat_select="0,1,3,5,6,7,8,10,11,12,14" # with 'other' and 'sil'
  for sub in $scan_sub_dir; do
    fusion_in=$out_dir/$sub/res/fusion
    fusion_out=$out_dir/$sub/res/fusion_place
    log=$fusion_out/log
    steps/select_features.sh $nj $feat_select $fusion_in $fusion_out $log
  done
fi
