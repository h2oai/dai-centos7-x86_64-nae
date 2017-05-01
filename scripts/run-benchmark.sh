NGPU=$1

cd /opt/h2oaiglm/src
make -j gpu cpu
cd /opt/h2oaiglm/examples/cpp
ln -sf /data/train.txt .

echo "Starting Benchmark on $NGPU GPUs"
export N=$NGPU
make run 2>&1 | tee log$(N).txt
tar -cvfX benchmarks_`date +%Y%m%d_%H%M%S`.tar *.txt
cp *.tar /data
