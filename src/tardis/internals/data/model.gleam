import gleam/list
import gleam/option.{type Option, Some}
import gleam/pair
import tardis/internals/data/colors
import tardis/internals/data/debugger.{type Debugger}

pub type Model {
  Model(
    debuggers: List(#(String, Debugger)),
    color_scheme: colors.ColorScheme,
    frozen: Bool,
    opened: Bool,
    selected_debugger: Option(String),
  )
}

pub fn optional_set_debugger(model: Model, debugger_: String) {
  let selected = option.or(model.selected_debugger, Some(debugger_))
  Model(..model, selected_debugger: selected)
}

pub fn keep_active_debuggers(model: Model) {
  use debugger_ <- list.filter(model.debuggers)
  let steps = pair.second(debugger_).steps
  !list.is_empty(steps)
}
