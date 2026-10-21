# Workspace instructions

- 19 October 2026: the owner handed implementation to Claude, working directly in this repository (git). The Codex/GPT-6 Luna orchestration, usage-threshold and half-hour automation rules further down applied to ChatGPT/Codex and do not bind Claude sessions; product, content, licensing and safety rules still apply.

- Never put the computer to sleep or change power lifecycle settings. The user controls sleep manually.
- Gemini routing is disabled. Do not call Gemini or change its installed configuration. Project execution follows the GPT-6 Luna worker / Codex orchestrator policy below.
- Implement the three Turkish specification files in phase order. The later explicit six-game free tier in section 13.1b overrides the earlier summary.
- Preserve Android applicationId `com.YeS.OzelEgitimOyunlari`, versionCode >= 14. Do not change or publish signing keys.
- Release bundles are built only with `bash tools/build_release.sh` (21 October 2026, after vc16–vc19 closed on launch). The script checks that GeneratedPluginRegistrant is in the bundle, that the bundle is upload-signed, and that a cold launch of the release build on Pixel_9a stays up. Never build release with `--no-pub` and never delete the generated plugin registrant. Never hand over a bundle whose release build has not been launched.
- Play upload (Yunus, 21 October 2026): service-account key `android/play-service-account.json` (git-ignored, never print or copy it). `python tools/play_upload.py check` is read-only. `python tools/play_upload.py upload <aab> "<TR notes>" "<EN notes>"` rolls a bundle out to the internal testing track only. Use it only for bundles that passed `tools/build_release.sh`, and only after Yunus asks for that upload. Never touch production, closed or open tracks.
- Google Play release bundles (signed .aab, upload key via git-ignored `android/key.properties`) go in the project-root folder `GooglePlayBuild/` (Yunus, 20 October 2026), not under artifacts/. Test APKs stay in `artifacts/test-builds/`.
- Read DEVELOPMENT_STATUS.md before resuming. Keep actual completion and missing integrations distinct.
- Flutter 3.41.6 is installed. Dependencies in pubspec.lock have been resolved against its Dart 3.11.4; avoid blanket upgrades.
- Source Unity project is read-only: D:/GameDesktop/UnityProjects/SpecialEducationGames.
- ELEVENLABS_API_KEY is available in the environment. Never print, embed, copy to the app, or commit it. The original 20 Lauren samples are historical. Latest user selected Turkish İrem - Authoritarian Female Voice and English Laura - a top narration voice, eleven_multilingual_v2, with a period after single words. Preserve prior samples, verify exact IDs, and record slider settings as estimates where no numerical value was supplied. Do not buy credits or widen key permissions.
- Record meaningful tests and remaining work in DEVELOPMENT_STATUS.md after each work session.
- Illustrations (Yunus, 20 October 2026, narrows the 16 October rule below): designed parts (onboarding art, hero/header scenes, option pictures, decorative icons) are AI-generated illustrations made with ChatGPT image generation, all in the one style of `docs/illustration-style.md` (master prompt + per-asset prompts in `docs/illustration-prompts.md`; record each file in `assets/illustrations/onboarding/MANIFEST.json`, originals in `artifacts/illustrations-*`). Game content items stay real licensed photos. Onboarding uses illustrations only, never photos.
- User correction (16 October 2026): Do not generate new images with AI. Existing generated images are temporary and not approved for final content. Source natural real photographs from free internet libraries, verify each asset license and record its source/author/license. Research paid alternatives when useful, but do not purchase subscriptions without explicit authorization.
- Photo requirements: one complete animal/object, high-quality real photo, true alpha-transparent background, no cropped ears/paws/tail/fruit tips and no extra objects. Photo masking and crop/resize are authorized; preserve original photo detail rather than re-rendering. Samples are 1024×1024 RGBA PNG with aspect ratio preserved. Latest user requests larger cat framing and a white subject outline about 3–4 px (slightly more allowed). Continue authorized work without waiting for the absent user; do not treat historical samples as blanket final approval.
- Orientation (user decision, 19 October 2026, overrides "landscape-only" below): family/parent screens and onboarding are portrait; child mode (home, themes, games, round end, daily path, album, break) is landscape. The router sets preferred orientations per route.
- Latest UI requirements override the old design palette: landscape-only (superseded for family screens, see above), white or very faint cream canvas, vibrant orange/blue/turquoise, smooth rounded buttons with white borders, polished aligned category cards. Initial language follows the device (Turkish otherwise English), editable later in parent settings; do not ask language at onboarding.
- Read TODO.md with DEVELOPMENT_STATUS.md. Update relevant checkboxes after every concrete change, marking implemented but unverified and external blockers honestly. Application tasks must use GPT-6 Luna subagents under the latest execution policy below; integration/review stays with the primary Codex agent.

