# Arsenal: Evolved — server downloads

Public distribution repo for **Arsenal: Evolved** on **Paper 1.21.11**.

This repo holds only release artifacts and a small updater. The plugin source
lives in [Snipernode/ARSENAL-EVOLVED](https://github.com/Snipernode/ARSENAL-EVOLVED).
The resource pack stays a **separate artifact** — it is never embedded in the
plugin jar.

## What is here

| File | Purpose |
| --- | --- |
| `ArsenalEvolved-0.1.0-SNAPSHOT.jar` | Plugin jar; drop into the server `plugins/` folder. |
| `Arsenal-Evolved-ResourcePack.zip` | Companion resource pack for Minecraft 1.21.11 (format 75). |
| `Arsenal-Evolved-ResourcePack.zip.sha1` | Pack hash used by the plugin's pack delivery/hosting. |
| `manifest.json` | Current version, file sizes and SHA-1/SHA-256 hashes. |
| `update.sh` | Checks the manifest and downloads only files that changed. |

## First install

From the server directory:

```bash
mkdir -p plugins/ArsenalEvolved/resourcepack
curl -fsSLo plugins/ArsenalEvolved-0.1.0-SNAPSHOT.jar \
  https://raw.githubusercontent.com/Snipernode/aresnal-evolved-resource-pack-repo/main/ArsenalEvolved-0.1.0-SNAPSHOT.jar
curl -fsSLo plugins/ArsenalEvolved/resourcepack/Arsenal-Evolved-ResourcePack.zip \
  https://raw.githubusercontent.com/Snipernode/aresnal-evolved-resource-pack-repo/main/Arsenal-Evolved-ResourcePack.zip
curl -fsSLo plugins/ArsenalEvolved/resourcepack/Arsenal-Evolved-ResourcePack.zip.sha1 \
  https://raw.githubusercontent.com/Snipernode/aresnal-evolved-resource-pack-repo/main/Arsenal-Evolved-ResourcePack.zip.sha1
```

Then start the server once to generate `plugins/ArsenalEvolved/config.yml`.

## Updating

Run the updater from the server root (the directory that contains `plugins/`):

```bash
curl -fsSL https://raw.githubusercontent.com/Snipernode/aresnal-evolved-resource-pack-repo/main/update.sh -o update-arsenal.sh
chmod +x update-arsenal.sh
./update-arsenal.sh
```

It prints `UP-TO-DATE`, `UPDATE AVAILABLE`, or `INSTALLED` for each file and
verifies SHA-256 before replacing anything. To only check for updates without
changing files:

```bash
./update-arsenal.sh --check
```

Override destinations if your server uses a non-standard layout:

```bash
PLUGIN_DIR=/srv/minecraft/plugins \
PACK_DIR=/srv/minecraft/plugins/ArsenalEvolved/resourcepack \
./update-arsenal.sh
```

After an update, restart the server, or run `/arsenal reload` and
`/arsenal pack reload` in-game. Players will be sent the new pack when it is
enabled for auto-send, or on demand with `/arsenal pack send <player>`.

## Manifest

`manifest.json` is the source of truth for the updater:

```json
{
  "minecraft": "1.21.11",
  "source_commit": "c95cb33c4027b85a2fd2c1e8a9121b9a646ae741",
  "artifacts": {
    "plugin": { "file": "...", "version": "...", "size": 0, "sha1": "...", "sha256": "..." },
    "resourcepack": { "file": "...", "version": "...", "size": 0, "sha1": "...", "sha256": "..." }
  }
}
```

Every artifact update should refresh the file, its `.sha1` sidecar (pack only)
and the manifest in the **same commit**, so a server can never fetch a mismatched
pair.

## Publishing

Updates are published from the source repo with `./scripts/publish-dist.sh`.
It rebuilds both artifacts, refreshes `manifest.json`, commits and pushes in a
single step. Servers then run `update.sh` (or `update.sh --check`) to pick up the
new files.
