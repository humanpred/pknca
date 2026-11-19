# Ctrough as the predose concentration of the dose that starts the interval

Against main 7fb438cd; no code before Bill has read this.  His rule:
"Predose of the dose that starts the interval".  The values in section 4 come
from `pk.nca()` on main and from a prototype of the rule in a script, not from
package code.

## 1. What the rule says, made exact

For an interval that starts at a dose, Ctrough is the concentration of the
sample taken just before that dose:

- a sample at the dose time itself is predose (the usual convention, and what
  `start_predose` assumes);
- otherwise, the most recent measured sample before the dose, if it lies within
  a window.  The prototype uses the `start_predose` window, 5% of the interval
  (of the time to the last sample when the interval has no finite end);
- an interval that does not start at a dose has no Ctrough;
- the value is a measurement, so it is read from the group's data, not from the
  interval's imputed data.  An imputed start (`start_cmin`, `start_conc0`) is
  not a predose sample.

Sections 7 and 8 list the choices in these four points that are Bill's to make.

## 2. What PKNCA does today

- **`ctrough`** is `C(t_end)`:  the concentration whose time equals the end of
  the interval exactly, read from the interval's data after imputation
  (`pk.calc.ctrough()`, `formalsmap = list(end = "time.end")`).  No match, or
  a missing value there, is `NA`.  It is registered with `PPTESTCD` `CTROUGH`
  ("Conc Trough"), the description "Trough (end of interval) conc", tier
  `common`, and selection for multiple and steady-state dosing, so every
  generated multiple-dose interval reports it.  `end_conc_drop` imputation
  excludes it in `pknca_interval_table()`, because dropping the end sample
  removes exactly what it reports.
