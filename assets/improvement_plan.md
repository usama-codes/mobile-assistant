# Improvement Plan: Flutter AI Productivity Assistant
### Target: make this the standout project on a fresh-grad Software Engineering CV in 2026

---

## Part 1 — Edits to existing code (nothing gets deleted, but two things get restructured)

### 1.1 Consolidate the two encryption implementations into one crypto module
Right now the Documents Manager and the Long-Term Memory feature each have their own path to encrypting data on disk. Two independent implementations of encryption in the same codebase is not two features, it is a liability. If one implementation has a subtle bug (wrong IV reuse, weak key derivation, missing authentication tag check) you now have two places to find and fix it, and a reviewer has to audit both. The fix is not new functionality, it is a refactor: pull both call sites onto a single `VaultService` class that wraps one hardened implementation, backed by a key that lives in the Android Keystore rather than anywhere in your own database. Use the `cryptography` package (pub.dev) for the actual AES-GCM authenticated encryption primitives, and `flutter_secure_storage` (which you already have for the lock feature) to store the derived key material, never the plaintext key, and never in SQLite. This single change turns "I encrypted two features" into "I built a shared security layer," which is the correct framing for a CV bullet and the correct engineering practice.

### 1.2 Retrofit Clean Architecture layering
From your description, the app is organized by feature folder (`lib/features/chat`, `lib/features/tasks`, etc.), which is good, but there is no mention of a domain/data/presentation split inside those folders. Without that split, business logic (deciding how to sort tasks, deciding when the agent should call a tool, deciding how memory importance decays) tends to leak directly into widgets, which makes the logic untestable without spinning up the whole UI. Restructure each feature folder into three layers: `domain` (pure Dart entities and use-case classes, zero Flutter imports), `data` (repository implementations, local/remote data sources), and `presentation` (widgets and state management). This is not cosmetic — it is what makes Part 2 (testing) possible without slow, flaky widget-only tests. No new package is required for the split itself, but see 1.3 for the state management layer that ties it together.

### 1.3 Formalize state management with Riverpod
If the app currently uses `setState` or ad-hoc `ChangeNotifier`s scattered across screens, standardize on **Riverpod** (`flutter_riverpod` + `riverpod_generator` for code generation). Riverpod is currently one of the two most requested state management skills in Flutter job postings (alongside Bloc), it gives you compile-time-safe dependency injection without a separate service locator, and — critically for your testing goals — it lets you override any provider with a fake implementation in tests without touching the widget tree. Pair it with `freezed` for immutable state classes and sealed unions (loading/data/error states), which is the current standard for representing async UI state cleanly.

---

## Part 2 — Testing and CI infrastructure (currently the single biggest gap)

### 2.1 Unit tests for the domain layer
Once 1.2 is done, the domain layer (task sorting logic, memory importance scoring, encryption wrapper contracts, agent tool-selection logic) can be tested with zero Flutter dependency using the built-in `test` package. This is where most of your test count should live — aim for the bulk of your suite here, since these tests run in milliseconds and don't need a simulator.

### 2.2 Widget tests for UI components
Use `flutter_test` (built-in) for individual widgets: the task list sorting by priority and deadline, the chat bubble rendering agent steps, the settings toggles. Use `mocktail` (not `mockito`) for creating fakes of your repositories — it avoids the code-generation step mockito requires and has better null-safety ergonomics.

### 2.3 Integration tests for the two flows that actually differentiate this app
Full integration tests are expensive to maintain, so use them sparingly and only for your flagship flows: the "document → OCR → task extraction → agent creates task" pipeline, and the biometric unlock flow. Use the `integration_test` package (the officially supported successor to `flutter_driver`). For the biometric/native-dialog interaction specifically, add **Patrol**, which can actually interact with native permission and biometric prompts that plain `integration_test` cannot reach.

### 2.4 Golden tests for visual regression
Add `golden_toolkit` to snapshot key screens (chat screen, task list, settings). This catches accidental UI breakage from refactors and is a cheap way to show you think about regression, not just features.

### 2.5 CI pipeline with GitHub Actions
This is free for public repositories and is the single highest-leverage addition on this entire list, because it is the first thing a recruiter or hiring manager checks when they open your repo — a green checkmark next to your latest commit. Add a `.github/workflows/ci.yml` that runs on every push and pull request: checkout, set up Flutter via `subosito/flutter-action`, `flutter pub get`, `flutter analyze`, `flutter test --coverage`, and upload the coverage report. Add `very_good_analysis` as your lint ruleset (stricter than the default `flutter_lints`) so `flutter analyze` is actually enforcing something. Gate merges to `main` on this workflow passing.

---

## Part 3 — Make the "AI Agent" a real function-calling agent, not a prompted illusion

If the current "Agent Execution Pipeline" works by asking Gemini to produce a plan in free text and then your Dart code parses that text to decide what to do, that is fragile and will not hold up under a technical interview question about how it works. The correct 2026 pattern is native function calling: you declare your tools (create task, extract text from image, save memory fact, search documents) as structured `FunctionDeclaration` objects with JSON schemas, send them to Gemini alongside the conversation, and the model returns a structured tool-call object that you execute directly — no text parsing involved. The `google_generative_ai` package you're already using supports function declarations natively, so this is an upgrade to your existing dependency, not a new one. Wrap each tool behind a shared `AgentTool` abstract class (name, JSON schema, `execute()` method) and register them in a `ToolRegistry`, so adding a new capability to the agent later is a one-file change. If you want a more structured orchestration layer on top of this rather than hand-rolling the loop, look at `dartantic_ai`, a Dart-native agent orchestration package built specifically for this pattern.

