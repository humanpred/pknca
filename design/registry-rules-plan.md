# Parameter registry rules:  ratios, metabolite ratios, historical names, and SE/DF companions

Decisions by Bill Denney (2026-11-13).  The plan is written against main
be353efa.  Secondary parameters follow
[secondary-parameters-plan.md](secondary-parameters-plan.md) §3.16, the
as-built description, without change.

## Decisions

| Topic | Decision |
|---|---|
| Ratios | Built by a rule from a base parameter (`ratio.<base>`), not added by name. |
| Ratio bases | Concentrations, AUCs, and amounts, but not AUMCs.  The base is calculated directly (not FUN `NA`), is not dose-normalized, and is not secondary; its unit type is `conc`, `auc`, or `amount`.  There is no ratio of a `.dn` parameter and no `.dn` of a ratio. |
| Metabolite ratios | `mr.<base>`, beside the ratios on one interval, with the same eligible bases. |
| Molecular weight | Only through unit conversion, with **hand-built per-analyte units tables** and their own conversion factors.  PKNCA takes no molecular weight. |
| `mr.*` units | "mol/mol" when both sides are molar, and "g/g" when both are mass.  A mixed pair is a typed error.  `ratio.*` of one analyte keeps "fraction". |
| CDISC codes | No invented code.  PPTESTCD is the PKNCA parameter name unless a controlled-terminology code is known.  The six existing ratio codes stay in an override table, and a code is added only when confirmed in CT. |
| Historical names | A plain character vector `historical_names` in `add.interval.col()`, with no version recorded.  The accessor returns the old and current names.  Re-registering without the argument keeps the historical names. |
| SE/DF companions | Outputs of their parameter, not requestable columns.  Naming one warns and is a request for its parent, indefinitely. |
| Deprecation (standing rule for PKNCA) | "Warn, work indefinitely (I value backward compatibility for mature packages like PKNCA)":  an old name or a retired request warns and keeps working, with no removal date. |

## Today

- The registry is `.PKNCAEnv$interval.cols`, written only by `add.interval.col()`
  (R/001-add.interval.col.R:575), which clears four caches on every write.
  There are 325 entries.
- `.dn` members come from a load-time loop over a hand list of 14 bases
  (R/zzz-pk.calc.dn.R:13): FUN `pk.calc.dn`, `depends` = the base.  Their unit
  type is pasted as `"<base>_dose"`, which `match.arg()` accepts only by
  partial matching to `*_dosenorm`.
- There are six hand-registered `ratio.*` entries
  (R/secondary-parameters.R:398-474), with codes RCMAX, RAUCLST, RAUCIFO,
  RAUCIFP, RAUCINL, and RAUCINA.
- 54 historical names, each registered as a full copy of its replacement,
  were listed by hand before this plan; they are now declared with
  `historical_names` (see "Historical names in `add.interval.col()`" below),
  and `pknca_parameter_renames()` lists them.
  - `assert_intervals()` warns (`pknca_warning_deprecated_parameter`); the
    old name keeps working.
  - Readers of the list (each now reads `parameter_renames()`):
    - deprecated-parameters.R;
    - pk.calc.all.R (output-only names);
    - interval-table.R;
    - exclude_nca.R;
    - set_and_assert_intervals.R;
    - eight test files.
- There are 28 SE/DF companions: 12 in auc.R, 12 in auciv.R, and 4 deprecated
  `sparse_*`.  Each is FUN `NA`, depending on its parent.
  - Requested alone with dense data, one is `pknca_error_sparse_only_parameter`.
  - With sparse data, one computes its parent, and the parent's row is
    returned too.

## One mechanism:  rules that make registry members

`add_parameter_rule(prefix, eligible, make)` stores a rule in
`.PKNCAEnv$parameter_rules`.  `eligible(spec)` is a predicate on a registered
base's entry; `make(base_name, spec)` returns the arguments for
`add.interval.col()`.  `resolve_parameter_name(name)`, called wherever a name
is looked up, works in three steps:

1. A registered name is used as it is.
2. Otherwise, `<prefix>.<base>` with a registered, eligible `base` is
   registered with `make()` and returned.
3. Otherwise the name is unknown.

