import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/set.{type Set}
import gleam/string
import glevenshtein

const distance_threshold = 1

const ngram_size = 3

pub type Score =
  Int

pub type Distance =
  Int

pub type BookId =
  Int

pub type Title =
  String

pub opaque type Database {
  Database(books: Dict(BookId, Book), index: Index)
}

pub type Book {
  Book(id: Int, title: Title)
}

pub type Results =
  Dict(BookId, Score)

type Index =
  Dict(String, Set(Int))

pub fn init() {
  let books = [
    Book(68_283, "The call of Cthulhu"),
    Book(70_652, "At the mountains of madness"),
    Book(73_181, "The shadow over Innsmouth"),
  ]

  books
  |> list.map(fn(book) { #(book.id, book) })
  |> dict.from_list
  |> Database(index: index_from_list(books))
}

pub fn regex(
  database: Database,
  query: String,
  case_insensitive: Bool,
) -> Result(List(String), String) {
  let query =
    regex.compile(
      query,
      regex.Options(case_insensitive: case_insensitive, multi_line: False),
    )

  case query {
    Error(_e) -> Error("Invalid regular expression")
    Ok(re) -> {
      let results: Dict(BookId, Score) = dict.new()

      database.books
      |> dict.fold(results, fn(results, book_id, book) {
        case regex.check(re, book.title) {
          False -> results
          True -> dict.insert(results, book_id, 0)
        }
      })
      |> to_list(database)
      |> Ok
    }
  }
}

pub fn fuzzy(database: Database, query: String) -> List(String) {
  let score: Dict(BookId, Int) = dict.new()
  let query_ngrams =
    query
    |> split_whitespace
    |> list.map(to_ngrams)
    |> option.values
    |> list.flatten

  {
    use score, ngram <- list.fold(query_ngrams, score)
    ngram_score(database, score, ngram)
  }
  |> to_list(database)
}

fn ngram_score(
  database: Database,
  scores: Dict(BookId, Int),
  ngram: String,
) -> Dict(BookId, Int) {
  use scores, indexed_ngram, book_ids <- dict.fold(database.index, scores)
  let distance = glevenshtein.calculate(indexed_ngram, ngram)
  case distance <= distance_threshold {
    True -> {
      use scores, book_id <- set.fold(book_ids, scores)
      use score <- dict.upsert(scores, book_id)
      case score {
        Some(score) -> score + 1
        None -> 1
      }
    }
    False -> scores
  }
}

fn index_from_list(books: List(Book)) -> Index {
  let index: Index = dict.new()
  use index, book <- list.fold(books, index)
  let title_words = book.title |> split_whitespace
  use index, word <- list.fold(title_words, index)

  case word |> to_ngrams {
    None -> index
    Some(ngrams) -> {
      use index, ngram <- list.fold(ngrams, index)
      use with <- dict.upsert(index, ngram)
      case with {
        None -> set.new() |> set.insert(book.id)
        Some(books) -> books |> set.insert(book.id)
      }
    }
  }
}

fn to_ngrams(str: String) -> Option(List(String)) {
  case string.length(str) >= ngram_size {
    True ->
      str
      |> string.lowercase
      |> string.to_graphemes
      |> list.window(ngram_size)
      |> list.map(string.join(_, ""))
      |> Some

    False -> None
  }
}

// Returns a list of titles ordered by search rank
pub fn to_list(results: Results, database: Database) -> List(String) {
  results
  |> dict.to_list
  |> list.sort(fn(left, right) { int.compare(right.1, left.1) })
  |> list.map(fn(tuple) {
    let assert Ok(book) = dict.get(database.books, tuple.0)
    book.title
  })
}

fn split_whitespace(str) {
  let assert Ok(re) = regex.from_string("[ ]+")
  regex.split(re, str)
}
