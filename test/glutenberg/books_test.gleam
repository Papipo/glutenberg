import gleam/regex
import gleeunit
import gleeunit/should
import glutenberg/database

pub fn main() {
  gleeunit.main()
}

pub fn regex_find_test() {
  let db = database.init()
  let assert Ok(regex) = regex.from_string("the")

  db
  |> database.regex(regex)
  |> database.to_list
  |> should.equal(["At the mountains of madness"])

  let assert Ok(regex) = regex.from_string("The")

  db
  |> database.regex(regex)
  |> database.to_list
  |> should.equal(["The call of Cthulhu", "The shadow over Innsmouth"])

  let assert Ok(regex) = regex.from_string("[Tt]he")

  db
  |> database.regex(regex)
  |> database.to_list
  |> should.equal([
    "The call of Cthulhu", "At the mountains of madness",
    "The shadow over Innsmouth",
  ])
}
