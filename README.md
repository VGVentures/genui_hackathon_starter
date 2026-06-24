# GenUI Hackathon Starter 🦄

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A starter Flutter app for building **Generative UI** (GenUI) experiences. Instead of the model replying with plain text, it replies with a _user interface_: buttons, lists, cards, forms, and more, rendered live as real Flutter widgets.

This template wires up Google's Gemini model to Flutter's [`genui`](https://pub.dev/packages/genui) package so you can start shaping that experience right away.

**You bring _two_ things** — the Template handles everything in between:
> 1. a **catalog** — the list of widgets the model is allowed to use.
> 2. a **system prompt** — describing each widget's behavior to the model.
>
> 📝 Due to the **catalog** is shared between the Renderer and the Model, your App can never be asked to draw a Widget it doesn't know about.

The Template is the plumbing between your two inputs, Gemini, and the screen:
> The two knobs you'll touch most are:
> 1. **`lib/catalog.dart`** — _what_ the model can build (the widget vocabulary).
> 2. **`lib/prompt.dart`** — _how_ the model should behave (persona, tone, rules).

---

## What is GenUI, in one minute

While both the typical chat experience and GenUI share the same Request flow: send a message, await a response, GenUI diverges in its Response output; this _structure_ is known as **A2UI** ("agent-to-UI"): composing the Response as a _description_ of UI rather than plain text. When pairing that _description_ with the `genui` package we begin to see how this transformation of input returns applicable, live Flutter widgets on screen!

---

## Getting started
> New to **GenUI**? No worries, this guide starts from scratch, including Flutter installation!

This section assumes you have **never installed Flutter** -- macOS
> we'll run the app as a native macOS desktop app. No simulators nor devices needed!

### 1. Install Flutter

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

This project targets the Flutter SDK that ships **Dart `^3.12.1`** (see [pubspec.yaml](pubspec.yaml)).
> If `flutter doctor` reports an older Dart, run `flutter upgrade`.

### 2. Get a Gemini API key

> The app talks to Google's Gemini model, which needs an API key.

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

> Enable macOS desktop support once (harmless if already enabled):

```sh
flutter config --enable-macos-desktop
```

Then run, passing your Gemini key in via `--dart-define`:

```sh
flutter run -d macos --dart-define=GEMINI_API_KEY=your_key_here
```

Replace `your_key_here` with the key from step 2. The first build takes a minute or two; later runs are faster.

> **Why `--dart-define`?** It injects the key as a compile-time constant the app reads via `String.fromEnvironment('GEMINI_API_KEY')` (see [lib/model/gemini_model_client.dart](lib/model/gemini_model_client.dart)). This keeps your secret out of the codebase. If you forget the flag, the app builds but Gemini calls fail with an auth error.

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

| File                                                                       | What it's for                                                                                                                                                                                                                                                                                                 |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`lib/model/model_client.dart`](lib/model/model_client.dart)               | A model-agnostic `ModelClient` interface. It owns the conversation history and exposes the latest model response. Swap in a different model by writing a new subclass; nothing else has to change.                                                                                                            |
| [`lib/model/gemini_model_client.dart`](lib/model/gemini_model_client.dart) | The Gemini implementation of `ModelClient`. Owns the Gemini client, builds the A2UI system prompt from your catalog, layers your `prompt.dart` on top, and streams the model's response. This is where the API key and model name live.                                                                       |
| [`lib/conversation.dart`](lib/conversation.dart)                           | `GenUiSession`: the heart of the pipeline. It ties together the GenUI `SurfaceController` (which renders), the transport (which carries A2UI chunks), the `Conversation` (which tracks state), and the `ModelClient`. It builds and disposes all four as a single unit so the UI doesn't have to juggle them. |

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

---

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_ventures_link]: https://verygood.ventures
