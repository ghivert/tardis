# Tardis

<!-- [![Package Version](https://img.shields.io/hexpm/v/tardis)](https://hex.pm/packages/tardis)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/tardis/) -->

Every good frontend framework should have a good debugger. Tardis tries to fill
this gap with [Lustre](https://hexdocs.pm/lustre). Because of the immutable nature and the management of side-effects of lustre, it's possible to implement a debugger able to register everything that happened in the app and that can rewind the time in order to display the state of your app, at any point in time! Tardis is a time-traveller debugger, made to interact with multiple lustre applications and components on one page, with the simplest setup possible yet!

## Demo

![Demo video](assets/demo.mp4)

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
  let main = tardis.single("main")

  lustre.application(init, update, view)
  |> tardis.wrap(main)
  |> lustre.start("#app", Nil)
  |> tardis.activate(main)
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
