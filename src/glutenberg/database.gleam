import gleam/dict.{type Dict}
import gleam/regex.{type Regex}

pub opaque type Database {
  Database(books: Dict(Int, String))
}

pub type Book {
  Book(Int, String)
}

pub fn init() {
  [
    #(68_283, "The call of Cthulhu"),
    #(70_652, "At the mountains of madness"),
    #(73_181, "The shadow over Innsmouth"),
  ]
  |> dict.from_list
  |> Database
}

pub fn regex(database: Database, query: Regex) -> Database {
  database.books
  |> dict.filter(fn(_id, title) { regex.check(query, title) })
  |> Database
}

pub fn to_list(database: Database) -> List(String) {
  database.books |> dict.values
}
