# Make your own custom AI code assistant

## Prerequisites

* [Ollama](https://ollama.com) and/or [LM Studio](https://lmstudio.ai) installed
* [Continue](https://www.continue.dev) plugin installed

**Note: You should have at least 8 GB of RAM available to run the 7B models,
16 GB to run the 13B models, and 32 GB to run the 33B models.**


## Configure Continue plugin to use local models

Click on the gear icon in the bottom right corner of Continue to open your `~/.continue/config.yaml`. For more information, see:
* [Editing config.json](https://docs.continue.dev/customize/overview#editing-configjson)
* [Model providers: Ollama](https://docs.continue.dev/customize/model-providers/ollama)

### Pull local models for code completion

Base LLMs (usually have `-base` suffix in the tag aliases) are foundational models trained on large, diverse datasets using unsupervised learning. They predict the next word in a sequence based on the context of previous words but are not optimized for specific tasks or instruction-following.

```sh
ollama pull qwen2.5-coder:1.5b-base
```

```sh
ollama pull qwen2.5-coder:3b-base
```

```sh
ollama pull qwen2.5-coder:7b-base
```

```sh
ollama pull qwen2.5-coder:14b-base
```

### Configure local models for autocomplete

```yaml
models:
  - name: Qwen2.5 Coder 1.5B base
    provider: ollama
    model: qwen2.5-coder:1.5b-base
    roles: [ autocomplete ]

  - name: Qwen2.5 Coder 3B base
    provider: ollama
    model: qwen2.5-coder:3b-base
    roles: [ autocomplete ]

  - name: Qwen2.5 Coder 7B base
    provider: ollama
    model: qwen2.5-coder:7b-base
    roles: [ autocomplete ]

  - name: Qwen2.5 Coder 14B base
    provider: ollama
    model: qwen2.5-coder:14b-base
    roles: [ autocomplete ]  
```

### Pull local models for chat

Instruction-Tuned LLMs (usually have `-instruct` suffix in the tag aliases) are derived from base models but undergo additional fine-tuning on datasets specifically designed for instruction-following tasks. Optimized to follow user prompts accurately and consistently, even for complex or multi-step instructions. Better at structured outputs like summaries, lists, or step-by-step guides. They adapt well to different tones and styles based on user requests

```sh
ollama pull cogito:8b
```

```sh
ollama pull cogito:14b
```

```sh
ollama pull qwen2.5:7b
```

```sh
ollama pull qwen2.5:14b
```

```sh
ollama pull qwen2.5-coder:7b
```

```sh
ollama pull qwen2.5-coder:14b
```

```sh
ollama pull deepseek-r1:14b
```

### Configure local models for chat

```yaml
models:
  - name: Cogito 8B
    provider: ollama
    model: cogito:8b
    roles: [chat, edit, apply]

  - name: Cogito 14B
    provider: ollama
    model: cogito:14b
    roles: [chat, edit, apply]

  - name: Qwen2.5 7B
    provider: ollama
    model: qwen2.5:7b
    roles: [chat, edit, apply]

  - name: Qwen2.5 14B
    provider: ollama
    model: qwen2.5:14b
    roles: [chat, edit, apply]

  - name: Qwen2.5 Coder 7B
    provider: ollama
    model: qwen2.5-coder:7b
    roles: [chat, edit, apply]

  - name: Qwen2.5 Coder 14B
    provider: ollama
    model: qwen2.5-coder:14b
    roles: [chat, edit, apply]

  - name: DeepSeek R1 14B
    provider: ollama
    model: deepseek-r1:14b
    roles: [chat, edit, apply]
```
or

```yaml
models:
  - name: Ollama
    provider: ollama
    model: AUTODETECT

  - name: LM Studio
    provider: lmstudio
    model: AUTODETECT
  ```

## Pull embeddings to power @Codebase

An "embeddings model" is trained to convert a piece of text into a vector, which can later be rapidly compared to other vectors to determine similarity between the pieces of text. Embeddings models are typically much smaller than LLMs, and will be extremely fast and cheap in comparison.

In Continue, embeddings are generated during indexing and then used by @Codebase to perform similarity search over your codebase.

```sh
ollama pull nomic-embed-text:v1.5
```

### Configure local embeddings to power @Codebase

```yaml
models:
  - name: Nomic Embed v1.5
    provider: ollama
    model: nomic-embed-text:v1.5
    roles: [ embed ]
```

### Configure context providers

Context Providers allow you to type '@' and see a dropdown of content that can all be fed to the LLM as context. Every context provider is a plugin, which means if you want to reference some source of information that you don't see here, you can request (or build!) a new context provider.

```yaml
context:
  - provider: file
  - provider: currentFile
  - provider: open
    params:
      onlyPinned: true
  - provider: tree
  - provider: code
  - provider: diff
  - provider: terminal
  - provider: problems
  - provider: search
  - provider: docs
  - provider: folder
  - provider: repo-map
    params:
      includeSignatures: false
  - provider: codebase

```

## [Examples](https://github.com/drafael/dotfiles/tree/master/.continue)