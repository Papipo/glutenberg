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
  Model(database: Database, results: List(String))
}

pub type Msg {
  Search(query: String)
  SetResults(results: List(String))
}

pub fn app() {
  lustre.application(init, update, view)
}

fn init(database: Database) {
  #(Model(database, []), effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Search(query) -> #(model, regex(model, query))
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
            ],
            [html.option([], "RegEx")],
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
      |> database.to_list
      |> SetResults
      |> dispatch
    }
  }
}
