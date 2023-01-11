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

### ODC gRPC Server

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

### Logs

ODC log is written to `$HOME/.ODC/log/odc_<date>.log`.

The logs for individual devices are stored under `$HOME/.DDS/sessions/<session_id>/wrk/<submission_id>/<job_id_and_node>`.

For anything larger than a handful of devices the location of logs and session files for DDS agents and user tasks should be moved to the local node. This can be configured in `$HOME/.DDS/DDS.cfg` under the key `agent.work_dir`.

## Known Issues

1. Sometimes agent submission gets stuck on worker package creation. Investigated in https://github.com/FairRootGroup/DDS/issues/468.

2. RepReqTsSampler does not return out of Running state on Stop transition. Possibly effect of missing input, but should still be fixed.
