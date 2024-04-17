# Tardis

<!-- [![Package Version](https://img.shields.io/hexpm/v/tardis)](https://hex.pm/packages/tardis)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/tardis/) -->

Every good frontend framework deserve to have a good debugger. Tardis tries to fill
this gap with [Lustre](https://hexdocs.pm/lustre). Because of the immutable nature and the management of side-effects of lustre, it's possible to implement a debugger able to register everything that happened in the app and that can rewind the time in order to display the state of your app, at any point in time! Tardis is a time-traveller debugger, made to interact with multiple lustre applications and components on one page, with the simplest setup possible yet!

## Demo

https://github.com/ghivert/tardis/assets/7314118/748ed6bd-b593-47c8-bde9-647c67e0e25e

## Quickstart Guide

First, add tardis to your gleam project.

```sh
gleam add tardis
```

Then, setup the package.

```gleam
import gleam/int
import lustre
import lustre/element/html
import lustre/event
import tardis

pub fn main() {
  let assert Ok(main) = tardis.single("main")

  lustre.application(init, update, view)
  |> tardis.wrap(with: main)
  |> lustre.start("#app", Nil)
  |> tardis.activate(with: main)
}

fn init(_) {
  0
}

fn update(model, msg) {
  case msg {
    Incr -> model + 1
    Decr -> model - 1
  }
}

fn view(model) {
  let count = int.to_string(model)
  html.div([], [
    html.button([event.on_click(Incr)], [html.text(" + ")]),
    html.p([], [html.text(count)]),
    html.button([event.on_click(Decr)], [html.text(" - ")])
  ])
}
```

You're good to go!

## Multiple apps setup

While it's easy to setup a single application with tardis, it can also be used to debug multiple applications in the same page. Tardis exposes two additional functions: [`setup`](https://hexdocs.pm/tardis/tardis.html#setup) and [`application`](https://hexdocs.pm/tardis/tardis.html#application). The first one initialize the debugger, while the second one allows to setup an application on the debugger!

In case you're developping a independant package, you can even send the tardis or the debugger instance directly to your application, and it will nicely integrate in it!

```gleam
import gleam/int
import lustre
import lustre/element/html
import lustre/event
import tardis

pub fn main() {
  let assert Ok(instance) = tardis.setup()
  let main = tardis.application(instance, "main")
  let mod = tardis.application(instance, "module")

  lustre.application(init_1, update_1, view_1)
  |> tardis.wrap(with: main)
  |> lustre.start("#app", Nil)
  |> tardis.activate(with: main)

  lustre.application(init_2, update_2, view_2)
  |> tardis.wrap(with: mod)
  |> lustre.start("#mod", Nil)
  |> tardis.activate(with: mod)
}
```

## Style collision

No worry about the debugger going into your application! Tardis uses the Shadow DOM, meaning no style nor behavior will leak out of the debugger and ending in your application. Tardis will just come on top, watch the application, and can rollback in time. Nothing more!
