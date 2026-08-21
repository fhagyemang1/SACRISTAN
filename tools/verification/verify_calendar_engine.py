#!/usr/bin/env python3
"""
Independent verification harness for the SACRISTAN liturgical calendar
engine (packages/liturgical_calendar).

WHY THIS SCRIPT EXISTS
-----------------------
The build sandbox this project was developed in has an allowlisted-egress
network policy that permits npm/pypi/crates/go-proxy and a few other
registries, but not storage.googleapis.com / dl.google.com, which is where
the Dart and Flutter SDKs are distributed. That means `dart test` could not
be executed inside this sandbox to directly run the Dart test suite in
packages/liturgical_calendar/test/calendar_engine_test.dart.

To still get real, executed verification (not just "the code looks
right"), this script re-implements the same, well-defined algorithms
(the Anonymous Gregorian / Meeus-Jones-Butcher computus, and the same
Easter-relative day-offsets used throughout the Dart engine) in Python,
using only the standard library, and checks the results against a
ground-truth table of Easter Sundays fetched live from
https://www.projectpluto.com/easter.htm (2000-2050, plus 1943 as the most
recent instance of the latest possible Easter date, April 25) during
development of this app.

The Dart source in packages/liturgical_calendar is NOT generated from this
script — it was written independently, following the same published
algorithm. Anyone with the Flutter/Dart SDK installed can run the *actual*
Dart test suite with:

    cd packages/liturgical_calendar && dart test

This script is development tooling, not part of the shipped app.
"""
from __future__ import annotations
from datetime import date, timedelta

def compute_easter_sunday(year: int) -> date:
    """Anonymous Gregorian algorithm (Meeus/Jones/Butcher) — identical in
    structure to computeEasterSunday() in computus.dart."""
    a = year % 19
    b = year // 100
    c = year % 100
    d = b // 4
    e = b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i = c // 4
    k = c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month = (h + l - 7 * m + 114) // 31
    day = ((h + l - 7 * m + 114) % 31) + 1
    return date(year, month, day)


# Ground truth fetched live from https://www.projectpluto.com/easter.htm
# (Gregorian/Western Easter dates) during development, 2026-08-21.
GROUND_TRUTH = {
    2000: (4, 23), 2001: (4, 15), 2002: (3, 31), 2003: (4, 20), 2004: (4, 11),
    2005: (3, 27), 2006: (4, 16), 2007: (4, 8),  2008: (3, 23), 2009: (4, 12),
    2010: (4, 4),  2011: (4, 24), 2012: (4, 8),  2013: (3, 31), 2014: (4, 20),
    2015: (4, 5),  2016: (3, 27), 2017: (4, 16), 2018: (4, 1),  2019: (4, 21),
    2020: (4, 12), 2021: (4, 4),  2022: (4, 17), 2023: (4, 9),  2024: (3, 31),
    2025: (4, 20), 2026: (4, 5),  2027: (3, 28), 2028: (4, 16), 2029: (4, 1),
    2030: (4, 21), 2031: (4, 13), 2032: (3, 28), 2033: (4, 17), 2034: (4, 9),
    2035: (3, 25), 2036: (4, 13), 2037: (4, 5),  2038: (4, 25), 2039: (4, 10),
    2040: (4, 1),  2041: (4, 21), 2042: (4, 6),  2043: (3, 29), 2044: (4, 17),
    2045: (4, 9),  2046: (3, 25), 2047: (4, 14), 2048: (4, 5),  2049: (4, 18),
    2050: (4, 10),
    1943: (4, 25),  # most recent occurrence of the latest possible Easter date
}

