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

import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import lustre.{type Action, type App}
import lustre/attribute as a
import lustre/effect
import lustre/event
import sketch
import sketch/lustre as sl
import sketch/lustre/element as el
import sketch/lustre/element/html as h
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

/// Creates the tardis. Should be run once, at the start of the application.
/// It can be skipped when using [`single`](#single).
pub fn setup() {
  let #(shadow_root, lustre_root) = setup.mount_shadow_node()
  sketch.cache(strategy: sketch.Ephemeral)
  |> result.map(sl.compose(sl.shadow(shadow_root), view, _))
  |> result.map(lustre.application(init, update, _))
  |> result.try(start_lustre(lustre_root, _))
  |> result.map(fn(dispatch) { Tardis(dispatch) })
}

/// Directly creates a tardis instance for a single application.
/// Replaces `setup` and `application` in a single application context.
pub fn single(name: String) {
  result.map(setup(), application(_, name))
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
  let color_scheme = colors.choose_color_scheme()
  Model(
    debuggers: [],
    frozen: False,
    opened: False,
    color_scheme:,
    selected_debugger: option.None,
  )
  |> pair.new(effect.none())
}

fn update(model: Model, msg: Msg) {
  case msg {
    msg.LustreAddedApplication(debugger_, dispatcher) -> {
      model.debuggers
      |> debugger_.replace(debugger_, debugger_.add_dispatcher(_, dispatcher))
      |> model.set_debuggers(model, _)
      |> pair.new(effect.none())
    }

    msg.LustreRanStep(debugger_, m, m_) -> {
      model.debuggers
      |> debugger_.replace(debugger_, debugger_.add_step(_, m, m_))
      |> model.set_debuggers(model, _)
      |> model.optional_set_selected_debugger(debugger_)
      |> pair.new(effect.none())
    }

    msg.TardisPrintDebug(message:) -> {
      io.debug(message)
      #(model, effect.none())
    }

    msg.UserChangedColorScheme(cs) -> {
      Model(..model, color_scheme: cs)
      |> pair.new(colors.save_color_scheme(cs))
    }

    msg.UserClickedStep(debugger_, item) -> {
      model.debuggers
      |> debugger_.replace(debugger_, debugger_.select(_, Some(item.index)))
      |> model.set_debuggers(model, _)
      |> model.freeze
      |> pair.new({
        let debugger_ = debugger_.get(model.debuggers, debugger_)
        use debugger_ <- result.try(debugger_)
        debugger_.dispatcher
        |> option.map(fn(dispatcher) { dispatcher(item.model) })
        |> option.to_result(Nil)
      })
      |> pair.map_second(result.unwrap(_, effect.none()))
    }

    msg.UserResumedApplication(debugger_) -> {
      model.debuggers
      |> debugger_.replace(debugger_, debugger_.unselect)
      |> model.set_debuggers(model, _)
      |> model.unfreeze
      |> pair.new({
        effect.batch({
          use #(_name, debugger_) <- list.filter_map(model.debuggers)
          use step <- result.try(list.first(debugger_.steps))
          debugger_.dispatcher
          |> option.map(fn(dispatcher) { dispatcher(step.model) })
          |> option.to_result(Nil)
        })
      })
    }

    msg.UserSelectedDebugger(debugger_) -> {
      model.set_selected_debugger(model, debugger_)
      |> pair.new(effect.none())
    }

    msg.UserToggledPanel -> {
      Model(..model, opened: !model.opened)
      |> pair.new(effect.none())
    }
  }
}

fn view(model: Model) {
  let #(panel, header) = select_panel_options(model.opened)
  let debugger_ = model.get_selected_debugger(model)
  panel_wrapper(model, [], [
    panel([], [
      header([], [
        s.title([], [
          h.div_([], [h.text("Debugger")]),
          view_color_scheme_selector(model),
          view_restart_button(model),
        ]),
        view_debugger_actions(model, debugger_),
      ]),
      debugger_
        |> result.map(view_debugger_body(model, _))
        |> result.lazy_unwrap(el.none),
    ]),
  ])
}

fn select_panel_options(panel_opened: Bool) {
  case panel_opened {
    True -> #(s.panel, s.bordered_header)
    False -> #(s.panel_closed, s.header)
  }
}

fn panel_wrapper(model: Model, attrs, children) {
  let color_scheme_class = colors.get_color_scheme_class(model.color_scheme)
  let frozen_panel = select_frozen_panel(model)
  let classes = [color_scheme_class, frozen_panel]
  let panel_class = sketch.class(list.map(classes, sketch.compose))
  h.div(panel_class, [a.class("debugger_"), ..attrs], children)
}

fn select_frozen_panel(model: Model) {
  case model.frozen {
    True -> s.frozen_panel()
    False -> sketch.class([])
  }
}

fn view_color_scheme_selector(model: Model) {
  use <- bool.lazy_guard(when: !model.opened, return: el.none)
  s.select_cs([event.on_input(on_cs_input)], {
    use item <- list.map(colors.themes())
    let as_s = colors.cs_to_string(item)
    let selected = model.color_scheme == item
    h.option_([a.value(as_s), a.selected(selected)], [h.text(as_s)])
  })
}

fn on_cs_input(content) {
  let cs = colors.cs_from_string(content)
  msg.UserChangedColorScheme(cs)
}

fn view_restart_button(model: Model) {
  use <- bool.lazy_guard(when: !model.frozen, return: el.none)
  case model.selected_debugger {
    None -> el.none()
    Some(debugger_) ->
      s.button([event.on_click(msg.UserResumedApplication(debugger_))], [
        h.text("Restart"),
      ])
  }
}

fn view_debugger_actions(model, debugger_) {
  case debugger_ {
    Error(_) -> el.none()
    Ok(debugger_) -> {
      s.actions_section([], [
        view_debugger_selection(model),
        view_debugger_step_counter(debugger_),
        view_debugger_toggle_panel_button(model),
      ])
    }
  }
}

fn view_debugger_selection(model: Model) {
  s.select_cs([event.on_input(msg.UserSelectedDebugger)], {
    use #(item, _) <- list.map(model.keep_active_debuggers(model))
    let selected = model.selected_debugger == Some(item)
    h.option_([a.value(item), a.selected(selected)], [h.text(item)])
  })
}

fn view_debugger_step_counter(debugger_: debugger_.Debugger) {
  let count = int.to_string(debugger_.count - 1)
  h.div_([], [h.text(count <> " Steps")])
}

fn view_debugger_toggle_panel_button(model: Model) {
  s.toggle_button([event.on_click(msg.UserToggledPanel)], [
    h.text(case model.opened {
      True -> "Close"
      False -> "Open"
    }),
  ])
}

fn view_debugger_body(model: Model, debugger_: debugger_.Debugger) {
  case model.selected_debugger {
    Some(name) -> v.view_model(model.opened, name, debugger_)
    None -> el.none()
  }
}
