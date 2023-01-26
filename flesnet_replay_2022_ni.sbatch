#!/bin/bash

#SBATCH -J CbmReplay
#SBATCH --singularity-container=/cvmfs/cbm.gsi.de/debian10/containers/debian10_master_v18.8.0_nov22p1_online_flesnet.sif
#SBATCH --mem=11800

# Copyright (C) 2022 Facility for Antiproton and Ion Research in Europe, Darmstadt
# SPDX-License-Identifier: GPL-3.0-only
# author: Pierre-Alain Loizeau [committer]

## Replay a run at ~1x real speed

_nbts=0
if [ $# -ge 2 ]; then
  _run_id=$1
  _port=$2
  if [ $# -eq 3 ]; then
    _nbts=$3
  fi
else
  echo 'Missing parameters. Only following pattern allowed:'
  echo 'flesnet_replay_2022_ni.sbatch <Run Id> <port> [<Nb TS to replay>]'

  exit -1
fi

RUN_ID=${_run_id}

if [ 2352 -le ${RUN_ID} ] && [ ${RUN_ID} -le 2397 ]; then

  # After remapping of HDDs/SDDs
  Filename01=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node8_0_*.tsa
  Filename02=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node8_1_*.tsa
  Filename03=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node8_2_*.tsa
  Filename04=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node8_3_*.tsa
  Filename05=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node8_4_*.tsa
  Filename06=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node8_5_*.tsa
  Filename07=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node9_0_*.tsa
  Filename08=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node9_1_*.tsa
  Filename09=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node9_2_*.tsa
  Filename10=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node9_3_*.tsa
  Filename11=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node9_4_*.tsa
  Filename12=/lustre/cbm/prod/beamtime/2022/05/mcbm/nickel/${RUN_ID}_node9_5_*.tsa

  TS_LIMIT=""
  if [ 0 -lt $_nbts ]; then
    TS_LIMIT=" -n ${_nbts} "
  fi

  export PATH=/opt/flesnet/master_nov22p1_online/bin/:$PATH

  #tsclient -i file:"${Filename01};${Filename02};${Filename03};${Filename04};${Filename05};${Filename06};${Filename07};${Filename08};${Filename09};${Filename10};${Filename11};${Filename12}"? -P "tcp://*:${_port}" --publish-hwm 1 ${TS_LIMIT} --rate-limit 2 # slow readout
  tsclient -a -i file:"${Filename01};${Filename02};${Filename03};${Filename04};${Filename05};${Filename06};${Filename07};${Filename08};${Filename09};${Filename10};${Filename11};${Filename12}"? -P "tcp://*:${_port}" --publish-hwm 1 ${TS_LIMIT} --rate-limit 4 # close to real rate
  #tsclient -i file:"${Filename01};${Filename02};${Filename03};${Filename04};${Filename05};${Filename06};${Filename07};${Filename08};${Filename09};${Filename10};${Filename11};${Filename12}"? -P "tcp://*:${_port}" --publish-hwm 1 # max speed readout
else
  echo "Bad run id ${RUN_ID}. This script is valid only for the following range:"
  echo "runs [2352; 2397] (with some missing runs in-between)"

  exit -1
fi
