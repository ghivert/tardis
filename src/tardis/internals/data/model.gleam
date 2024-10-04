import gleam/list
import gleam/option.{type Option, Some}
import gleam/pair
import tardis/internals/data/colors
import tardis/internals/data/debugger.{type Debugger} as debugger_

pub type Debuggers =
  List(#(String, Debugger))

pub type Model {
  Model(
    debuggers: Debuggers,
    color_scheme: colors.ColorScheme,
    frozen: Bool,
    opened: Bool,
    selected_debugger: Option(String),
  )
}

pub fn optional_set_selected_debugger(model: Model, debugger_: String) {
  let selected = option.or(model.selected_debugger, Some(debugger_))
  Model(..model, selected_debugger: selected)
}

pub fn keep_active_debuggers(model: Model) {
  use debugger_ <- list.filter(model.debuggers)
  let steps = pair.second(debugger_).steps
  !list.is_empty(steps)
}

pub fn set_debuggers(model: Model, debuggers: Debuggers) {
  Model(..model, debuggers:)
}

pub fn freeze(model: Model) {
  Model(..model, frozen: True)
}

pub fn unfreeze(model: Model) {
  Model(..model, frozen: False)
}

pub fn get_selected_debugger(model: Model) {
  model.selected_debugger
  |> option.unwrap("")
  |> debugger_.get(model.debuggers, _)
}

pub fn set_selected_debugger(model: Model, debugger_) {
  Model(..model, selected_debugger: Some(debugger_))
}
