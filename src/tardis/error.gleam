//// Manages error for Tardis.
//// Used only during initialization, to identify what is failing.

import lustre
import sketch/error as sketch

pub type Error {
  SketchError(sketch.SketchError)
  LustreError(lustre.Error)
}
