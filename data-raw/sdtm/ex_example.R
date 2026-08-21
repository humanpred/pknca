# Example SDTM EX (Exposure) domain for a multi-dose PK study
#
# Simulates a Phase I dose-escalation study with:
# - 6 subjects across 2 treatment arms (Drug A oral, Drug B IV infusion)
# - 3 dose levels (100mg, 200mg, 400mg oral; 50mg, 100mg IV)
# - Multiple dosing occasions (Day 1 and Day 8)
# - Mixed date-time precision (full datetime, date-only)
# - IV infusions with start/end times (for duration derivation)
# - Reference date/time for elapsed time derivation

ex_example <- data.frame(
  STUDYID   = "PKS-001",
  DOMAIN    = "EX",
  USUBJID   = c(
    # Drug A oral: 3 subjects, 2 doses each
    "PKS-001-001", "PKS-001-001",
    "PKS-001-002", "PKS-001-002",
    "PKS-001-003", "PKS-001-003",
    # Drug B IV infusion: 3 subjects, 2 doses each
    "PKS-001-004", "PKS-001-004",
    "PKS-001-005", "PKS-001-005",
    "PKS-001-006", "PKS-001-006"
  ),
  EXSEQ     = rep(c(1L, 2L), 6),
  EXTRT     = c(
    rep("DRUG A", 6),
    rep("DRUG B", 6)
  ),
  EXDOSE    = c(
    # Drug A: escalating oral doses
    100, 100,   # Subject 1: 100mg on Day 1 and Day 8
    200, 200,   # Subject 2: 200mg
    400, 400,   # Subject 3: 400mg
    # Drug B: IV doses
    50, 50,     # Subject 4: 50mg IV
    100, 100,   # Subject 5: 100mg IV
    100, 100    # Subject 6: 100mg IV
  ),
  EXDOSU    = "mg",
  EXDOSFRM  = c(
    rep("TABLET", 6),
    rep("SOLUTION", 6)
  ),
  EXROUTE   = c(
    rep("ORAL", 6),
    rep("INTRAVENOUS INFUSION", 6)
  ),
  EXSTDTC   = c(
    # Drug A oral (instantaneous dosing, date+time)
    "2024-03-01T08:00", "2024-03-08T08:00",
    "2024-03-01T08:15", "2024-03-08T08:10",
    "2024-03-01T08:30", "2024-03-08T08:25",
    # Drug B IV infusion (start of infusion)
    "2024-03-01T09:00:00", "2024-03-08T09:00:00",
    "2024-03-01T09:05:00", "2024-03-08T09:10:00",
    "2024-03-01T09:15",    "2024-03-08T09:20"
  ),
  EXENDTC   = c(
    # Drug A oral: no end time (instantaneous dosing)
    NA, NA,
    NA, NA,
    NA, NA,
    # Drug B IV: 1-hour infusions
    "2024-03-01T10:00:00", "2024-03-08T10:00:00",
    "2024-03-01T10:05:00", "2024-03-08T10:10:00",
    "2024-03-01T10:15",    "2024-03-08T10:20"
  ),
  EXRFTDTC  = c(
    # Reference date = first dose date for each subject
    "2024-03-01T08:00", "2024-03-01T08:00",
    "2024-03-01T08:15", "2024-03-01T08:15",
    "2024-03-01T08:30", "2024-03-01T08:30",
    "2024-03-01T09:00:00", "2024-03-01T09:00:00",
    "2024-03-01T09:05:00", "2024-03-01T09:05:00",
    "2024-03-01T09:15",    "2024-03-01T09:15"
  ),
  VISITNUM  = rep(c(1L, 2L), 6),
  VISIT     = rep(c("DAY 1", "DAY 8"), 6),
  EPOCH     = "TREATMENT",
  stringsAsFactors = FALSE
)

# Process SDTM EX
library(PKNCA)
ex_to_PKNCAdose(ex)
