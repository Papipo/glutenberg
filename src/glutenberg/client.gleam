import gleam/list
import gleam/regex
import glutenberg/database.{type Database}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/event

pub type Model {
  Model(database: Database, results: List(String), mode: Mode)
}

pub type Msg {
  Search(query: String)
  SelectMode(mode: String)

  SetResults(results: List(String))
}

pub opaque type Mode {
  RegEx
  Fuzzy
}

pub fn app() {
  lustre.application(init, update, view)
}

fn init(database: Database) {
  #(Model(database, [], mode: RegEx), effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Search(query) ->
      case model.mode {
        Fuzzy -> #(model, fuzzy(model, query))
        RegEx -> #(model, regex(model, query))
      }
    SelectMode(mode) -> {
      let mode = mode_from_string(mode)
      #(Model(..model, mode: mode, results: []), effect.none())
    }

    SetResults(results) -> #(Model(..model, results: results), effect.none())
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
          html.input([
            attribute.class(
              "flex-none border border-teal-500 w-full p-3 rounded",
            ),
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

fn regex(model: Model, string) -> Effect(Msg) {
  let query = regex.from_string(string)

  case query {
    Error(_query) -> effect.none()
    Ok(query) -> {
      use dispatch <- effect.from()
      model.database
      |> database.regex(query)
      |> SetResults
      |> dispatch
    }
  }
}

fn fuzzy(model: Model, query: String) -> Effect(Msg) {
  use dispatch <- effect.from()
  model.database
  |> database.fuzzy(query)
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
