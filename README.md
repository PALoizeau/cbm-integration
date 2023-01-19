# CBM Integration

This repository contains a topology and configuration files needed for running CBM FairMQ devices with ODC/DDS.

## Steps to run on the Virgo cluster with Slurm

We take `lxbk0600` node here for convenience, but you can take any other or a random `lxlogin` node. You will need to know the node name where `odc-grpc-server` runs to connect to it with `odc-grpc-client`.

We use the container `/cvmfs/cbm.gsi.de/debian10/containers/debian10_master_v18.8.0_nov22p1_nodds.sif`, where CBM, ODC and DDS are installed under /opt/.

Adjust the host names and paths for your environment

### Environment setup (for both ODC server and client)

1. Launch the CBM+ODC+DDS container on Virgo (both for ODC server and client)

```sh
SINGULARITY_CONTAINER=/cvmfs/cbm.gsi.de/debian10/containers/debian10_master_v18.8.0_nov22p1_nodds.sif ssh -o SendEnv=SINGULARITY_CONTAINER lxbk0600
```

2. initialize CBM, ODC, DDS environment

```bash
source /opt/cbmroot/master_v18.8.0_nov22p1_nodds/bin/CbmRootConfig.sh -a
```

3. Disable http_proxy for gRPC
```bash
export no_grpc_proxy=lxbk0600
```

4. set HOME to a path on Lustre, to be used for DDS/ODC session files and logs (can be configured separately)
```bash
export HOME=/lustre/rz/orybalch/
```

### ODC gRPC server

```bash
odc-grpc-server --sync --host "*:6667" --rp "slurm:/opt/fairsoft/nov22p1_nodds/bin/odc-rp-epn-slurm --zones online:5:/lustre/rz/orybalch/cbm-integration/slurm-main.cfg:" --timeout 120
```

### ODC gRPC client

You can run client interactively, or have it execute a set of given commands sequentially.

```bash
odc-grpc-client --host lxbk0600:6667
```
For an interactive run, the following client commands start a session, launch the topology and bring it from Idle to Running and back and terminate the session.

```
.run -p slurm -r "{\"zone\":\"online\",\"n\":1}" --topo /lustre/rz/orybalch/cbm-integration/topology.xml
.config
.start
.stop
.reset
.term
.down
```

To check the state of the devices at any point (when they already exist):
```
.state --detailed

```

## Steps to run the "full" test case with data flowing from the mFLES cluster at close to real bandwidth

1. Same Environment setting as for chain described above
1. Set SDE_HOME to the folder where the clone of this repo was placed and go to it
```bash
export SDE_HOME=/lustre/cbm/users/ploizeau/sde2023
cd $SDE_HOME
```
1. Start the ODC gRPC server with 8 possible device slots (!Remember to check with `ps aux | grep 6668` if the port is already used on this lxbk node and increase it if needed)
```bash
odc-grpc-server --sync --host "*:6668" --rp "slurm:/opt/fairsoft/nov22p1_nodds/bin/odc-rp-epn-slurm --zones online:8:$SDE_HOME/cbm-integration/slurm-main.cfg:" --timeout 120
```
1. Start the ODC client
```bash
odc-grpc-client --host lxbk0600:6668
```
1. In the client, start the topology and move it to the `READY` state
```bash
.run -p slurm -r "{\"zone\":\"online\",\"n\":1}" --topo /lustre/cbm/users/ploizeau/sde2023/cbm-integration/topology_mfles.xml
.config
```
1. In another console connected to virgo, check with squeue on which node (`lxbk<XXXX>`) the topology was started
1. Connect a web browser to `lxbk<XXXX>:8080` (from within the GSI trusted network, e.g. lxg or lxi node, you may need to use `Chromium` instead of `Firefox` depending on the versions)
1. Connect to the mFLES cluster (`cbmfleslogin01`, you will need an account there) and start the replay (it does not matter if the first timeslices are not caught)
```bash
spm-run /home/loizeau/scripts/replayers_node_2022_Ni_Au.spm
```
1. In the ODC client, move the topology to the `RUNNING` state
```bash
.start
```
1. Wait until it succeeds, then check that all devices are still alive after receiving the first TS, then try to refresh the web-browser page (it may take 10-20s to receive the first batch of plots)
1. Click in the folder explorer in the left tab on `canvases` and thein either `cEvBSummary` or `cSampSummary_` to see some of the plots, then tick `Monitoring` to have live updates
1. When done, first stop the topology in ODC client (got from `RUNNING` to `READY` state)
```bash
.stop
```
1. When state transition returned (not before otherwise the Sampler will hang!), stop the replayer on `mFLES` with `CTRL + C`
1. Then tear down the topology in ODC client with the following sequence (the output and histogram root files should then be cleanly written to disk)
```bash
.reset
.term
.down
```

### Logs

ODC log is written to `$HOME/.ODC/log/odc_<date>.log`.

The logs for individual devices are stored under `$HOME/.DDS/sessions/<session_id>/wrk/<submission_id>/<job_id_and_node>`.

For anything larger than a handful of devices the location of logs and session files for DDS agents and user tasks should be moved to the local node (for example to `/tmp/`). This can be configured in `$HOME/.DDS/DDS.cfg` under the key `agent.work_dir`.

## Known Issues

1. Sometimes agent submission gets stuck on worker package creation. Investigated in https://github.com/FairRootGroup/DDS/issues/468.

2. RepReqTsSampler does not return out of Running state on Stop transition. Possibly effect of missing input, but should still be fixed. \
   => Confirmed to be due to missing input: the sampler is asking for the next timeslice through a flesnet library call and this call never returns if input not present in network mode. \
   This leads to hangup if a state transition is attempted at this stage (e.g. stopping before the source starts emitting or stopping after the source stopped emitting) \
   =>To be discussed with the `flesnet` team.

3. Environment variable expansion does not work when pointing to the topology in the ODC `.run` command, even when it is defined in both client and server sides

4. The stop sequence is not controlled, sometimes leading to errors because clients try to contact servers which are already in the `READY` state.
