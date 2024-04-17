import lustre
import sketch/error as sketch

pub type Error {
  SketchError(sketch.SketchError)
  LustreError(lustre.Error)
}
