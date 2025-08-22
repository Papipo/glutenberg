import gleam/bool
import gleam/list
import gleam/option.{type Option, None, Some}
import glutenberg/database.{type Database}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/event

pub type Model {
  Model(
    database: Database,
    query: String,
    results: List(String),
    mode: Mode,
    case_insensitive: Bool,
    error: Option(String),
  )
}

pub type Msg {
  Search(query: String)
  SelectMode(mode: String)
  CaseInsensitiveClicked(String)

  SetResults(results: List(String))
  SetError(e: String)
}

pub opaque type Mode {
  RegEx
  Fuzzy
}

pub fn app() {
  lustre.application(init, update, view)
}

fn init(database: Database) {
  #(
    Model(
      database,
      query: "",
      results: [],
      mode: RegEx,
      case_insensitive: False,
      error: None,
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let model = Model(..model, error: None)
  case msg {
    Search(query) -> {
      let model = Model(..model, query: query)
      case model.mode {
        Fuzzy -> #(model, fuzzy(model))
        RegEx -> #(model, regex(model))
      }
    }
    SelectMode(mode) -> {
      let mode = mode_from_string(mode)
      #(Model(..model, mode: mode, results: []), effect.none())
    }
    CaseInsensitiveClicked(_) -> {
      let model =
        Model(..model, case_insensitive: model.case_insensitive |> bool.negate)
      #(model, regex(model))
    }

    SetResults(results) -> #(Model(..model, results: results), effect.none())
    SetError(e) -> #(Model(..model, error: Some(e)), effect.none())
  }
}

fn view(model: Model) {
  html.div(
    [attribute.class("h-screen m-10 flex justify-center font-teal-800 text-xl")],
    [
      html.div(
        [attribute.class("flex flex-col justify-start items-center gap-2")],
        [
          html.select(
            [
              attribute.class(
                "flex-none w-auto bg-white border border-teal-500 w-full p-3 rounded",
              ),
              event.on_input(SelectMode),
            ],
            [RegEx, Fuzzy]
              |> list.map(fn(mode) {
                html.option(
                  [attribute.selected(model.mode == mode)],
                  mode |> mode_to_string,
                )
              }),
          ),
          case_selector(model),
          html.input([
            attribute.class(
              "flex-none border border-teal-500 w-full p-3 rounded",
            ),
            attribute.classes([
              #(
                "ring-offset-1 ring-4 ring-rose-800",
                model.error |> option.is_some,
              ),
            ]),
            attribute.placeholder("Search..."),
            attribute.type_("text"),
            event.on_input(Search),
          ]),
          results(model.results),
        ],
      ),
    ],
  )
}

fn results(items: List(String)) {
  case items {
    [] -> element.none()
    _ ->
      html.div(
        [attribute.class("border shadow flex-col gap-1 py-2 w-full bg-white")],
        list.map(items, result),
      )
  }
}

fn result(item: String) {
  html.div([attribute.class("p-2")], [html.text(item)])
}

fn case_selector(model: Model) {
  case model.mode {
    Fuzzy -> element.none()
    RegEx ->
      html.div([attribute.class("w-full flex flext-start gap-2")], [
        html.input([
          attribute.type_("checkbox"),
          attribute.checked(model.case_insensitive),
          event.on_input(CaseInsensitiveClicked),
        ]),
        html.text("Case insensitive"),
      ])
  }
}

fn regex(model: Model) -> Effect(Msg) {
  use dispatch <- effect.from()
  case
    model.database
    |> database.regexp(model.query, model.case_insensitive)
  {
    Error(e) -> e |> SetError |> dispatch
    Ok(results) -> results |> SetResults |> dispatch
  }
}

fn fuzzy(model: Model) -> Effect(Msg) {
  use dispatch <- effect.from()
  model.database
  |> database.fuzzy(model.query)
  |> SetResults
  |> dispatch
}

fn mode_from_string(mode: String) -> Mode {
  case mode {
    "RegEx" -> RegEx
    "Fuzzy" -> Fuzzy
    _ -> RegEx
  }
}

fn mode_to_string(mode: Mode) {
  case mode {
    Fuzzy -> "Fuzzy"
    RegEx -> "RegEx"
  }
}
