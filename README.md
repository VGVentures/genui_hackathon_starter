# genui_template

A starter Flutter app for building **Generative UI** (GenUI) experiences. Instead of the model replying with plain text, it replies with a _user interface_: buttons, lists, cards, forms, and more, rendered live as real Flutter widgets.

This template wires up Google's Gemini model to Flutter's [`genui`](https://pub.dev/packages/genui) package so you can start shaping that experience right away. You bring two things: a **catalog** of widgets the model is allowed to use, and a **system prompt** that tells it how to behave. The template handles everything in between.

New to GenUI? That's fine. This README walks you through it from scratch, including installing Flutter.

---

## What is GenUI, in one minute

A normal chat app sends your message to a model and gets text back. GenUI sends your message to a model and gets back a structured description of a UI (in a format called **A2UI**, "agent-to-UI"). The `genui` package turns that description into live Flutter widgets on screen.

The model can only ever describe widgets you've told it about. That list of allowed widgets is the **catalog**. Because the same catalog is fed to the model _and_ used to render, the model can never ask for something your app can't draw.

So the two knobs you'll touch most are:

- **`lib/catalog.dart`** — _what_ the model can build (the widget vocabulary).
- **`lib/prompt.dart`** — _how_ the model should behave (persona, tone, rules).

Everything else in this template is plumbing that connects those two things to Gemini and to the screen.

---

## Getting started

This section assumes you have **never installed Flutter**. We'll run the app on **macOS** as a native desktop app. (You're on a Mac, so this is the quickest path. No simulators or devices needed.)

### 1. Install Flutter

The easiest way on macOS is via the official installer.

