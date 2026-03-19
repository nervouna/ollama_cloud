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