## Persistent execution policy — user instruction, 16 October 2026

- Until the user explicitly changes this instruction, delegate application implementation, bug fixes, implementation research and test authoring to native GPT-6 Luna subagents (model gpt-6-luna). DeepSeek and InferX are disabled as active workers; preserve their installed tools and credentials without calling them.
- Codex is the orchestrator: read requirements, split tasks, grant narrow file scopes, invoke the worker, inspect changes and evidence, run independent validation, and send corrections back to the worker. Do not silently implement application fixes yourself or substitute a different worker model. Native GPT-6 Luna subagents are explicitly authorized.
- Codex may maintain orchestration configuration, AGENTS.md, TODO.md, DEVELOPMENT_STATUS.md and task prompts/review records directly. The worker may propose changes to these control documents through its summary; Codex reconciles them after review.
- Grant write access per task, preserve unrelated work, inspect backups/action logs, and distinguish worker-reported completion from independently verified completion. A failed check goes back to the same model with concrete feedback.
- If the model, endpoint, credentials, tool capabilities or budget block a task, record the blocker and continue independent orchestration/review work. Do not silently bypass the selected worker. Broaden tooling only deliberately, preserving credential and project boundaries.
- This policy supersedes earlier project-local statements that implementation must use Codex or that simple tasks should use Codex subagents. Gemini remains disabled. It does not authorize publication, purchases, signing changes, image generation, power changes, automatic API retries or renewed recurring automations.
- Keep remote calls bounded and task-specific. Never send credentials, Unity source outside the permitted workspace, or the entire repository by default. Existing native service integrations remain subject to their external dependencies.



## Orchestration efficiency — user correction

- Keep Codex orchestration concise: do not repeatedly dump full source files, history or large tool logs into the main conversation. Let the GPT-6 Luna worker inspect scoped source; review bounded diffs and relevant evidence.
- Bundle a coherent implementation and its tests into one worker task. Use one consolidated independent validation after review; repeat only for actual changes or failed checks.
- Avoid prolonged provider diagnostics and repeated manual retries. Preserve working code and report a concrete blocker if bounded recovery fails. Do not switch away from the selected worker without authorization.
- Store each photo-mask attempt in a separate numbered directory. Preserve prior inputs, seeds, reports, outputs and previews before recovery attempts; a historical hash or review note does not replace the original artifact. Keep backup source files under non-source extensions such as `.dart.bak` so analyzer discovery does not treat relocated backups as application code.

## Usage thresholds — explicit user correction, 17 October
- Check remaining usage separately: stop code/model work only when five-hour remaining usage is below 8% OR weekly remaining usage is below 2%. Weekly remaining usage below 8% is not a stopping condition. Equality permits work. Never spend a reset credit automatically. Use existing later reset checks when blocked.
## Latest execution override — user instruction, 17 October 2026
- Use native GPT-6 Luna subagents (gpt-6-luna) for application work until the user changes this temporary preference. Do not call DeepSeek or InferX. This explicitly supersedes all older DeepSeek-only/native-worker-prohibition statements above and in historical logs. Keep primary Codex orchestration/review, narrow scopes, evidence-based tests and usage thresholds. Preserve provider configuration/credentials for later use; do not delete them.




## Continuous development — latest user request, 17 October
- Resume continuous authorized TODO work. The old 08:00 cutoff no longer applies. Keep the existing half-hour automation active; when usage allows, continue to the next task after completing one instead of stopping after a single job.
- Stop new code/model work only below the existing five-hour8% or weekly2% remaining thresholds. Keep half-hour reset checks while blocked.
- Prioritize a current installable test APK, emulator verification, meaningful release notes and honest outstanding integrations. Do not claim live services or all requirements completed from local tests alone.

## Host validation — observed runner limitation, 19 October
- Two default-parallel R25 host runs ended failed/inconclusive although the captured machine protocol marked every recorded test successful. A controlled `flutter test --no-pub --concurrency=1 --reporter expanded` run passed all227 tests. Until the parallel launcher discrepancy is isolated, prefer one serial full host validation after meaningful changes and preserve stdout/stderr separately. This does not establish that parallel execution is fixed; do not repeat passing checks without a new change or concrete concern. Evidence: artifacts/validation/r25-fixed-prompts/root/.

## Photo-attempt report preservation — observed loss, 19 October
- Treat a generated attempt report as write-once: create it exclusively, never reopen an existing report for writing, and put later review/status notes in a separate file. After acceptance/rejection, preserve its hash and keep finalized reports read-only; do not clear that protection to revise an attempt. Any lost report must be disclosed. A later measurement/reconstruction must use a new, explicitly labeled filename and must never be presented as the original. Inputs/scripts/outputs/previews remain in their numbered attempt folders.
