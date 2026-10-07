# Content-pack format

Content packs let curriculum evolve independently from the app and keep initial
installation size modest.

## Manifest requirements

Every pack declares:

- stable pack ID and semantic version;
- title, description, language, and licence metadata;
- prerequisite pack/skill IDs;
- minimum compatible app and schema versions;
- compressed and installed sizes;
- SHA-256 digest and release signature;
- included skills, lessons, generators, curated questions, and assets.

## Content requirements

Every skill has a stable ID and dependency links. Every question identifies its
skills, difficulty, response type, answer contract, explanation, and source or
original-author metadata. Generated questions additionally identify generator
and template versions and validate parameter constraints during compilation.

Pack installation is transactional: validate signature, checksum, schema,
references, and storage availability before activation. Keep the previous pack
version until activation succeeds.

Progress refers to stable IDs and versions, never local file paths. Removing or
upgrading a pack therefore cannot erase learning history.

## Implemented schema versions

- Version 1: stable skills and deterministic arithmetic templates.
- Version 2: offline concept cards, hint ladders, and HTTPS refresher links.
- Version 3: directed skill prerequisites and explicit learning-goal-to-skill
  mappings.

Version-3 activation validates missing, duplicate, and self prerequisite
references; rejects cycles; and checks every goal and referenced skill. Older
packs remain readable and receive empty prerequisite and goal collections.
