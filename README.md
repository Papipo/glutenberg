# glutenberg

## Running

```sh
gleam run -m lustre/dev start
```

## Shortcuts

- Single gleam project, didn't separate FE from BE
- Using lustre dev server. For the same reason as above, I didn't setup mist nor any other server. This runs on the browser
- The database module has 3 hardcoded books.
- There are no tests for the UI.
- Didn't bother to make the autocompletion results interactive.

## Iterations

- Implemented the basic UI + RegEx search. Nothing special here.
- For fuzzy search, a simple Dict(Word, List(Book)) did not work because it didn't properly yield substring matches. For example searching for "mou" did not yield "mountains" or "Innsmouth" results because those words were too large
- A trigram index was implemented instead. Search query is split by whitespace, then words into trigrams (the n in n-gram is configurable)
- Then I added taking (or not) case into account + regexp format error

# Decisions

- Trigrams are lowercase. I think it's a reasonable compromise. It's true that it can lower distance between some strings but that might in fact be desirable.

# Improvements

- Take into account the order of the words in the search query -> promote score
- Less distance = better score (right now we just count hits within the distance threshold)
- Special treatment for substrings? (0 distance)
- Limit the amount of results
- Paralelise ngram matching
