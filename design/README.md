# PKNCA Design Documents

This directory contains internal design review documents for the PKNCA package. These files are excluded from the R package build via `.Rbuildignore` and are intended for maintainers.

## Documents

| File | Contents |
|------|----------|
| [01-architecture.md](01-architecture.md) | Package structure, S3 OOP design, class hierarchy, parameter registration system |
| [02-best-practices.md](02-best-practices.md) | Roxygen2 docs, NAMESPACE hygiene, error handling, input validation, dependency review, test coverage |
| [03-performance.md](03-performance.md) | Identified performance bottlenecks, memory concerns, vectorization opportunities |
| [04-code-clarity.md](04-code-clarity.md) | Confusing sections, naming inconsistencies, underdocumented internals |
| [05-future-work.md](05-future-work.md) | Design decisions worth reconsidering, deprecation candidates, breaking changes for v1.0 |
| [06-potential-bugs.md](06-potential-bugs.md) | Potential bugs, edge cases, and logic issues found during code review |

## Audit Date

This audit was conducted against PKNCA version 0.12.2 (branch: `main`, approximately March 2026).