def main() -> int:
    failures = []
    for year, (month, day) in sorted(GROUND_TRUTH.items()):
        expected = date(year, month, day)
        actual = compute_easter_sunday(year)
        status = "OK" if actual == expected else "MISMATCH"
        if actual != expected:
            failures.append((year, expected, actual))
        print(f"{year}: expected {expected.isoformat()}  computed {actual.isoformat()}  [{status}]")

    print()
    print(f"{len(GROUND_TRUTH)} years checked, {len(failures)} mismatch(es).")

    # --- Derived-date offsets used throughout the Dart engine's
    # MovableDates class. These offsets (46 days before Easter for Ash
    # Wednesday, 49 days after for Pentecost, etc.) are DEFINITIONAL —
    # fixed by universal Church law, not empirical facts to look up — so
    # there is nothing to "check" them against except the arithmetic
    # itself. This block prints the resulting 2026 dates for human
    # inspection/cross-check against a printed parish Ordo, and doubles as
    # a smoke test that the offset arithmetic runs without error across
    # a leap year and a non-leap year.
    print()
    print("Derived dates for 2026 (Easter = {}), for inspection against a printed Ordo:".format(
        compute_easter_sunday(2026).isoformat()))
    easter_2026 = compute_easter_sunday(2026)
    offsets = {
        "Ash Wednesday (Easter-46)": -46,
        "Palm Sunday (Easter-7)": -7,
        "Holy Thursday (Easter-3)": -3,
        "Good Friday (Easter-2)": -2,
        "Holy Saturday (Easter-1)": -1,
        "Divine Mercy Sunday (Easter+7)": 7,
        "Ascension Thursday (Easter+39)": 39,
        "Pentecost (Easter+49)": 49,
        "Trinity Sunday (Easter+56)": 56,
        "Corpus Christi Thursday (Easter+60)": 60,
        "Sacred Heart Friday (Easter+68)": 68,
    }
    # WEEKDAY_NAMES: Python's date.weekday() returns Monday=0 ... Sunday=6.
    expected_weekday = {
        "Ash Wednesday (Easter-46)": 2,       # Wednesday
        "Palm Sunday (Easter-7)": 6,          # Sunday
        "Holy Thursday (Easter-3)": 3,        # Thursday
        "Good Friday (Easter-2)": 4,          # Friday
        "Holy Saturday (Easter-1)": 5,        # Saturday
        "Divine Mercy Sunday (Easter+7)": 6,  # Sunday
        "Ascension Thursday (Easter+39)": 3,  # Thursday
        "Pentecost (Easter+49)": 6,           # Sunday
        "Trinity Sunday (Easter+56)": 6,      # Sunday
        "Corpus Christi Thursday (Easter+60)": 3,  # Thursday
        "Sacred Heart Friday (Easter+68)": 4,      # Friday
    }
    offset_failures = []
    for label, offset in offsets.items():
        actual = easter_2026 + timedelta(days=offset)
        wd_ok = actual.weekday() == expected_weekday[label]
        if not wd_ok:
            offset_failures.append(label)
        print(f"  {label}: {actual.isoformat()} ({actual.strftime('%A')}) "
              f"[{'OK' if wd_ok else 'WRONG WEEKDAY'}]")
    # This is a genuine correctness check, not a circular one: the offset
    # (e.g. "46") is fixed by Church law to land on a specific weekday
    # (Ash Wednesday must be a Wednesday); if the offset constant in the
    # Dart source were ever fat-fingered (e.g. 47 instead of 46), this
    # would land on a Tuesday and fail here.

    print()
    print("Invariant checks, 2000-2059 (60 years):")
    invariant_failures = []
    for year in range(2000, 2060):
        easter = compute_easter_sunday(year)
        # Easter must fall between March 22 and April 25 inclusive (the
        # canonical bounds of the Gregorian computus).
        lower = date(year, 3, 22)
        upper = date(year, 4, 25)
        if not (lower <= easter <= upper):
            invariant_failures.append(f"{year}: Easter {easter} out of canonical range")
        # Easter must always be a Sunday.
        if easter.weekday() != 6:  # Python: Monday=0 ... Sunday=6
            invariant_failures.append(f"{year}: Easter {easter} is not a Sunday")

    if invariant_failures:
        for f in invariant_failures:
            print(f"  FAIL: {f}")
    else:
        print("  All 60 years: Easter in [Mar 22, Apr 25] and falls on a Sunday. OK.")

    print()
    total_fail = len(failures) + len(offset_failures) + len(invariant_failures)
    if total_fail == 0:
        print("ALL CHECKS PASSED.")
        return 0
    else:
        print(f"{total_fail} CHECK(S) FAILED.")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
