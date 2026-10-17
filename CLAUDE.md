# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Tailor Shop Ledger: a Ruby on Rails app that shows small tailoring and alteration shops whether their work pays. A shop records the services it offers, with their price and material cost; the jobs it charges for; its fixed costs, occasional expenses and other income. The app turns that into a goal for the day and results by day, week, month, semester and year. Several shops share one installation, each with one user who usually works alone, from a phone, and has never kept accounts.

It is the owner's public portfolio project, licensed AGPL-3.0, and real shops use it at `modisteria.yunquelabs.com`. Code quality and a clear README matter as much as features. Built by a single developer in limited time: keep it small, finished and well tested rather than broad and half-built.

## Work plan

`docs/plan.md` holds the context, decisions, domain model, business rules, screens and milestones. Read it at the start of every session. A new milestone starts only when the owner says so; once started, work through its unchecked tasks. Check tasks off in the commit that completes them, and record any changed decision there.

## Working with the owner

- The owner writes in Spanish: reply in Spanish, informally (tú). Code, comments, docs, the `en` copy and commit messages are in English.
- Act as a strict mentor: if an idea is bad, wrong or risky, or may be, say so first, with the concrete reason. No flattery: the owner wants the truth, not validation.
- Ask as many questions as it takes before acting on anything unclear, but first check what you can yourself (files, configs, commands). Always ask before large changes or new dependencies.
- The owner is a senior Rails developer: don't explain Ruby, Rails or git basics.
- Build what the current milestone needs, and nothing ahead of it.
- Helper scripts outside the app (one-off data or ops tasks) are Python 3.12, standard library first and `uv` when a dependency is needed. App code is Ruby. The machine has no pip, pipx, poetry or gh.

## Scope

v0.1 is what one shop needs to know whether its work pays, deployed and backed up. Details and order are in `docs/plan.md`.

In v0.1:
- Several shops in one installation, each with one user and its own services, records, fixed costs and work days. The operator creates shops with a rake task.
- Services with a price and a material cost, which can be 0. They are deactivated, never deleted.
- Jobs: one record per service done, with its date, quantity, price and material cost, copied from the service and editable.
- Fixed costs with a monthly amount that applies from a month on, never changing earlier months. Occasional expenses and other income, with date, concept and amount.
- Today: the day's goal, what the shop has made towards it and the month so far.
- Reports for a day, a week (Monday to Sunday), a month, a semester and a year: charged, materials, other income, other expenses, the fixed costs of the days worked and the result; the services that left the most in the period; and the last six months, month by month.
- Mobile first and responsive, in `en` and `es-CO`, with an icon on the phone's home screen.
- Demo seeds and a README with screenshots.
- Deployed with Kamal next to the owner's gym app, with nightly off-site backups.

Out, until shops ask for it: order tracking (customer, due date, status), customer data, receipts, invoicing, inventory, supplies per recipe, payment methods, Excel export, charts, offline mode, several users per shop.

## The accounting rules are the product

Costs are what these shops struggle with, so the rules under Business rules in `docs/plan.md` are what makes the app useful. Materials count once, inside each job: supply purchases are never recorded as expenses. Fixed costs spread over the days the shop works, so the day the rent is paid doesn't show a loss and every other day an inflated profit. When the shop is in the home, the help texts warn that charging the whole home's bills to the shop, or counting income that isn't the shop's, distorts its result. Don't change these rules without the owner.

## Stack

- Ruby on Rails 8.1 with its defaults: Hotwire (Turbo and Stimulus), Propshaft, importmap, Solid Queue, Solid Cache and Solid Cable. No Redis, Sidekiq or Node.
- Tailwind CSS through `tailwindcss-rails`.
- Multi-tenant: `shop_id` on every shop-owned table with `acts_as_tenant` and `require_tenant`. The shop comes from the signed-in user, and URLs carry no shop. There are no roles and no Pundit: isolation between shops is the authorization, and request specs prove it. No change history.
- PostgreSQL 17, installed locally.
- Authentication with the Rails 8 generator, not Devise, without the email password reset.
- RSpec with FactoryBot, and system specs for the critical flows.
- RuboCop (rubocop-rails-omakase, plus the rubocop-rspec cops that back the spec rules) and Brakeman, both run in GitHub Actions CI, which also builds the demo seeds.
- Deploy with Kamal to the VPS that runs the owner's gym app, at `modisteria.yunquelabs.com`, with its own PostgreSQL accessory, nightly backups to a Cloudflare R2 bucket of its own, a Healthchecks.io check on the backup, and its own Sentry project for errors.
- Ruby 4.0.7 through rbenv, pinned in `.ruby-version`. The machine's global Ruby is 3.0.6, too old for Rails 8.

## Reusing the gym app

The owner's gym app, in `~/Desktop/gym-membership-manager` (a private repository), already solves most of the setup with this same stack: authentication, tenancy, I18n, specs, RuboCop, CI, Sentry, Kamal and backups. Read it and copy what applies instead of reinventing it, renaming as you go; its `CLAUDE.md` and `docs/deploy.md` explain each piece. Never copy its secrets, its credentials or anything about its gyms.

