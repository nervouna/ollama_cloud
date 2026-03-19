## 0.0.2

- Added `thinking` field to `ChatMessage`, `GenerateResponse`, and `GenerateChunk` for chain-of-thought reasoning support.
- Added `tool_calls` field to `ChatMessage` with typed `ToolCall` and `ToolCallFunction` models.
- Added `logprobs` field to `ChatResponse`, `ChatChunk`, `GenerateResponse`, and `GenerateChunk` with typed `LogprobItem` and `TopLogprob` models.
- Completed `ChatChunk` with full statistics fields (`total_duration`, `load_duration`, `prompt_eval_count`, `prompt_eval_duration`, `eval_count`, `eval_duration`).
- Exported `LogprobItem` and `TopLogprob` as part of the public API.

## 0.0.1

- Initial release of ollama_cloud Flutter SDK.
- Added generate and generateStream APIs.
- Added chat and chatStream APIs.
- Added embeddings API.
- Added model management APIs: tags, ps, show, pull, push, delete.
- Added typed exceptions for unauthorized, timeout, network, server, and invalid responses.
- Added NDJSON stream parser and streaming service tests.

### Notes

- Example currently demonstrates qwen3.5:397b-cloud workflows.
- Streaming APIs require server-side NDJSON support.
