# DETAILED PLAN

## 1 Define the domain model and scope

Start with the smallest possible problem definition.

Create the core entities:

- `ChatMessage`
- `TaskItem`
- `ReminderItem`
- `NoteItem`
- `MemoryFact`
- `AttachmentItem`
- `UserPreference`
- `AgentAction`
- `ParsedIntent`

Define the allowed intents:

- create task
- complete task
- reschedule task
- create reminder
- save note
- remember fact
- search memory
- summarize text
- extract text from image

Define response types:

- confirmation
- clarification request
- error
- result summary
- follow-up suggestion

This must come first because every later component will read or write these models.

## 2 Build the Flutter shell with feature boundaries

Create the app skeleton before any AI logic.

Implement:

- app routing
- theme
- bottom navigation or drawer
- empty screens for chat, tasks, memory, settings
- shared widgets for cards, chips, input bars, loading states, error states

Use a feature-first folder structure:

- `features/chat`
- `features/tasks`
- `features/memory`
- `features/ocr`
- `features/settings`
- `core/domain`
- `core/data`
- `core/services`

This comes before anything else because the app must have stable screens and layout boundaries before the logic is wired in.

## 3 Add local storage and repository abstractions

Put persistence in place before intelligence.

Implement a local database layer:

- SQLite or Hive
- repositories for tasks, notes, messages, memory, and attachments
- CRUD operations
- migration/versioning strategy
- search by keyword, date, and type

Add a repository interface layer so the rest of the app does not know whether data is local, Firebase-backed, or mixed.

This is mandatory because chat history, memory, and tasks all depend on persistence.

## 4 Build the basic chat UI and message pipeline

Now create the visible conversation flow.

Implement:

- message list
- typing indicator
- input composer
- send button
- message states: sent, processing, done, failed
- message metadata: timestamp, intent, source, confidence

At this stage the chat is not smart. It only sends input into a pipeline and displays output.

This must come before NLP because you need a stable entry point for all user instructions.

## 5 Implement deterministic intent parsing

Do not use Gemini yet. Use rules first.

Build a parser that:

- normalizes text
- detects intent by keywords and patterns
- extracts dates, times, durations, priorities, names, and task titles
- assigns a confidence score
- marks ambiguous input for clarification

Examples:

- “remind me tomorrow at 7 to study DSA”
- “finish assignment tonight”
- “save this as a note”
- “what did I say about the internship?”

Use regex, keyword maps, and simple heuristics.

This must come before Gemini because the parser becomes your fallback system and your debugging baseline. Without it, you will not know whether later failures come from the model or your app.

## 6 Build the task and reminder engine

Make the assistant capable of doing something concrete.

Implement:

- create task
- update task
- delete task
- mark complete
- set reminder date/time
- recurring reminders
- priority levels
- overdue detection
- task filtering
- daily agenda view

At this stage, the assistant should already be useful without any AI.
This is important because task management is the main product utility and the backbone of the agent behavior.

## 7 Add local notifications and schedule handling

Once reminders exist, make them actually trigger.

Implement:

- local notifications
- notification tap actions
- snooze
- mark done from notification
- reschedule from notification
- recurring notification logic
- timezone-safe scheduling

This must happen after the reminder engine because notifications depend entirely on the reminder objects and their lifecycle.

## 8 Build the memory system

Now add persistence with meaning.

Implement memory categories:

- personal facts
- preferences
- recurring context
- project-specific facts
- pinned memories
- recent memories

Add memory operations:

- save memory
- update memory
- delete memory
- rank memory by relevance
- retrieve memory by keyword and recency
- retrieve memory by semantic-like tags if available
- mark memory as important

Make memory write-only from verified events at first. Do not let the model invent memories.

This comes after storage and tasks because memory retrieval depends on a reliable database and a structure for confidence.

## 9 Add Firebase only for sync, auth, and backup

Now use Firebase selectively, not as the core.

Implement:

- authentication if needed
- Firestore sync for selected collections
- cloud backup of tasks, notes, and memories
- optional file storage for attachments
- sync conflict rules

Keep the app fully usable without Firebase. Firebase should be an upgrade path, not a dependency.

This must come after local storage because local-first data architecture is simpler, cheaper, and safer. Firebase is a synchronization layer, not the foundation.

## 10 Integrate Gemini as the reasoning layer

Only now bring in Gemini.

Use Gemini for:

- intent disambiguation
- summarization
- task extraction from messy text
- memory extraction
- assistant-style response generation
- planning multi-step actions
- rewriting user input into structured actions

Do not ask Gemini to directly control everything.
Use it as a reasoning service that outputs structured JSON or tool-call-like results.

Example flow:

1. user says: “I need to finish the ML assignment by Friday and revise CNNs”
2. deterministic parser extracts obvious entities
3. Gemini clarifies missing structure if needed
4. planner converts it into tasks and reminders
5. repository stores them
6. UI confirms the action

