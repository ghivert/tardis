import sketch
import sketch/lustre/element/html as h
import sketch/size.{percent, px}

fn panel_() {
  sketch.class([
    sketch.z_index(1_000_001),
    sketch.display("flex"),
    sketch.flex_direction("column"),
    sketch.position("fixed"),
    sketch.bottom(px(12)),
    sketch.right(px(12)),
    sketch.background("var(--background)"),
    sketch.border_radius(px(10)),
    sketch.box_shadow("0px 0px 5px 1px var(--shadow)"),
    sketch.overflow("hidden"),
    sketch.border("2px solid var(--primary)"),
    sketch.color("var(--editor-fg)"),
    sketch.width(px(1000)),
    sketch.max_width_("calc(100vw - 24px)"),
    sketch.max_height_("min(1200px, calc(100vh - 24px))"),
  ])
}

pub fn panel(attrs, children) {
  panel_()
  |> h.div(attrs, children)
}

pub fn panel_closed(attrs, children) {
  sketch.class([
    sketch.compose(panel_()),
    sketch.width(px(400)),
    // sketch.min_height(px(60)),
    sketch.justify_content("center"),
  ])
  |> h.div(attrs, children)
}

fn grid_header_() {
  sketch.class([
    sketch.display("grid"),
    sketch.grid_column("1 / 4"),
    sketch.grid_template_columns("subgrid"),
    sketch.position("sticky"),
    sketch.top(px(0)),
  ])
}

pub fn grid_header() {
  grid_header_()
}

pub fn bordered_grid_header() {
  sketch.class([
    sketch.compose(grid_header_()),
    sketch.border_bottom("2px solid var(--primary)"),
  ])
}

fn header_() {
  sketch.class([
    sketch.background("var(--background)"),
    sketch.padding(px(12)),
    sketch.display("flex"),
    sketch.align_items("center"),
    sketch.justify_content("space-between"),
    sketch.font_family("Lexend"),
  ])
}

pub fn header(attrs, children) {
  header_()
  |> h.div(attrs, children)
}

pub fn bordered_header(attrs, children) {
  sketch.class([sketch.compose(header_())])
  |> h.div(attrs, children)
}

pub fn body() {
  sketch.class([
    sketch.display("grid"),
    sketch.grid_template_columns("auto 2fr 3fr"),
    sketch.font_family("monospace"),
    sketch.overflow_y("auto"),
    sketch.width_("100%"),
    sketch.white_space("pre-wrap"),
    sketch.font_size(px(10)),
  ])
}

fn details_() {
  sketch.class([
    sketch.display("grid"),
    sketch.grid_column("1 / 4"),
    sketch.grid_template_columns("subgrid"),
    sketch.background("var(--editor-bg)"),
    sketch.font_size(px(14)),
    sketch.border_bottom("1px solid var(--gutter)"),
  ])
}

pub fn details() {
  details_()
}

pub fn selected_details() {
  sketch.class([sketch.compose(details_()), sketch.background("var(--shadow)")])
}

pub fn step_index() {
  sketch.class([
    sketch.padding_("9px 9px"),
    sketch.justify_self("end"),
    sketch.border_right("1px solid var(--gutter)"),
    sketch.font_family("Lexend"),
    sketch.color("var(--syntax-comment)"),
  ])
}

pub fn step_msg() {
  sketch.class([
    sketch.overflow("hidden"),
    sketch.word_break("break-all"),
    sketch.padding(px(9)),
    sketch.border_right("1px solid var(--gutter)"),
  ])
}

pub fn step_model() {
  sketch.class([
    sketch.overflow("hidden"),
    sketch.word_break("break-all"),
    sketch.padding(px(6)),
  ])
}

pub fn actions_section(attrs, children) {
  sketch.class([
    sketch.display("flex"),
    sketch.gap(px(12)),
    sketch.align_items("center"),
    sketch.white_space("nowrap"),
  ])
  |> h.div(attrs, children)
}

pub fn toggle_button(attrs, children) {
  sketch.class([
    sketch.appearance("none"),
    sketch.border("none"),
    sketch.background("none"),
    sketch.font_family("Lexend"),
    sketch.property("cursor", "pointer"),
    sketch.color("var(--button)"),
  ])
  |> h.button(attrs, children)
}

pub fn keyword_color() {
  [sketch.color("var(--bool)"), sketch.white_space("pre")]
  |> sketch.class()
}

pub fn flex() {
  [sketch.display("flex")]
  |> sketch.class()
}

pub fn title(attrs, children) {
  sketch.class([
    sketch.compose(flex()),
    sketch.align_items("center"),
    sketch.gap(px(18)),
  ])
  |> h.div(attrs, children)
}

pub fn text_color(color: String) {
  sketch.class([sketch.color(color)])
}

pub fn subgrid_header() {
  sketch.class([
    sketch.font_size(px(14)),
    sketch.font_family("Lexend"),
    sketch.background("var(--background)"),
    sketch.padding(px(9)),
  ])
}

pub fn button_base() {
  sketch.class([
    sketch.appearance("none"),
    sketch.background("transparent"),
    sketch.padding(px(6)),
    sketch.margin(px(0)),
    sketch.width(percent(100)),
    sketch.font_size(px(12)),
    sketch.font_family("inherit"),
    sketch.line_height("inherit"),
    sketch.color("var(--primary)"),
    sketch.border("1px solid var(--primary)"),
    sketch.border_radius(px(5)),
    sketch.outline("none"),
  ])
}

pub fn button(attrs, children) {
  button_base()
  |> h.button(attrs, children)
}

pub fn select_cs(attrs, children) {
  button_base()
  |> h.select(attrs, children)
}

pub fn frozen_panel() {
  sketch.class([
    sketch.position("fixed"),
    sketch.top(px(0)),
    sketch.bottom(px(0)),
    sketch.right(px(0)),
    sketch.left(px(0)),
    sketch.z_index(1_000_000),
    // sketch.background("rgba(255, 255, 255, 0.1)"),
  ])
}