---

## Part 4 — Turn "Long-Term Memory" into real semantic memory (Agentic RAG)

A weighted SQLite fact table is a reasonable v1, but it cannot do what actual memory-augmented agents do in 2026: retrieve facts by *meaning*, not by manually-assigned importance scores. The current dominant architecture — agentic RAG — has the LLM decide what to retrieve and when, then a vector index returns semantically similar stored facts, which get injected into the next prompt. Implement this with **ObjectBox**, which as of version 4.0 ships the first on-device vector database for Dart/Flutter, supports HNSW-indexed vector search alongside normal object storage, works fully offline, and has a small footprint appropriate for a phone. Generate the embeddings for each memory fact using Gemini's embedding endpoint (or an on-device embedding model if you want a fully offline story — see Part 5), store the vector alongside the fact in ObjectBox, and at query time embed the user's current message and run a nearest-neighbor search to retrieve the top-k relevant facts instead of just sorting by an importance column. Keep the importance-weight column too — use it as a secondary ranking signal (recency + importance + semantic similarity), which is a more sophisticated retrieval story than either approach alone.

---

## Part 5 — Offline / hybrid on-device inference

Right now the assistant appears to be fully dependent on a network connection and a paid Gemini API call for every interaction. Adding a small on-device model as a fallback (or as the default for cheap, latency-sensitive operations like intent classification) is directly on-trend for 2026 and gives you a genuinely interesting architecture story: "cloud model for complex reasoning, on-device model for offline and low-latency operations." Use `flutter_gemma`, which runs Google's Gemma models on-device via MediaPipe with no server dependency, entirely free and open source. This also strengthens your existing privacy narrative (local encrypted documents, local encrypted memory) — a fully local fallback path means the app can plausibly work with zero data leaving the device.

---

## Part 6 — Observability

There is currently no way to know when the app crashes for a real user, and no usage data to know which features are actually used. Add `firebase_crashlytics` and `firebase_analytics` — both are free at your scale, take under an hour to wire up, and there is no legitimate reason for a production-oriented app not to have them. Crashlytics gives you real stack traces from real devices; Analytics gives you screen-view and event funnels you can screenshot for a portfolio write-up ("60% of sessions use the OCR-to-task flow" is a far stronger CV line than a feature list). Pair this with the `logger` package for structured local logging during development.

---

## Part 7 — Deployment and distribution

A project that only exists as source code on GitHub is much less convincing than one with an install link. Configure a signed release build (`compileSdk`/`targetSdk` 35, Android App Bundle format — Google Play no longer accepts raw APKs for production uploads), enable Play App Signing, and push to the Play Console's **Internal Testing** track, which is free and does not require the full production review process to get a shareable install link. Automate this with **Fastlane** (`fastlane supply`), a free, open-source tool that handles metadata, screenshots, and upload to the Play Console from the command line — wire it into the same GitHub Actions workflow from Part 2 so a tagged release automatically produces a new internal build. Even if you never go to public production, "CI builds and ships to an internal testing track on every release tag" is a concrete, verifiable engineering claim.

---

## Part 8 — Two product gaps worth closing since they're natural extensions of what you already have

### 8.1 Local notifications for task deadlines
The Smart Task Manager has priorities and deadlines but, from your description, no reminder mechanism — a task manager that doesn't remind you of anything is missing its main value proposition. Add `flutter_local_notifications` to schedule a local notification at (or before) each task's deadline. This is a small addition that closes an obvious gap a reviewer will notice immediately.

### 8.2 Localization for Urdu and English
You've already built Urdu speech-command handling for your separate Jarvis project — bringing that same bilingual awareness into this app's UI (via `flutter_localizations` and the `intl` package, or the `slang` package for type-safe generated translations) is low-effort given your existing experience and demonstrates internationalization skill, which is explicitly called out as a differentiator in current portfolio guidance and is rarely present in student projects.

---

## Part 9 — The numbers you need to be able to say out loud in an interview

Recruiters and interviewers in 2026 are explicitly looking for quantified outcomes, not feature lists. Once the above is implemented, capture and remember these figures, because "I built an OCR feature" is forgettable and "OCR extracts task deadlines from scanned documents with 94% field accuracy across 50 test documents" is not:
- OCR extraction accuracy (build a small labeled test set of 30-50 scanned documents and measure it)
- Agent tool-call success rate (what fraction of agent-issued tool calls execute without error across a fixed test conversation set)
- Cold-start and average response latency for cloud vs on-device inference paths
- Test coverage percentage from `flutter test --coverage`
- Encrypted read/write overhead versus unencrypted (even a rough millisecond delta is a legitimate, honest metric)
- Crash-free session rate from Crashlytics after a week of your own dogfooding

---

## Suggested order of implementation

1. Consolidate encryption (1.1) — small, removes a real security smell, do it first.
2. Domain/data/presentation split + Riverpod (1.2, 1.3) — unlocks everything else.
3. Unit + widget tests and CI (Part 2) — highest visibility-to-effort ratio.
4. Native function calling for the agent (Part 3) — turns your flagship feature into a defensible technical story.
5. Crashlytics + Analytics (Part 6) — an hour of work, disproportionate credibility gain.
6. Vector-based semantic memory (Part 4) — the most technically impressive single addition, do it once the foundation above is solid.
7. Deployment pipeline (Part 7) — do this once you have something you're proud to show installed on a real device.
8. On-device fallback model, notifications, localization (Part 5, Part 8) — polish, in whatever order fits your remaining time.