This must come after the deterministic system because Gemini works best as augmentation, not as the first line of logic.

## 11 Build the planner and tool execution layer

This is the true agent layer.

Implement a planner that:

- receives user input
- decides whether to use rules or Gemini
- selects the tool to invoke
- validates the tool arguments
- executes the tool
- stores the result
- returns a response to the UI

Tools should include:

- createTask
- updateTask
- completeTask
- createReminder
- saveMemory
- searchMemory
- summarizeText
- extractTextFromImage

This layer depends on every previous layer:

- it needs models
- it needs repositories
- it needs tasks
- it needs memory
- it needs Gemini
- it needs notification scheduling

Without those, the planner has nothing to orchestrate.

## 12 Add OCR and image ingestion

Now add the CV component.

Implement:

- camera capture
- gallery import
- image preprocessing
- OCR extraction
- extracted text preview
- “save as note” action
- “convert to task” action
- “summarize text” action

Flow:

1. user scans a screenshot, document, or whiteboard
2. OCR extracts text
3. parser identifies task-like pieces
4. Gemini optionally summarizes or structures it
5. user saves it to notes/tasks/memory

This must come after the planner because OCR is not just vision; it becomes useful only when the extracted text can be routed into tasks, notes, or memory.

## 13 Add summarization and text-to-structure workflows

Now make the app handle large text intelligently.

Implement:

- summarize long notes
- summarize OCR output
- extract action items from notes
- extract deadlines
- extract names and topics
- create tasks from summaries

This depends on Gemini and the memory/task system because summarization is only valuable if it can feed a downstream action.

## 14 Add conversation memory and retrieval-augmented responses

Now connect memory to chat.

Implement:

- retrieve relevant memories before responding
- inject memory snippets into Gemini prompts
- show citations or source cards inside the app
- ask clarifying questions when memory is insufficient
- keep chat context across sessions

This is later in the plan because memory retrieval only makes sense once tasks, notes, and memory storage already exist.

## 15 Add agentic multi-step flows

Now let the assistant handle compound requests.

Examples:

- “Save this note, remind me next week, and make it urgent”
- “Read this screenshot, summarize it, and create tasks”
- “Find my notes about CNNs and tell me what I should revise”

Implement:

- multi-step action planning
- branching execution
- rollback or partial failure handling
- confirmation gates for destructive actions
- retry logic

This belongs near the end because it depends on the entire system being stable. Agentic behavior is the highest-complexity layer.

## 16 Add offline fallback behavior

Make the app robust without depending on Gemini.

Implement:

- rule-based fallback if API fails
- offline task creation
- offline note saving
- offline reminder scheduling
- cached responses for repeated queries
- graceful degradation when OCR or Gemini fails

This is important because your project must not collapse when the API quota is exhausted or unavailable.

## 17 Add privacy, security, and data control

Harden the app.

Implement:

- delete all data
- export data
- optional app lock
- encrypted sensitive storage
- clear permission prompts
- camera and notification permission flow
- minimal data retention

This is late in the plan because privacy features become easier once the data architecture is stable.

## 18 Add observability and metrics

Add proof that the system works.

Track:

- intent detection accuracy
- task creation success rate
- reminder scheduling success rate
- OCR extraction success rate
- summary length reduction
- Gemini latency
- number of successful tool executions
- number of fallback invocations

This is useful for your resume and for debugging.

## 19 Polish the UX

Now improve presentation.

Implement:

- polished empty states
- quick action chips
- task cards with status
- memory cards
- OCR preview cards
- subtle transitions
- dark mode
- responsive layout
- error recovery UI

Do this only after the engine works. Otherwise you will polish a broken system.

## 20 Build the demo scripts last

Prepare a few scripted flows.

Demo flow 1:

- create task from natural language
- schedule reminder
- mark complete

Demo flow 2:

- scan screenshot
- extract text
- summarize
- convert to tasks

Demo flow 3:

- ask about a stored memory
- retrieve it
- answer with context

Demo flow 4:

- compound request requiring planner and tools

This final stage depends on everything else. It is how you present the project, not how you build it.

## Strict dependency chain

The order you should follow is:

1. domain models
2. Flutter shell
3. local storage
4. chat UI
5. deterministic intent parsing
6. task engine
7. reminders and notifications
8. memory system
9. Firebase sync
10. Gemini integration
11. planner/tool execution
12. OCR ingestion
13. summarization workflows
14. memory-aware chat
15. multi-step agent flows
16. offline fallback
17. security/privacy
18. metrics/observability
19. UX polish
20. demo scripts

That order minimizes rewrites.

If you reverse it, you will create avoidable rework:

- Gemini before models causes messy responses with nowhere to go
- OCR before tasks causes extracted text with no action path
- Firebase before local storage creates sync complexity too early
- agent flows before deterministic parsing makes debugging nearly impossible

Use this as your build order.
