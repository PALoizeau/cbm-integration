## CBM Integration

SINGULARITY_CONTAINER=/cvmfs/cbm.gsi.de/debian10/containers/debian10_master_v18.8.0_nov22p1_nodds.sif ssh -o SendEnv=SINGULARITY_CONTAINER lxbk0600

export no_grpc_proxy=lxbk0600
export HOME=/lustre/rz/orybalch/

odc-grpc-server --sync --host "*:6667" --rp "slurm:/opt/fairsoft/nov22p1_nodds/bin/odc-rp-epn-slurm --zones online:5:/lustre/rz/orybalch/cbm-integration/slurm-main.cfg:" --timeout 120

odc-grpc-client --host lxbk0600:6667


.init
.submit -p slurm -r "{\"zone\":\"online\",\"n\":1}"
.activate --topo /lustre/rz/orybalch/cbm-integration/topology.xml
.config
.start
.stop
.reset
.term
.down