1. Install [Xcode](https://apps.apple.com/us/app/xcode/id497799835) from the App Store (required to build macOS apps). After it installs, open it once so it can finish setting up, then run:
   ```sh
   sudo xcodebuild -runFirstLaunch
   ```
2. Install Flutter. If you have [Homebrew](https://brew.sh):
   ```sh
   brew install --cask flutter
   ```
   Otherwise, follow the manual steps at [docs.flutter.dev/get-started/install/macos](https://docs.flutter.dev/get-started/install/macos).
3. Confirm everything is healthy. This checks your toolchain and tells you if anything is missing:
   ```sh
   flutter doctor
   ```
   You want green checkmarks for **Flutter** and **Xcode** at minimum. Don't worry if Android/Chrome show warnings; you don't need them for macOS.

This project targets the Flutter SDK that ships **Dart `^3.12.1`** (see [pubspec.yaml](pubspec.yaml)). If `flutter doctor` reports an older Dart, run `flutter upgrade`.

### 2. Get a Gemini API key

The app talks to Google's Gemini model, which needs an API key.

1. Go to [Google AI Studio](https://aistudio.google.com/apikey).
2. Sign in and click **Create API key**.
3. Copy the key somewhere safe. You'll paste it in the next step.

The key is **not** stored in the project. You pass it in at run time, so it never ends up in source control.

### 3. Install the project's dependencies

From the project root:

```sh
flutter pub get
```

### 4. Run the app on macOS

Enable macOS desktop support once (harmless if already enabled):

```sh
flutter config --enable-macos-desktop
```

Then run, passing your Gemini key in via `--dart-define`:

```sh
flutter run -d macos --dart-define=GEMINI_API_KEY=your_key_here
```

Replace `your_key_here` with the key from step 2. The first build takes a minute or two; later runs are faster.

> **Why `--dart-define`?** It injects the key as a compile-time constant the app reads via `String.fromEnvironment('GEMINI_API_KEY')` (see [lib/agent/gemini_agent.dart](lib/agent/gemini_agent.dart)). This keeps your secret out of the codebase. If you forget the flag, the app builds but Gemini calls fail with an auth error.

Once it's running, type a request into the box at the bottom, for example _"give me a button that says hello and a list of three fruits."_ The left side shows the rendered UI; the right side shows the raw A2UI JSON the model produced, so you can see exactly what it asked for.

> **Tip:** Tired of typing the long command? Most editors let you save it. In VS Code, add a `launch.json` config with `"args": ["--dart-define=GEMINI_API_KEY=your_key_here"]`.

---

## How the project is laid out

Here's every meaningful file in [lib/](lib/) and what it's for. The files you'll edit most are at the top.

### The files you'll probably customize

| File                                   | What it's for                                                                                                                                                                                                                                                                                                                                        |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`lib/catalog.dart`](lib/catalog.dart) | **Defines the widgets the model knows how to use.** This is your GenUI vocabulary. It ships with `BasicCatalogItems` (a ready-made set of common widgets). Add your own components here to expand what the model can build. The catalog feeds both the renderer and the system prompt, so the model can only ever request widgets you've registered. |
| [`lib/prompt.dart`](lib/prompt.dart)   | **Defines the overall interaction.** A plain system-prompt string: the assistant's persona, tone, and any domain rules. You focus on _what_ the assistant should do; the framework already teaches the model _how_ to emit valid A2UI, so you don't have to.                                                                                         |

Start here. You can build a surprising amount just by editing these two.

### The GenUI plumbing (you might edit this)

| File                                                         | What it's for                                                                                                                                                                                                                                                                                           |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`lib/model/model_client.dart`](lib/model/model_client.dart)               | A model-agnostic `ModelClient` interface. It owns the conversation history and exposes the latest model response. Swap in a different model by writing a new subclass; nothing else has to change.                                                                                                            |
| [`lib/model/gemini_model_client.dart`](lib/model/gemini_model_client.dart) | The Gemini implementation of `ModelClient`. Owns the Gemini client, builds the A2UI system prompt from your catalog, layers your `prompt.dart` on top, and streams the model's response. This is where the API key and model name live.                                                                       |
| [`lib/conversation.dart`](lib/conversation.dart)             | `GenUiSession`: the heart of the pipeline. It ties together the GenUI `SurfaceController` (which renders), the transport (which carries A2UI chunks), the `Conversation` (which tracks state), and the `ModelClient`. It builds and disposes all four as a single unit so the UI doesn't have to juggle them. |

### The screen and widgets (feel free to replace all this)

| File                                                                     | What it's for                                                                                                                                                                  |
| ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [`lib/home_page.dart`](lib/home_page.dart)                               | The main screen. Creates the catalog and session, shows the rendered surface on the left and the raw A2UI source on the right, and feeds your typed messages into the session. |
| [`lib/app.dart`](lib/app.dart)                                           | The root `MaterialApp`. Theming and top-level app config go here.                                                                                                              |
| [`lib/bootstrap.dart`](lib/bootstrap.dart)                               | The `main()` entry point that boots the app.                                                                                                                                   |
| [`lib/widgets/message_input.dart`](lib/widgets/message_input.dart)       | The text box and send button at the bottom of the screen.                                                                                                                      |
| [`lib/widgets/a2ui_source_view.dart`](lib/widgets/a2ui_source_view.dart) | The right-hand panel that shows the raw A2UI JSON as it streams in. Handy for learning and debugging.                                                                          |
| [`lib/widgets/widgets.dart`](lib/widgets/widgets.dart)                   | A barrel file that re-exports the widgets above for tidy imports.                                                                                                              |

---

## Where to go next

- **Teach the model new tricks.** Add a custom component to [`lib/catalog.dart`](lib/catalog.dart). Once it's in the catalog, the model can use it.
- **Change the personality.** Rewrite the string in [`lib/prompt.dart`](lib/prompt.dart) to give the assistant a focus, a tone, or domain rules.
- **Try a different model.** Change `_defaultModel` in [`lib/model/gemini_model_client.dart`](lib/model/gemini_model_client.dart), or write a new `ModelClient` subclass for a different provider.
- **Learn the framework.** See the [`genui` package on pub.dev](https://pub.dev/packages/genui) for the full catalog API and A2UI format.

Happy building.
