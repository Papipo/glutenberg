import gleam/result
import gleeunit
import gleeunit/should
import glutenberg/database

pub fn main() {
  gleeunit.main()
}

pub fn regex_find_test() {
  let db = database.init()

  db
  |> database.regex("the", False)
  |> result.unwrap([])
  |> should.equal(["At the mountains of madness"])

  db
  |> database.regex("The", False)
  |> result.unwrap([])
  |> should.equal(["The call of Cthulhu", "The shadow over Innsmouth"])

  db
  |> database.regex("[Tt]he", False)
  |> result.unwrap([])
  |> should.equal([
    "The call of Cthulhu", "At the mountains of madness",
    "The shadow over Innsmouth",
  ])
}

pub fn case_insensitive_regex_test() {
  let db = database.init()

  db
  |> database.regex("the", True)
  |> result.unwrap([])
  |> should.equal([
    "The call of Cthulhu", "At the mountains of madness",
    "The shadow over Innsmouth",
  ])
}

pub fn fuzzy_find_test() {
  let db = database.init()

  db
  |> database.fuzzy("mour")
  |> should.equal(["At the mountains of madness", "The shadow over Innsmouth"])

  db
  |> database.fuzzy("mour cal")
  |> should.equal([
    "At the mountains of madness", "The shadow over Innsmouth",
    "The call of Cthulhu",
  ])

  db
  |> database.fuzzy("mour call")
  |> should.equal([
    "The call of Cthulhu", "At the mountains of madness",
    "The shadow over Innsmouth",
  ])
}