- **`cstart`** is `C(t_start)` on the same terms (`CSTART`, described as "The
  predose concentration").  Because it reads the imputed data, it is the
  shifted predose sample under `start_predose`, the interval's minimum under
  `start_cmin`, and 0 under `start_conc0`.
- **Calculated from `ctrough`:**  `ptr` (`cmax/ctrough`),
  `aucabove.trough.all`, and `ctrough.dn`.  `be_assess()` judges `ctrough`
  like Cmax as Ctau,ss (its documentation cites the EMA modified-release
  guideline, section 6.8.2.2, and Health Canada, section 2.1.1.1).
- Neither gives a `PPANMETH` (the column is empty for both).

## 3. The external definitions

As given in the brief, not re-checked here; they should be confirmed against
the current sources before any code:

- CDISC C102394 (`CTROUGH`):  "Concentration at end of a dosing interval,
  immediately before the next dose is administered".
- EMA:  C-tau, the concentration at the end of the dosing interval.
- FDA:  Cmin,ss.

All three describe the end of the interval, the predose sample of the *next*
dose, which is what `ctrough` is today when a sample sits exactly at the end.
Bill's rule takes the predose sample of the *current* dose.  At steady state
both estimate the same quantity, but for a given interval they are different
samples:  under the rule, the Ctrough of 24-48 h is the sample that today is
the Ctrough of 0-24 h.

## 4. What would change

Doses of 100 at 0, 24 and 48 h; samples at 0, 1, 2, 4, 8, 12, 24, 25, 26, 28,
32, 36, 48, 49, 50, 52, 56, 60 and 72 h, with C(24) = 1.2, C(48) = 1.4 and
C(72) = 1.5.  "Today" is `pk.nca()` on main without imputation; with
`start_predose` the `ctrough` column is the same and `cstart` is as in the
last column.

| Interval shape | Interval | `ctrough` today | Rule | `cstart` today (none / `start_predose`) |
|---|---|---|---|---|
| Samples at both bounds | 24-48 | 1.4 | 1.2 | 1.2 / 1.2 |
| Predose drawn at 23.95 h | 24-48 | 1.4 | 1.2 (from 23.95) | NA / 1.2 |
| Next predose drawn at 47.95 h | 24-48 | NA | 1.2 | 1.2 / 1.2 |
| Last dose, no finite end | 48-Inf | NA | 1.4 | 1.4 / 1.4 |
| Last dose, finite end with no next dose | 48-72 | 1.5 | 1.4 | 1.4 / 1.4 |
| First dose of the regimen | 0-24 | 1.2 | 0 | 0 / 0 |
| Interval spanning two doses | 0-48 | 1.4 | 0 | 0 / 0 |
| Interval not starting at a dose | 12-24 | 1.2 | NA | 2.5 / 2.5 |
| Single dose | 0-24 | 1.2 | 0 | 0 / 0 |
| Single dose, no finite end | 0-Inf | NA | 0 | 0 / 0 |

In words:

- **Every interval with a sample at its end changes value**, from the end
  sample to the predose sample of its own dose, and so do `ptr`,
  `aucabove.trough.all`, `ctrough.dn`, and any `be_assess()` result on
  `ctrough`.  At 24-48 h above, `ptr` moves from 6.43 to 7.50 and
  `aucabove.trough.all` from 61.79 to 62.72 (the trough it subtracts falls
  from 1.4 to 1.2).
- **NA becomes a value** when the end sample is off its nominal time and when
  the interval has no finite end.
- **A value becomes NA** for an interval that does not start at a dose.
- **The first dose and a single dose give the baseline** (0 here) instead of
  the concentration at the end.
- **Default results change:**  `PKNCAdata()` without intervals, on the data
  above, gives 0-24, 24-48 and 48-72 with `ctrough` (1.2, 1.4, 1.5 today; 0,
  1.2, 1.4 under the rule), so every default multiple-dose analysis changes
  its `ctrough`.

Under `start_predose`, the rule gives the same value as today's `cstart` in
every shape above except the one that does not start at a dose.  The rule is
close to "`cstart`, on measured data, at a dose".

## 5. `PPTESTCD` and `PPANMETH`

- Redefined in place, `ctrough` would keep `CTROUGH`, whose CDISC definition
  (end of the interval, before the next dose) no longer describes it.  Whether
  the CDISC PK parameters codelist has a code for the predose concentration of
  the current dose needs checking; until then a new parameter would carry a
  sponsor-defined code.
- `PPANMETH` could say where the value came from:  "Ctrough: predose sample at
  23.95 h" when the window was used, nothing extra when the sample is at the
  dose time.  Neither parameter gives one today.

## 6. Backward compatibility

Bill's standing rule is that nothing that works stops working and every moved
value is named.  Redefining `ctrough` in place would not stop anything working,
but it would move the value of every multiple-dose `ctrough` (and of `ptr`,
`aucabove.trough.all`, `ctrough.dn`, and Ctau,ss in `be_assess()`) for code
that is unchanged, with the code and the name still pointing at the CDISC and
EMA end-of-interval definitions.  NEWS would list all of it as a breaking
change.

## 7. Options

- **A.  Redefine `ctrough` in place.**  One name, Bill's meaning.  Every
  multiple-dose `ctrough` and its dependents move; `CTROUGH` and the
  `be_assess()` documentation no longer match the definition; `end_conc_drop`
  no longer needs to exclude it, and `start_cmin` and `start_conc0` need not
  either, because it reads measured data.
- **B.  Make `cstart` follow the rule** (measured data, window, dose at the
  start) and report it where Bill's tables say Ctrough.  `ctrough` keeps the
  CDISC and EMA meaning.  `cstart` moves instead:  NA becomes a value where the
  predose sample is off its nominal time without imputation, the imputed value
  becomes the measured one (or NA) under `start_cmin` and `start_conc0`, and a
  value becomes NA where the interval does not start at a dose.
- **C.  Add a parameter for the rule** (name to choose, for example
  `ctrough.predose`) and leave `ctrough` and `cstart` as they are.  The
  generated multiple-dose and steady-state intervals select the new parameter
  instead of `ctrough`; that changes the default results (named in NEWS) but
  no explicitly requested value.  `ptr` and `aucabove.trough.all` keep
  `ctrough`; companions on the new parameter can follow if wanted.

## 8. Recommendation

C.  It gives the rule an exact definition (window, dose at the start,
measured data) without moving any value a user asked for by name, and keeps
`ctrough` matching the CDISC, EMA and BE meaning that its code and its
`be_assess()` use rely on.  Bill's rule then acts where it matters to him,
in what is reported by default.

Questions for Bill, whichever option:

1. A, B or C?
2. The window:  `start_predose`'s 5% of the interval, or a fixed time given as
   an option?  (Separately, `start_predose` today checks the window as if every
   interval started at 0, so after the first dose any earlier sample passes;
   that is reported as its own fix.)
3. An interval that does not start at a dose:  `NA` with a reason, or the
   predose sample of the most recent dose before it?
4. The first dose of a regimen and a single dose:  the baseline (0 or the
   endogenous level), or `NA` because there is no trough before the first
   dose?
