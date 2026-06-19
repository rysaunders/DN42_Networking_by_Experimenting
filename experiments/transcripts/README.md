# Transcript Conventions

Checked-in validation transcripts live directly in this directory. Chapters may reference those files by exact name.

Local lab runs write to `experiments/transcripts/local/` by default. That directory is ignored by Git so readers and maintainers can rerun labs without creating accidental tracked files.

To intentionally refresh a checked-in validation transcript, set `LAB_TRANSCRIPT_PATH` to the exact tracked path before running the lab script:

```sh
LAB_TRANSCRIPT_PATH=experiments/transcripts/<lab-name>-<timestamp>.txt \
  experiments/labs/<lab-name>/run.sh
```

When a checked-in transcript filename changes, update every chapter that references it.