## Conventions

- All user-facing text goes through I18n, in `en`, the project's language and the default, and `es-CO`, the default in production. `APP_LOCALE` picks one per installation. Specs run in `en` and assert its copy; `spec/i18n_spec.rb` checks that both locales have the same keys. The approved screens are in Spanish: the `es-CO` copy follows them word for word, and `en` translates it.
- Time zone America/Bogota. Dates the app reasons about are `date` columns; use `Date.current`, never `Date.today`.
- Money in Colombian pesos, stored as integers, never negative. Money attributes use the `pesos` attribute type, which drops anything that isn't a digit before casting: `15.000` and `15,000` both save 15000, where Rails' integer cast would save 15.
- Tenancy runs with `require_tenant`: code outside a request (rake tasks, seeds, console) runs inside `ActsAsTenant.with_tenant(shop)`, and jobs keep the shop they were enqueued with.
- This repository is public. Never commit a real shop's data, names or figures, anything about the owner's clients or deals, secrets or `config/master.key`. Seeds and screenshots use fake data only.
- Small, focused commits. The message is a single English subject line with no body. Never mention Claude, Claude Code or any AI tool in commit messages, and never add co-author trailers.
- Dependabot's pull requests aren't merged, since their commits carry a long body: the bump lands as an ordinary commit on `main`, which closes the pull request. A gem nothing uses is removed instead of bumped.
- The git remote uses the SSH host alias `github` (the owner's personal account): `git@github:atlmetal/tailor-shop-ledger.git`. Keep it that way; the local git identity is set in `.git/config`.

### Layers

Controllers and views hold no business logic. Each piece of code belongs to one of these layers. Apart from `ApplicationService`, a layer's folder and base class arrive with its first real use.

- Models: associations, validations, enums, scopes and small predicates about the record itself.
- Services (`app/services`): business rules and workflows, one class per use case, namespaced by domain, e.g. `FixedCosts::ChangeService`. They inherit from `ApplicationService`, receive everything in `initialize` and run with `.call`.
- Queries (`app/queries`): anything beyond a simple scope, such as the results of a period, as query objects inheriting from `ApplicationQuery`, also run with `.call`.
- Arel instead of SQL strings, through `Model[:column]` (e.g. `Job[:done_on]`). Simple conditions keep the Active Record interface (`where(done_on: range)`). Rails treats Arel as internal API, so it stays in scopes and query objects, where an upgrade breaks it in one place.
- Controllers: find records within the current shop, then render or redirect. Plain CRUD on one record stays in the controller; anything with rules beyond that record's validations goes through one service or query.
- Views: render and iterate only. Formatting and display conditions go to helpers, one module per area. Behaviour shared by several models or controllers goes to concerns.
- Facades (`app/facades`): a page that needs data from several sources, like Today or Reports, gets one facade instead of several instance variables. Plain objects namespaced by domain, e.g. `Reports::PeriodFacade`, with no base class while they share nothing.
- Form objects (`app/models`, with `ActiveModel::Model`): what a form collects when it isn't one record. The service that acts on one validates it first and leaves its errors on it for the form.

### Visual design

- The approved design, five phone screens in the "tape measure" direction, is described in `docs/plan.md` with its tokens and copy. Build it as approved; pages it doesn't cover follow its tokens and patterns.
- Visual work goes through the `frontend-design` skill (plugin `frontend-design@claude-plugins-official`). Review the result with the owner in screenshots at phone and desktop width.
- Within the stack: Tailwind through `tailwindcss-rails`, no Node and no new JavaScript libraries; fonts self-hosted under `app/assets`, never loaded from a third-party CDN.

### Responsive UI

Most users run the app from an Android phone and some from a computer, so every page is built mobile first and works from 360px wide up.

- Base classes style the phone; `sm:`, `md:` and `lg:` add the wider layouts. No page scrolls sideways on a phone.
- Touch targets are at least 44px tall, and primary buttons span the full width on phones.
- Inputs use the right `type` and `inputmode`: dates are `type="date"` and money fields `inputmode="numeric"`, so phones show the right keyboard.
- Amounts use the monospace face, so their digits line up.
- System specs run at a phone viewport (390×844); tag an example `:desktop` for the wide layout. When a page is added or changed, check it at both sizes.

### Specs

- `instance_double` first, with `allow(...).to receive` and `expect(...).to have_received`. `build_stubbed` only when a real object is unavoidable.
- `create` only in model, request, query and system specs, which need real rows. Service, facade and helper specs never touch the database.
- RSpec DSL only: `describe`, `context`, `let`, `subject`, `before`, `shared_examples` and matchers. No `def`, instance variables, loops or conditionals in spec files.
- Every controller that reads or writes a shop's records has request specs showing that a user of another shop gets a 404.