`assert_intervals()` resolves column names before it builds the allowed set.
`PKNCAresults` readers resolve parameter codes the same way, so a result read
in a new session finds its member.  A generated member is an ordinary registry
entry, so validation, classification, CDISC lookup, units, and the second pass
(§3.16) need no change.  `pknca_parameter_rules()` lists the rules for the
documentation and for the enumerating tests.

## `ratio.<base>`

- **Member:**
  - FUN `pk.calc.ratio`, with `formalsmap` test = base and reference =
    `pknca_ref(base)`, and `depends` = base;
  - unit type `fraction`;
  - `selection = list(concept = "parameter_ratio")`;
  - pretty name "Ratio of <base pretty name> to Reference";
  - summary by geometric mean and geometric CV.
- **Reference:** another interval, through the existing `<param>_ref`,
  `group_ref`, and `ref_vary` machinery.
- **CDISC:** the six codes above stay in an override table.  Any other member
  has PPTESTCD equal to its name until a CT code is confirmed.
- **The six names today:** the hand registrations are deleted and the names
  come from the rule.  Two tests guard this:
  - a field-by-field comparison with a stored copy of today's entries;
  - `pk.nca()` results on the secondary-parameter fixtures, compared with
    today's.
- The `.dn` loop gains the "not secondary" test.

## `mr.<base>`:  metabolite to parent

- **Member:**
  - like `ratio.*`, with selection concept `metabolite_ratio` and pretty
    name "Metabolite to parent ratio of <base pretty name>";
  - PPTESTCD is its name (no CT code is confirmed).
- **Reference:** the same interval of the parent analyte, declared with
  `group_ref` (as PKNCAdata documents for metabolite ratios).  Neither
  `group_ref` nor an `mr.<base>_ref` pointer is `pknca_error_mr_needs_parent`.
  The columns of `group_ref` join `ref_vary` for the member.

### Molar ratios through the units table

Today:

- `pknca_unit_conversion()` applies PPSTRES = PPORRES x conversion_factor
  once, in `PKNCAresults()`, after the secondary pass.  It joins the units
  table on every shared column, so a table with an analyte column converts per
  analyte.
- The secondary pass reads each side's raw PPORRES.
- `pknca_units_table_secondary()` standardizes a secondary row from the two
  sides' PPORRESU only ("fraction" when they are convertible).  Each side's own
  conversion factor never reaches the ratio.
- Its reference-keyed rows (`<group>_ref` columns) are built only for the
  table that `PKNCAdata()` builds itself, not for a hand-built one.

To build:

1. **Each side's conversion.**  For the pair (own group, reference group),
   factor = cf_own / cf_ref x reconcile(PPSTRESU_own -> PPSTRESU_ref), and
   PPSTRESU is the quotient of the sides' PPSTRESU.  The ratio's standardized
   value is then the ratio of the converted values.  With no conversions,
   cf = 1 and PPSTRESU = PPORRESU, so every result today is unchanged, which a
   test on the secondary fixtures pins.
2. **Reference-keyed rows for a hand-built table.**
   - When the `units` given to `PKNCAdata()` has group columns, each distinct
     combination of their values is a unit set.
   - `pknca_units_table_secondary()` builds the reference-keyed rows from those
     sets, as it does for the table `PKNCAdata()` builds.
   - An `mr.*` result that finds no reference-keyed row for its pair is
     `pknca_error_units_secondary_missing`, naming the two groups.  It is not
     a silent mass ratio.
3. **Labels and mixed pairs.**
   - `mr.*` has PPSTRESU "mol/mol" when both sides' standardized amount units
     are molar, and "g/g" when both are mass.  PPORRESU is composed the same
     way from the original units.
   - One side molar and the other mass is `pknca_error_mr_units_mixed`,
     naming both analytes and their units.
4. **Documentation**, with one worked example.  Parent MW 325.8 g/mol,
   metabolite MW 341.8 g/mol, concentrations in ng/mL, time in h.
   - 1 ng/mL = 1000/MW nmol/L, so the factors are 3.0694 (parent) and
     2.9257 (metabolite).
   - One `pknca_units_table(concu = "ng/mL", timeu = "hr", conversions = ...)`
     per analyte converts ng/mL to nmol/L and ng*h/mL to nmol*h/L with that
     analyte's factor.
   - Each table gets the analyte column, and the tables are bound together and
     given as `units`.
   - The molar `mr.auclast` is the mass ratio x 325.8/341.8, with PPSTRESU
     "mol/mol".

