//// Tardis is in charge of being your good debugger friend, able to navigate
//// accross time and space! Just instanciate it, and use it in your application.
////
//// ```gleam
//// import gleam/int
//// import lustre
//// import lustre/element/html
//// import lustre/event
//// import tardis
////
//// pub fn main() {
////   let assert Ok(main) = tardis.single("main")
////
////   lustre.application(init, update, view)
////   |> tardis.wrap(with: main)
////   |> lustre.start("#app", Nil)
////   |> tardis.activate(with: main)
//// }
////
//// fn init(_) {
////   0
//// }
////
//// fn update(model, msg) {
////   case msg {
////     Incr -> model + 1
////     Decr -> model - 1
////   }
//// }
////
//// fn view(model) {
////   let count = int.to_string(model)
////   html.div([], [
////     html.button([event.on_click(Incr)], [html.text(" + ")]),
////     html.p([], [html.text(count)]),
////     html.button([event.on_click(Decr)], [html.text(" - ")])
////   ])
//// }
//// ```

import gleam/dynamic.{type Dynamic}
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/pair
import gleam/result
import lustre.{type Action, type App}
import lustre/attribute as a
import lustre/effect
import lustre/element as el
import lustre/element/html as h
import lustre/event
import sketch/lustre as sketch
import sketch/options as sketch_options
import tardis/error
import tardis/internals/data/colors
import tardis/internals/data/debugger as debugger_
import tardis/internals/data/model.{type Model, Model}
import tardis/internals/data/msg.{type Msg}
import tardis/internals/setup.{type Middleware}
import tardis/internals/styles as s
import tardis/internals/view as v

/// Represents the running Tardis. Should be used with lustre applications
/// only. One tardis is enough for multiple lustre applications running on the
/// same page, with their own update loop.
pub opaque type Tardis {
  Tardis(dispatch: fn(Action(Msg, lustre.ClientSpa)) -> Nil)
}

