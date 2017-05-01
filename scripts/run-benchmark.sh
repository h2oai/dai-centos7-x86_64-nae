cd /opt/h2oaiglm/src
make -j gpu cpu
cd /opt/h2oaiglm/examples/cpp
ln -sf /data/train.txt .
export N=16
make run 2>&1 | tee log$(N).txt
cp log$(N).txt /data
