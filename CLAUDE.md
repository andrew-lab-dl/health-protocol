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
- the `cloudSync()` call at the end of `switchToDate`

Never straight-copy. Diff the new version against the deployed `index.html`,
port Andrew's actual changes forward, and keep everything above intact. Then
`node --check` the extracted `<script>` block before pushing.

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
