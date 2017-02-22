#MULAN-LRE
This version of MULAN repository for extracting attribute features from raw audio files from LRE15 dataset.
These articulatory attribute features (manner and place) are high-level speech descriptive features. More information you can find in articles [TODO refs]

###How to run?
1. fix path variable `KALDI_ROOT` in `path.sh` pointing to your installed Kaldi toolkit
2. be sure that all your bash files are runnable, fixing: run from the project folder `chmod -R +x ./`
3. fix paths `dataset_dir`, `scan_sub_dir` and  `out_dir` in the scripts `run_cnn.sh` and `run_dbn.sh`

- `dataset_dir`: path to the LRE-15 dataset
- `scan_sub_dir`: subforlders to search wave files with the `pcm` extention
- `out_dir`: output path, where audio lists, fbank features and result attribute scores will be saved there

After that, you can run 
```sh
$ ./run_dbn.sh 0 # 0 is the processing stage, from 0-2
```
or
```sh
$ ./run_cnn.sh 0 # 0 is the processing stage, from 0-3
```

Manner attribute scores will be saved in `$out_dir/res/manner/scores.txt` and place attributes in `$out_dir/res/place/scores.txt` in the next format:

utterance_id [ `columns with attributes scores per each frame`]

Columns in `scores.txt` correspond to the next type of attributes (you can find in `data/dict/`):

manner: [ fricative glides nasal other silence stop voiced vowel ]

place: [ coronal dental glottal high labial low mid other palatal silence velar ]

