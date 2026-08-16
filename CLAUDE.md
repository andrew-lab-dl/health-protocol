# health-protocol

Single-page health protocol tracker. `index.html` is the entire app — no build
step, no dependencies beyond the Supabase CDN script. Deployed to GitHub Pages
at https://andrew-lab-dl.github.io/health-protocol/ straight from `main`.

Andrew does not write code. Do the work directly — including external config —
rather than producing instructions for him to follow. Ask only when genuinely
blocked on a secret or an irreversible decision.

## The version-drift trap — read before deploying a new version

New versions are authored in iCloud at
`~/Library/Mobile Documents/com~apple~CloudDocs/Apps/Longevity App/Andrew_Li_Complete_Protocol vN.html`.

**Those files are always written against the pre-auth code.** Copying one over
`index.html` silently reverts:

- the login gate (markup, CSS, and the `AUTH` block in the init IIFE)
- `user_id` on every cloud row in `cloudSave` / `cloudLoad`
- `.maybeSingle()` instead of `.single()` in `cloudLoad`
- the sync-status badge and `syncErr()` error surfacing
- the `cloudSync()` calls in `switchToDate` and `checkDayRollover`
- `data-exrole="core"` on the five core workouts, and the show-up weighting in
  `getExCompletion` (see below)
- `toLocalDate()` and its call sites (see Dates below)

## Dates

Andrew is in America/Chicago. Every `YYYY-MM-DD` key must come from
`toLocalDate()`, never `new Date().toISOString().slice(0,10)` — `toISOString()`
is UTC, which rolled the day over at 7 PM Central and wiped the day's
checkboxes five hours early. iCloud versions are authored with the UTC form, so
re-apply `toLocalDate()` at every date derivation on each merge: `today`,
`getToday()`, `navDate()`, `renderStreak()`, and the trend loop. The only
correct use of `toISOString()` is the `updated_at` timestamp sent to Supabase.

Never straight-copy. Diff the new version against the deployed `index.html`,
port Andrew's actual changes forward, and keep everything above intact. Then
`node --check` the extracted `<script>` block before pushing.

## Exercise scoring

The five core workouts (`data-exrole="core"`: Alpha Strength, Conditioning,
Heavy Legs, BJJ, BJJ Open Mat) are **alternatives** — Andrew does one on a given
day. Summing all five into the denominator made a single session read ~20%, so
`getExCompletion` scores `SHOW_UP (45) + best checked core weight + incrementals`
over `SHOW_UP + max core weight + all incrementals`. Additional core sessions
stack on top as bonus, keeping >100% reachable.

Andrew's intent is that **doing at least one workout dominates the bar** — one
session lands at 63–74%. Preserve that property if the weights change. Note the
exercise items have no `data-day`, so every item counts every day.

## Supabase

Project ref `oemhujrfmjtpwxsmlwlc`. Table `protocol_kv`, composite PK
`(user_id, key)`, RLS with four owner-scoped policies on `auth.uid() = user_id`.
`authenticated` holds DML; `anon` holds nothing. Schema of record is
`supabase-setup.sql` (idempotent, safe to re-run).

The project was created with **"Automatically expose new tables" unchecked**, so
new tables get NO `anon`/`authenticated` DML grants. Any new table needs an
explicit `grant`, or every request fails with `42501` regardless of RLS policy.

The DB password is in a screenshot inside `Supbase Project Details.docx` in the
iCloud app folder. Use it to connect directly and verify schema changes actually
landed — do not ask Andrew to run SQL in the dashboard and report back. A
migration pasted into the SQL Editor silently failed three times before anyone
noticed, because the editor runs only the selected text if anything is
highlighted. After any schema change, `notify pgrst, 'reload schema'`, then
confirm through the REST API that a schema error (`42703` / `PGRST204`) has
become a permission error (`42501`).

Never commit the DB password, and never let it into `index.html`. The repo is
public. The anon key in `index.html` is public by design and is fine there.

## Verifying a change

`index.html` has no tests. Before saying a change works:

1. `node --check` on the extracted script block — catches syntax breaks.
2. Confirm the deployed page actually rebuilt; GitHub Pages lags ~45s and will
   serve the old file until it finishes.
3. For sync changes, verify against the database, not by asking Andrew to look.