/// Represents the instance for an application. It should be used within one and
/// only one application. You can get the instance by using [`application`](#application)
/// or [`single`](#single).
pub opaque type Instance {
  Instance(#(fn(Dynamic) -> Nil, Middleware))
}

/// Wrap a lustre application with the debugger. The debugger will never interfere
/// with your application by itself. You can directly chain your application with
/// this function.
/// ```gleam
/// fn main() {
///   let assert Ok(instance) = tardis.single("main")
///   lustre.application(init, update, view)
///   |> tardis.wrap(with: instance)
/// }
/// ```
pub fn wrap(application: App(a, b, c), with instance: Instance) {
  let Instance(#(_, middleware)) = instance
  setup.update_lustre(
    application,
    setup.wrap_init(middleware),
    setup.wrap_update(middleware),
  )
}

/// Activate the debugger of the application. `activate` should be run to let
/// the debugger being able to rewind time. It should be executed on the exact
/// same instance that has been wrapped.
/// ```gleam
/// fn main() {
///   let assert Ok(instance) = tardis.single("main")
///   lustre.application(init, update, view)
///   |> tardis.wrap(with: instance)
///   |> lustre.start()
///   |> tardis.activate(with: instance)
/// }
/// ```
pub fn activate(
  result: Result(fn(Action(a, b)) -> Nil, c),
  with instance: Instance,
) {
  use dispatch <- result.map(result)
  let Instance(#(dispatcher, _)) = instance
  dispatcher(dynamic.from(dispatch))
  dispatch
}

fn start_lustre(lustre_root, application) {
  application
  |> lustre.start(lustre_root, Nil)
  |> result.map_error(error.LustreError)
}

fn start_sketch(root) {
  // Attach the StyleSheet to the Shadow DOM.
  let setup = sketch.setup(sketch_options.shadow(root))
  use error <- result.map_error(setup)
  io.debug("Unable to start sketch. Check your configuration.")
  io.debug(error)
  error.SketchError(error)
}

/// Creates the tardis. Should be run once, at the start of the application.
/// It can be skipped when using [`single`](#single).
pub fn setup() {
  let #(shadow_root, lustre_root) = setup.mount_shadow_node()
  start_sketch(shadow_root)
  |> result.map(sketch.compose(view, _))
  |> result.map(lustre.application(init, update, _))
  |> result.try(start_lustre(lustre_root, _))
  |> result.map(fn(dispatch) { Tardis(dispatch) })
}

/// Directly creates a tardis instance for a single application.
/// Replaces `setup` and `application` in a single application context.
pub fn single(name: String) {
  setup()
  |> result.map(application(_, name))
}

/// Creates the application debugger from the tardis. Should be run once,
/// at the start of the application. It can be skipped when using [`single`](#single).
pub fn application(instance: Tardis, name: String) -> Instance {
  let dispatch = instance.dispatch
  let updater = setup.create_model_updater(dispatch, name)
  let adder = setup.step_adder(dispatch, name)
  Instance(#(updater, adder))
}

fn init(_) {
  colors.choose_color_scheme()
  |> Model(
    debuggers: [],
    frozen: False,
    opened: False,
    color_scheme: _,
    selected_debugger: option.None,
  )
  |> pair.new(effect.none())
}

fn update(model: Model, msg: Msg) {
  case msg {
    msg.ToggleOpen -> #(Model(..model, opened: !model.opened), effect.none())

    msg.Restart(debugger_) -> {
      let restart_effect =
        model.debuggers
        |> list.filter_map(fn(d_) {
          let d = pair.second(d_)
          let fst_step = list.first(d.steps)
          use step <- result.try(fst_step)
          d.dispatcher
          |> option.map(function.apply1(_, step.model))
          |> option.to_result(Nil)
        })
        |> effect.batch()

      model.debuggers
      |> debugger_.replace(debugger_, debugger_.unselect)
      |> fn(ds) { Model(..model, frozen: False, debuggers: ds) }
      |> pair.new(restart_effect)
    }

    msg.UpdateColorScheme(cs) ->
      Model(..model, color_scheme: cs)
      |> pair.new(colors.save_color_scheme(cs))

    msg.AddApplication(debugger_, dispatcher) ->
      model.debuggers
      |> debugger_.replace(debugger_, debugger_.add_dispatcher(_, dispatcher))
      |> fn(d) { Model(..model, debuggers: d) }
      |> pair.new(effect.none())

    msg.BackToStep(debugger_, item) -> {
      let selected_step = option.Some(item.index)
      let model_effect =
        model.debuggers
        |> debugger_.get(debugger_)
        |> result.try(fn(d) {
          d.dispatcher
          |> option.map(function.apply1(_, item.model))
          |> option.to_result(Nil)
        })
        |> result.unwrap(effect.none())

      model.debuggers
      |> debugger_.replace(debugger_, debugger_.select(_, selected_step))
      |> fn(d) { Model(..model, frozen: True, debuggers: d) }
      |> pair.new(model_effect)
    }

    msg.Debug(value) -> {
      io.debug(value)
      #(model, effect.none())
    }

    msg.SelectDebugger(debugger_) ->
      Model(..model, selected_debugger: option.Some(debugger_))
      |> pair.new(effect.none())

    msg.AddStep(debugger_, m, m_) -> {
      model.debuggers
      |> debugger_.replace(debugger_, debugger_.add_step(_, m, m_))
      |> fn(d) { Model(..model, debuggers: d) }
      |> model.optional_set_debugger(debugger_)
      |> pair.new(effect.none())
    }
  }
}

fn select_panel_options(panel_opened: Bool) {
  case panel_opened {
    True -> #(s.panel(), s.bordered_header(), "Close")
    False -> #(s.panel_closed(), s.header(), "Open")
  }
}

fn on_cs_input(content) {
  let cs = colors.cs_from_string(content)
  msg.UpdateColorScheme(cs)
}

fn on_debugger_input(content) {
  msg.SelectDebugger(content)
}

fn color_scheme_selector(model: Model) {
  case model.opened {
    False -> el.none()
    True ->
      h.select([event.on_input(on_cs_input), s.select_cs()], {
        use item <- list.map(colors.themes())
        let as_s = colors.cs_to_string(item)
        let selected = model.color_scheme == item
        h.option([a.value(as_s), a.selected(selected)], as_s)
      })
  }
}

fn restart_button(model: Model) {
  case model.frozen, model.selected_debugger {
    True, Some(debugger_) ->
      h.button([s.select_cs(), event.on_click(msg.Restart(debugger_))], [
        h.text("Restart"),
      ])
    _, _ -> el.none()
  }
}

fn view(model: Model) {
  let color_scheme_class = colors.get_color_scheme_class(model.color_scheme)
  let #(panel, header, button_txt) = select_panel_options(model.opened)
  let frozen_panel = case model.frozen {
    True -> s.frozen_panel()
    False -> a.none()
  }
  let debugger_ =
    model.selected_debugger
    |> option.unwrap("")
    |> debugger_.get(model.debuggers, _)
  h.div([a.class("debugger_"), color_scheme_class, frozen_panel], [
    h.div([panel], [
      h.div([header], [
        h.div([s.flex(), s.debugger_title()], [
          h.div([], [h.text("Debugger")]),
          color_scheme_selector(model),
          restart_button(model),
        ]),
        case debugger_ {
          Error(_) -> el.none()
          Ok(debugger_) ->
            h.div([s.actions_section()], [
              h.select([event.on_input(on_debugger_input), s.select_cs()], {
                use #(item, _) <- list.map(model.keep_active_debuggers(model))
                let selected = model.selected_debugger == Some(item)
                h.option([a.value(item), a.selected(selected)], item)
              }),
              h.div([], [h.text(int.to_string(debugger_.count - 1) <> " Steps")]),
              h.button([s.toggle_button(), event.on_click(msg.ToggleOpen)], [
                h.text(button_txt),
              ]),
            ])
        },
      ]),
      case debugger_, model.selected_debugger {
        Ok(debugger_), Some(d) -> v.view_model(model.opened, d, debugger_)
        _, _ -> el.none()
      },
    ]),
  ])
}
