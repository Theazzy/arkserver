# AGENTS.md — arkserver (Code)

Schlankes, öffentliches **Code-Repo** für den gehärteten, eigenständigen ARK-SE-Docker-Server.
Enthält nur Build-/Run-Artefakte: `Dockerfile`, `bin/`-Skripte, `docker-compose.yml`,
`.env.example`, CI.

## Steuerung & Doku liegen woanders
Planung, Backlog, Betriebs-Dokumentation und AI-Kontext leben im Schwester-Repo
**`../arkserver-ops`**. Vor inhaltlicher Arbeit dort `backlog/backlog.md` und die aktive
`backlog/phase-x.md` lesen.

## Konventionen
- **Eine Session = eine Backlog-Phase.**
- Secrets nur in `.env` (gitignored), niemals committen.
- `.dockerignore` muss Doku/`.git`/Hilfsdateien aus dem Build-Kontext halten.
- Basis-Image und arkmanager gepinnt (Digest/Commit) – keine schwebenden `latest`-Abhängigkeiten.
- Edition: ARK **Survival Evolved** (App-ID `376030`).
