# UrlChecker

A URL validator that filters by path rules and file type — the drop-acceptance policy for drag-and-drop handlers.

`UrlChecker` decides whether URLs are acceptable based on the `pattern` (matched according to `patternBehavior`) and the file type (`acceptDirs`/`acceptFiles`). The path checker is rebuilt immediately through `QProperty` bindings whenever `pattern`/`patternBehavior` change, so rule changes need no object rebuild.

The four `patternBehavior` modes:

- `FullMatch` — the absolute path or the file name equals `pattern` exactly.
- `PatternIsRegex` — the whole absolute path is matched against `pattern` as a `QRegularExpression`.
- `PatternIsFileNameList` — `pattern` is a comma/semicolon-separated file-name list; a path whose file name is in the set is accepted.
- `PatternIsSuffixList` (default) — `pattern` is a comma/semicolon/space-separated suffix list. Each suffix loses its leading dots and is escaped, then joined as `"(suffix1|suffix2…)$"` and matched case-insensitively against the path end. Empty segments are dropped via `SkipEmptyParts` — an empty segment would produce an empty suffix and an always-true empty branch in the regex; escaping is mandatory, otherwise regex metacharacters in a suffix (e.g. `"c++"`) would change the match structure.

An empty `pattern` accepts every path.

`checkType()` first filters by type — directories are not constrained by `acceptFiles` and vice versa — then `isAcceptable()` merges the type verdict with the path-rule check into the final decision.

Note: the lambdas inside `containsAcceptableUrls()`/`acceptableUrls()` capture `this` and must never be declared `static` — a local `static` initializes only once and captures the pointer of the first-calling instance, which dangles after that instance is destroyed and leaks check logic across instances.

## Properties

- `pattern : string`
  The path rule; empty accepts everything.

- `patternBehavior : PatternBehaviors` (default `PatternIsSuffixList`)
  One of `FullMatch`, `PatternIsRegex`, `PatternIsFileNameList`, `PatternIsSuffixList`.

- `acceptDirs : bool` (default `true`)
  Whether directories are accepted.

- `acceptFiles : bool` (default `true`)
  Whether files are accepted.

## Signals

This type defines no signals.

## Methods

- `bool isAcceptable(QUrl url)`
  Returns `true` when `url` passes the type filter and the path rule.

- `bool containsAcceptableUrls(list<QUrl> urls)`
  Returns `true` when at least one URL in the list is acceptable (`false` for an empty list).

- `list<QUrl> acceptableUrls(list<QUrl> urls)`
  Returns the subset of `urls` that is acceptable.

## Usage Example

```qml
import QtQuick
import Qool.File

UrlChecker {
    id: checker
    patternBehavior: UrlChecker.PatternIsSuffixList
    pattern: "png, jpg; jpeg, svg"
    acceptDirs: false
}

// In a drop handler:
// checker.containsAcceptableUrls(drop.urls)   →  bool
// checker.acceptableUrls(drop.urls)           →  list<url>
// checker.isAcceptable(drop.urls[0])
```
