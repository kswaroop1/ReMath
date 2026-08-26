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