## Historical names in `add.interval.col()`

- **Argument:**
  - `historical_names = c("cl.obs")` is a character vector, validated as
    names that are neither registered nor historical for another parameter,
    nor given twice (`pknca_error_historical_name_conflict`), and non-empty
    and not `NA` (`pknca_error_historical_names_invalid`).
  - A user who registers a parameter under a historical name gets that
    parameter (Bill, 2026-11-20: "The user's parameter wins"):  the alias is
    replaced for the session, in its place, with
    `pknca_message_historical_name_replaced`.
  - Re-registering a parameter without the argument keeps its historical
    names, so an old name never stops working because of a re-registration.
  - Generated members take theirs by rule from their base (`cav` -> `cav.last`
    gives `cav.dn` -> `cav.last.dn`).
- **Alias entries (Bill, 2026-11-16: "Generated alias entries"):**
  - `add.interval.col(historical_names = )` is the only place an old name is
    written.  Each old name is registered as an alias entry:  a copy of its
    parameter marked `historical_of = "<current>"`, tier "uncommon", and
    rebuilt in place whenever the parameter is registered again.
  - Order:  when the package is loaded, the aliases follow every parameter,
    in sorted order (`.onLoad()`).  A parameter or alias registered after
    that is added at the end, after them, as a user parameter was on main.
  - The hand list and its copy loop are gone; `add.interval.col()` is the
    only writer.  `PKNCA.set.summary()` gives an alias its parameter's
    summary, with the aliases last in sorted order.
  - The copies stay in the registry, as aliases, and `get.interval.cols()`
    still lists the old names.  Taking them out of the registry, as an
    earlier draft of this plan said, would need a historical-name lookup at
    each of 62 places in 17 files that read parameter names from the
    registry (the interval checks, `filter_requested`, the units table, the
    CDISC codes, the summary instructions, the exclusion rules, and more),
    where any one missed would silently drop an old name.  With aliases,
    every reader works unchanged and results are identical to main; an old
    and a current name requested together are both calculated, as on main.
- **Accessor:**  `pknca_parameter_renames()` returns a data.frame of
  `historical` and `current`, built from the alias entries; every reader
  listed above uses it.
- **Warning:**  "This NCA parameter is deprecated, and the old name keeps
  working; use the new name instead", for the renamed and the deprecated
  sparse names alike, with the same wording in NEWS and the help.
- **Test:** iterate `pknca_parameter_renames()`.  Each historical name, through
  `pk.nca()`, gives the warning class, the requested PPTESTCD, and the value of
  the current name.
- **Same rule elsewhere:** the 11 `deprecated_sparse_parameters` share the
  warning text above and stay as they are otherwise.

## SE/DF companions are outputs, not columns

- The 28 keep their registry entries (units, labels, codes), with
  `output_of = "<parent>"` set by `add.interval.col(output_of = )`.
- `check.interval.specification()` no longer fills them in as columns.
- A specification that names one:
  - gets `pknca_warning_deprecated_parameter`-class warning, naming the parent;
  - is a request for the parent;
  - keeps working with no removal date.
- **Who is affected:** sparse specifications that list `*_se` or `*_df` (the
  values are unchanged), and dense ones (today an error, then the same
  warning).
- The tests that change: test-pk.calc.all.R:1011-1119,
  test-set_and_assert_intervals.R:129, test-sparse.R:301 and :593, and
  test-interval-table.R:120.

## Order of work

Each is one PR off main.

1. Historical names: it changes registration, and the others use the accessor.
2. SE/DF companions.
3. `ratio.*` by rule.
4. The units changes (each side's conversion, reference-keyed rows for
   hand-built tables).
5. `mr.*`.

## Found outside these decisions

- The `.dn` unit types pass only by partial matching (`"auc_dose"` to
  `"auc_dosenorm"`).  The rule's `make()` should paste the full name.
- The `.dn` hand list could become a rule on the same mechanism.  That is not
  decided.
