import gleam/dynamic.{type Dynamic}
import lustre/effect.{type Effect}
import tardis/internals/data/colors.{type ColorScheme}
import tardis/internals/data/step.{type Step}

pub type Msg {
  LustreAddedApplication(name: String, dispatcher: fn(Dynamic) -> Effect(Msg))
  LustreRanStep(name: String, model: Dynamic, msg: Dynamic)
  TardisPrintDebug(message: String)
  UserChangedColorScheme(color_scheme: ColorScheme)
  UserClickedStep(name: String, step: Step)
  UserResumedApplication(name: String)
  UserSelectedDebugger(debugger: String)
  UserToggledPanel
}
