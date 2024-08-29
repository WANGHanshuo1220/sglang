# # When recieve ctrl+c from user
# cleanup() {
#     echo "Stopping ray server"
#     ray stop
#     echo "Ray server stopped."
#     exit 0
# }

# # Trace ctrl+c command
# trap cleanup SIGINT

# Run sglang server
HOST="0.0.0.0"
PORT="30000"
MODEL_PATH="/root/models/meta-llama/llama-2-7b-hf/"
MAX_MODEL_LEN=2048

python -m sglang.launch_server \
    --model-path $MODEL_PATH \
    --port $PORT \
    --host $HOST &
    # --enable-torch-compile \
    # --disable-radix-cache

echo "Run sgalng server in the background"

# Run sglang server benchmark
RANDOM_INPUT=64
RANDOM_OUTPUT=64
NUM_PROMPTS=2
QPS=1
FILE="/root/ShareGPT_V3_unfiltered_cleaned_split.json"

# Check if dataset exists
if [ -e "$FILE" ]; then
    echo "$FILE already exist"
else
    echo "$FILE does not exist, downloading it ..."
    exit 1
fi

# Wait 180 seconds for server to initialize...
timeout 180 bash -c "until curl -s localhost:$PORT/health > /dev/null; do sleep 1; done" || exit 1
echo "Server ready."
python3 -m sglang.bench_serving \
        --backend sglang \
        --dataset-name random \
        --dataset-path ${FILE} \
        --random-input ${RANDOM_INPUT} \
        --random-output ${RANDOM_OUTPUT} \
        --num-prompts ${NUM_PROMPTS} \
        --request-rate ${QPS} \
        --output-file online.jsonl

# curl http://$HOST:$PORT/generate -H "Content-Type: application/json" -d '{"text": "Once upon a time,","sampling_params": {"max_new_tokens": 16,"temperature": 0}}'

pkill -f "python -m sglang.launch_server"
