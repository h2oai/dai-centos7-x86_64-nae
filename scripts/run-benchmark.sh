export CUDA_HOME=/usr/local/cuda-8.0
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

cd /opt/h2oaiglm/src
make -j gpu cpu
cd /opt/h2oaiglm/examples/cpp
ln -sf /data/train.txt .

echo "Starting Benchmark on $NGPU GPUs"
export N=$1
make run 2>&1 | tee log$N.txt
tar -cvf benchmarks_gpu$1_`date +%Y%m%d_%H%M%S`.tar `find . -name "me*.txt"`
mv *.tar /data
