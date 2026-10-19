# Work plan

How Tailor Shop Ledger gets built: context, decisions, domain model, business rules, screens and milestones. Stack, conventions and what is out of scope are in [CLAUDE.md](../CLAUDE.md).

## How to use this plan

- Milestones go in order, and a new one starts only when the owner says so; once started, work through its unchecked tasks.
- A milestone is done when its tasks are checked, its specs pass and CI is green on `main`.
- Check a task off in the commit that completes it.
- From the demo seeds on, each milestone extends them with what it adds, so `bin/rails db:seed` always shows every feature built so far.
- If a rule is missing, unclear or looks wrong, stop and ask the owner, then record the answer here in its own commit.

## Who it's for

Small tailoring shops in Colombia that do alterations, sewing and dressmaking. What the owner gathered on 2026-10-16 and 2026-10-17:

- One person runs each shop, alone and usually at home, working on demand as customers bring work, most often Monday to Saturday.
- Each shop offers its own services, depending on its machines and skills. Prices are mostly fixed, though they can vary with the garment or the work, and some services use no materials.
- Most customers pay when the work is done. For some work they leave a deposit, which usually covers the materials, and pay the rest when it's done, now and then with a payment in between; one deposit can cover several garments. When the work can't be done, the deposit goes back. The shop tells those orders apart by the customer's name, the dates and the garments (gathered from the first shop on 2026-10-19).
- Supplies are bought for each order, with no stock, and their prices change about once a year.
- Today they write their work down in a notebook. Costs are the hardest part: they don't know how to keep accounts.
- Most would use the app from an Android phone, since many have no computer, but some do.
- Some have income that isn't from the shop, like rent from a room.

## Decisions

Decided by the owner on 2026-10-16 and 2026-10-17.

- **Tenancy.** Several shops share one installation and one subdomain. Every shop-owned table has `shop_id`, scoped with `acts_as_tenant` and `require_tenant`. A shop never sees another shop's data, or learns that another shop exists. Under Colombian Law 1581 each shop is the data controller; this app only processes data on its behalf.
- **One user per shop, no roles.** A user belongs to one shop, and the shop comes from the signed-in user: URLs carry no shop. Isolation between shops is all the authorization there is, so there is no Pundit, and request specs prove the isolation.
- **No super-admin UI.** The operator creates a shop and its user with a rake task, gives a user a new password with another, and uses the console for support.
- **No change history.** No paper_trail.
- **One locale and time zone per installation**, as in the gym app. `en` or `es-CO`, through `APP_LOCALE`: `en` by default, the project's language, and `es-CO` by default in production. Always `America/Bogota`.
- **No outgoing email in v0.1.** Users change their own password; a forgotten one goes through the operator. Generated passwords are 12 lowercase letters and digits, without l, 1, o or 0, so the operator can read one out and the user can type it on a phone.
- **Responsive.** Built for phones first and used the same way from a computer.
- **Installable, not offline.** Rails 8's PWA manifest puts the app's icon on the phone's home screen, named "Taller" after the subdomain for every shop: the shop's own name is at the top of every page, and a long one would get cut off under the icon. The app needs a connection.
- **Visual direction: "tape measure"** (approved as five phone screens, see Screens):
  - Neutrals: paper `#F4F3EF` background; ink `#1D1F1E` for text, primary buttons and the selected segment of a switch; graphite `#575A55` for secondary text; white `#FFFFFF` for panels and fields; `#DAD8D0` for panel borders, `#ECEAE3` for dividers between rows and `#858880` for switches and secondary buttons; `#9A9C96` for disabled controls.
  - Tape yellow `#F4C430` for the goal bar, the Record tab and the marker over the current tab; ticks `#C9C5B9` on a `#EFEDE6` track.
  - Profit, a yellow-tinted panel: `#FFF6D6` with a `#E2BC45` border. Loss, a red-tinted one: `#FBE9E2` with a `#E3A58F` border, and its word and figures in `#B03A16`. A result always shows its word and icon, never color alone.
  - Atkinson Hyperlegible Next (400, 600, 700, 800) for text and Atkinson Hyperlegible Mono (500, 700) for amounts, both self-hosted (SIL Open Font License). Base size 17px; page titles 32px at weight 800.
  - Radii: 16px for panels, 14px for buttons and switches, 12px for small buttons, 8px for the bar.
  - Plain words: "Ganancia", "Pérdida", "Te deja", "Llevas".
- **Money** is integer pesos without a money gem. Amounts show as `$15.000` in `es-CO` and `$15,000` in `en`, without decimals, and negatives as `−$47.000`.
- **Demo seeds.** `bin/rails db:seed` wipes the whole database and builds two demo shops through the app's own services, so a seed that breaks a rule fails instead of creating impossible data. They never run in production.
- **Approved gems:** rspec-rails, factory_bot_rails, capybara, selenium-webdriver, rubocop-rspec, rails-i18n, tailwindcss-rails, acts_as_tenant, sentry-ruby and sentry-rails. Ask before adding any other. Seeds use fixed lists instead of Faker.
- **Deploy** on the gym app's VPS, an OVHcloud VPS-1 (2 vCores, 4 GB of RAM), with the gym app's Kamal version, since both apps share one kamal-proxy. PostgreSQL 17 runs as this app's own accessory, and a nightly `pg_dump` goes to this app's own Cloudflare R2 bucket and token, kept 30 days.
- **Monitoring.** Errors go to a Sentry project of this app's own. Sentry's free plan has a single cron monitor, which the gym app uses, so a free Healthchecks.io check watches the nightly backup: the backup pings it when it ends, and Healthchecks.io emails when a ping fails or doesn't arrive. The gym app's uptime monitor covers the server; if only this app goes down, nothing warns, and that is accepted in v0.1.

## Domain model

Everything a shop owns carries `shop_id`: `services`, `jobs`, `fixed_costs`, `fixed_cost_amounts`, `entries`, `orders` and `payments`. `users` belong to a shop but aren't scoped by the tenant, since signing in looks them up by email. Money is integer pesos. Dates are `date` columns; use `Date.current`, never `Date.today`.

| Table | Columns | Constraints |
|---|---|---|
| `shops` | name, started_on, work_days (integer array of weekdays, 0 for Sunday; default Monday to Saturday) | at least one work day, each from 0 to 6 |
| `users` | shop, name, email_address, password_digest | Rails auth generator; unique email |
| `services` | name, price, material_cost, active (default true) | price and material cost 0 or more; unique name among the shop's active services, ignoring case |
| `jobs` | service, order (optional), done_on, quantity, price, material_cost | quantity 1 or more; price and material cost 0 or more; done_on from the shop's started_on to today, and the order's received_on in an order |
| `fixed_costs` | name, averaged (default false) | |
| `fixed_cost_amounts` | fixed_cost, starts_on, amount | starts_on is the first day of a month; unique (fixed cost, starts_on); amount 0 or more |
| `entries` | kind (`expense`, `income`), occurred_on, concept, amount | amount above 0; occurred_on from the shop's started_on to today |
| `orders` | customer_name, received_on | customer name present, up to 60 characters; received_on from the shop's started_on to today, and no later than its payments |
| `payments` | order, paid_on, amount | amount above 0; paid_on from the order's received_on to today; an order's payments add up to its total at most |

- A job's `price` and `material_cost` are per unit, copied from its service when it's recorded, so changing a service never changes recorded jobs. A job charges quantity × price, uses quantity × material cost in materials, and leaves the difference.
- An order's total is what its jobs charge, and what the customer owes is that total minus its payments.
- `Job` is a piece of work for a customer. Background jobs keep the `Job` suffix in `app/jobs`, like `BackupJob`.
- `started_on` is the day the shop starts keeping its accounts here. The operator sets it when creating the shop; nothing before it counts.

## Business rules

### Services

- Name, price and material cost. The material cost can be 0, for work that needs no materials; the price can be 0, for a service that is always quoted.
- What a service leaves ("Te deja") is its price minus its material cost.
- Services are deactivated, never deleted, and can be activated again. A deactivated service leaves the list for recording jobs, but its jobs keep it, in their forms and in the reports.
- Changing a price or a material cost never changes recorded jobs, and the services page says so.

### Jobs

- One record per service done: its date, service, quantity, and the price and material cost of each unit. Several garments under the same service make one record with a quantity; different services make one record each.
- A job on its own is recorded the day the customer pays, which is when the work is done. Work the customer pays for later, usually in parts, goes in an order instead (see Orders).
- The date defaults to today and can be any day from the shop's `started_on` to today, so days written on paper can be entered later. A job in an order takes the order's day.
- Choosing a service fills in its price and material cost, and both can be changed in each record: a quoted price, or 0 in materials when the customer brought them.
- Supply purchases are never recorded as expenses: they are already in each job's material cost. Counting them twice is the first accounting trap. The one exception is a cancelled order's (see Orders).
- Jobs can be edited and deleted. The service list in the form shows the active services, plus the job's own when editing.

### Orders

Decided by the owner on 2026-10-19, for the first shop.

- Work a customer leaves and pays for later goes in an order: the customer's name, the day they left it, its jobs and its payments. One order holds everything the customer left together, under one deposit.
- The payments are usually a deposit when the customer leaves the work, which covers its materials, and the rest when it's done; now and then one in between.
- The customer's name is all the app keeps about a customer: no phone, address or ID (see Privacy).
- An order's jobs are recorded with the job form and its rules, without a date of their own: they take the order's day, and move with it.
- Each payment counts as charged for jobs the day it arrives. An order's jobs never count their price, since its payments do; they count their materials and units the day the order was left, which is when the materials are bought, and the services that left the most count them that day too. The owner chose this over counting a whole order the day it's paid off: the deposit covers the materials, and the last payment the shop's work and profit.
- A payment's date defaults to today and goes from the order's day to today. An order's payments never add up to more than its total.
- An order is pending while it has no jobs yet or its payments don't cover them. A finished order nobody picks up stays pending: its deposit and materials already counted, and the rest never came.
- Cancelling an order deletes it with its jobs and payments, since the deposit goes back to the customer: it leaves the accounts as if it never existed. The page says to delete it only when the deposit went back, and that materials already bought for it that can't be used go in as an expense: the only materials that do, since no job carries them.
- The order, its jobs and its payments are edited and deleted from the order's page.

### Fixed costs

- What the shop pays every month, whether it works or not, each with its monthly amount: rent, electricity, water, gas, internet, a phone plan. Bills that vary use the average of the last ones, and are marked as averaged ("Promedio").
- An amount applies from a month on: the current one or a later one, never an earlier one. Earlier months keep the amount they had. A second change for a month that already has one replaces it, so a typo can be fixed within the month.
- A new fixed cost applies from the current month, one of the next two, or the month the shop started when that is earlier, so a shop that enters its days from paper carries the costs it already had, and a cost that starts now doesn't reach back to months it didn't exist.
- Removing a fixed cost is a change to 0 from a month on. It leaves the list once it's 0 from the current month on, with no later change.
- A month's fixed costs are the sum of the amounts that apply to it.
- When the shop is in the home, only the shop's share of the home's bills goes here. Each user decides that share, and the page explains it with an example: if the home's electricity is $120.000 and 30 % of it belongs to the shop, enter $36.000; entering all the home's bills (rent, electricity, water, gas, internet) can show a loss that isn't the shop's. Mixing the home's accounts with the shop's is the third accounting trap.

### Work days and the fixed costs of a day

- Each shop marks the weekdays it works, Monday to Saturday by default, and at least one.
- Each work day carries its month's fixed costs divided by the month's work days; days the shop doesn't work carry nothing. Charging the rent on the day it's paid would show that day as a loss and every other one with an inflated profit: that's the second accounting trap.
- The fixed costs of a period are, for each month it touches, the month's fixed costs × the period's work days within that month ÷ the month's work days, rounded to the peso, and then added up. A whole month always carries exactly its fixed costs.
- Only work days from the shop's `started_on` to today count: a period in progress counts up to today, today included, and nothing before the shop started.
- Changing the work days spreads each month's fixed costs again among its days; a whole month still carries all of its fixed costs.
- Holidays count as work days when their weekday is marked. A shop that closes on holidays sees those days carry their share; a holiday calendar waits until a shop asks for it.

### Expenses and other income

- Date, concept and amount, the date today by default and never before the shop's `started_on` or after today.
- Expenses are what the shop pays now and then: a machine repair, spare parts, transport. Supplies for a job don't go here, and the form says so.
- Other income is money that isn't from a job, like selling fabric scraps. The form warns that income that isn't the shop's, like rent from a room of the home, changes the shop's result.
- They are edited and deleted from the recent lists on the Record page, or from the day's report.

### Results

- Result = charged for jobs − materials + other income − other expenses − the fixed costs of the period. From 0 up it's a profit ("Ganancia"); below 0, a loss ("Pérdida").
- Charged for jobs is what the jobs on their own charged, plus the payments that came in for orders.
- The jobs of a period count their units: a record with quantity 2 counts 2.

### Today

- The day's goal is today's share of the fixed costs, when today is a work day. What the shop has made towards it ("Llevas") is today's charged amount minus today's materials. The bar fills with it, up to the goal, and the note under it says how much is left, or that the day's fixed costs are covered and by how much more.
- On a day the shop doesn't work there's no goal: the panel says so and shows what the shop made.
- The day's records include the payments that came in, and an order's jobs under its customer's name.
- "Te deben": the pending orders, the oldest first, each with its customer, its day and what's owed, opening its order; and the total owed.
- After saving or deleting a job or an entry, the app goes to Today when its date is today, and to that day's report otherwise. Saving or deleting anything inside an order goes back to the order's page, and deleting the order goes to Today.

### Reports

- Periods: day, week (Monday to Sunday), month, semester (January to June, July to December) and year. The current month opens by default. Arrows move to the previous or the next period, never past the current one and never before the one where the shop started. The switch keeps the date being viewed: each kind opens its period that holds the last day counted, so from September, Día opens September 30 and Año the whole year, and from a period in progress, the current one (decided after the approved screens).
- Each period shows its title and the range counted, from its start, or the shop's if later, to its end, or today while it's in progress; its result; the work days counted and the jobs done; the calculation, line by line; and the fixed costs per work day of the month of its last day counted: the current month while the period is in progress, its last month once it's over (decided after the approved screens).
- The services that left the most in the period: the top five by what they left, each with the units done. The day view leaves them out, since they would repeat its records (decided after the approved screens).
- Month by month, under every period: the result of each of the last six months, up to the current one, marked "hasta hoy" so it isn't compared as if it were complete. Months before the shop started don't show. The most recent comes first, and each opens its month's report (decided after the approved screens).
- The day view also lists that day's jobs, the payments that came in and its entries, each opening its form: that is how a past record is corrected.

### Privacy

- The only customer data the app stores is the customer's name on an order, which the shop needs to tell its orders apart: no phone, address or ID. The name stays out of the logs, and Sentry's defaults already leave request bodies out (decided on 2026-10-19).
- Before a second shop joins, a privacy notice and written terms of use (see Before a second shop).

## Screens

The approved design is five phone screens at 390px, in Spanish, with sample data from "Modistería La Puntada", which the demo seeds reuse. This is what each one holds; amounts are the sample's.

### Every page

- At the top, the shop's name in small graphite type, and an account button (a person icon, 44px) that opens the account page: change password and sign out.
- At the bottom, a tab bar with four tabs: Hoy, Registrar (a yellow round plus), Reportes and Taller. The current tab is bold, with a strip of tape over it.
- Not in the approved screens: sign-in, the account page and the wide layout. They follow the same tokens. On wide screens the content stays a centered column about 40rem wide, and the tab bar moves to the top from `lg` up.

### Hoy (Today), the home page

- Title "Hoy" and the date: "Martes 20 de octubre".
- The panel "Meta de hoy": "Llevas", the amount in large mono type ($32.400), "de $44.074 que necesitas hoy para cubrir los gastos fijos."; the tape bar, with "$0" and "Meta $44.074" under it; and a note with a clock icon: "**Te faltan $11.674.** Cobraste $38.000 y los materiales costaron $5.600."
- "Registrar trabajo", the primary button, and "Registrar gasto u otro ingreso", outlined.
- "Lo que registraste hoy", with the units on the right ("4 trabajos"): one row per job, "2 × Basta de pantalón", "Materiales $1.000" and "$16.000" with a chevron, opening the job.
- The panel "Octubre, hasta hoy", with the link "Ver reportes": the result's icon and word ("Ganancia"), the amount ($384.341) and "Ya descontados los materiales, los otros gastos y la parte de los fijos de 17 días de trabajo."

### Registrar (Record)

- Above the title, the top row every page has: the shop's name and the account button. The approved screen's "‹ Hoy" link repeated the Hoy tab, and pointed the wrong way when Registrar was opened from another tab or from a day's report (decided after the approved screens).
- A three-way switch: Trabajo, Gasto, Otro ingreso. Each opens its own form, so the switch needs no JavaScript.
- "Fecha", a date input, today by default.
- A job: "¿Qué servicio hiciste?", the services as radio rows with name and price, the chosen one tinted yellow; "Cantidad", with − and + buttons around the number, 1 at least; "Precio de cada uno", with "Cámbialo si cobraste otro precio."; "Materiales de cada uno", with "Pon 0 si el cliente trajo los materiales."; a summary with "Cobras", "Materiales" and "Te deja", updated while typing; "Guardar"; and "Guardar y registrar otro", which keeps the date and the service, sets the quantity back to 1 and confirms "**Guardado:** 2 × Basta de pantalón, $16.000. Sigue con el próximo."
- One Stimulus controller fills in the price and materials of the chosen service, runs the − and + buttons and keeps the summary up to date. Apart from the one that formats money fields, no other JavaScript.
- An expense: "¿En qué gastaste?", with the placeholder "Ej.: repuesto de la máquina"; "Valor"; the note "Las compras de telas, hilos y cremalleras no van aquí: ya están en los materiales de cada servicio."; "Guardar"; and "Últimos gastos", the last ten, with concept, date and amount.
- Other income: "¿De dónde salió?", with the placeholder "Ej.: venta de retazos"; "Valor"; the note about income that isn't the shop's (decided after the approved screens); "Guardar"; and "Últimos otros ingresos".
- Editing a job or an entry uses the same form, titled "Editar trabajo", "Editar gasto" or "Editar otro ingreso", without the switch or "Guardar y registrar otro": "Guardar" and "Cancelar" side by side, and "Borrar" under them. "Cancelar" goes where saving would (decided after the approved screens).

### Reportes (Reports)

- A five-way switch: Día, Semana, Mes, Semestre, Año. Under it, the period's title and range between the previous and next arrows: "Octubre de 2026", "Del 1 al 20, hasta hoy". Every period in progress ends its range with ", hasta hoy", semester and year included. A week's title is its days, "Del 19 al 25 de octubre", so under it goes only "Hasta hoy" while it's in progress, or the days counted in the week the shop started; today says "Hoy, hasta ahora", and a past day adds nothing (decided after the approved screens).
- The result panel: "Ganancia" with a check icon in the profit panel, or "Pérdida" with an alert icon in the loss panel; the amount in large mono type, a loss with its sign, "−$47.000", as everywhere (decided after the approved screens); and "17 días trabajados · 112 trabajos".
- "Cómo se calcula": Cobrado por trabajos; Materiales (−); Otros ingresos (+); Otros gastos (−); Gastos fijos de 17 días (−); a dashed rule; and Ganancia or Pérdida with the amount. Each line keeps its sign even on 0: "−$0", "+$0".
- The note "Los gastos fijos se reparten entre los días que trabajas: en octubre, cada día carga $44.074.", with the link "Ver gastos fijos".
- Decided after the approved screens, in the same style: in the day view, "Lo que registraste", with the day's jobs as in Hoy and its entries with "Gasto" or "Otro ingreso", or "No registraste nada este día."; in the other views, "Los servicios que más te dejaron", each with its units ("47 trabajos") and what it left; and under every view, "Mes a mes", each month with its result's word, icon and amount, the current one as "Octubre, hasta hoy".

### Taller (Shop): services and fixed costs

- Title "Taller" and a two-way switch: Servicios, Gastos fijos.
- Services: "Lo que cobras por cada servicio, lo que te cuestan sus materiales y lo que te deja."; "Nuevo servicio"; one row per service, with its name and price, "Materiales $500" and "Te deja $7.500", opening its form; "Desactivados (2)", folded in a `<details>`, each with "Activar"; and the note "Si cambias un precio o unos materiales, lo que ya registraste no cambia."
- Fixed costs: "Lo que pagas cada mes, trabajes o no. Luz y agua: el promedio de los últimos recibos."; one row per fixed cost, with its name, "Promedio" when it's averaged, this month's amount and an edit button; "Total de octubre"; "Agregar gasto fijo"; and the help about the home's bills, with its example (decided after the approved screens).
- Changing a fixed cost, inside its row: "Hoy: $900.000"; "Nuevo valor al mes"; "Desde", this month or one of the next two; a line saying which months keep the old amount ("Octubre y los meses anteriores siguen con $900.000."); "Guardar cambio" and "Cancelar". Afterwards the row notes the change: "Desde noviembre: $950.000".
- "Días que trabajas", on the fixed costs page: seven toggles, Lu to Do, and "En octubre trabajas **27 días**. Cada día debe cubrir **$44.074** de gastos fijos. Es la meta que ves en Hoy."; with none marked, "Marca al menos un día para calcular tu meta diaria."

### Pedidos (Orders)

Not in the approved screens: built in M9 with their tokens and patterns, and their copy recorded here once the owner approves the screenshots.

- Registrar's switch gains "Pedido", whose form takes the customer's name and the day, and goes on to the order's first job.
- The order's page: the customer's name and day; its jobs, with "Agregar trabajo"; its total, what's been paid and what's owed; its payments, with "Registrar pago"; and its edit form, with "Borrar pedido" and its note.
- On Hoy, "Te deben", and the day's records with payments and orders, as in the day's report.

## Milestones

### v0.1: one shop's accounts, deployed and backed up (about 54 hours)

No shop uses the app, the first one included, until v0.1 is finished. The deploy still comes before Reports, so the server, the backups and their restore are proven early.

#### M0. Setup (4 h)

- [x] Generate the app in this repository, keeping `LICENSE`, `CLAUDE.md` and `docs/`: `rails new . --name=tailor_shop_ledger --database=postgresql --css=tailwind --skip-test --skip-jbuilder --skip-active-storage --skip-action-text --skip-action-mailbox`. v0.1 stores no files, rich text or incoming email, so those frameworks wait until a shop needs one. The local folder is `~/Desktop/modisteria`, and `--name` keeps the app's module, databases and Kamal service named after the repository. Ruby 4.0.7 and Rails 8.1.4 are already installed for the gym app.
- [x] Pin Ruby 4.0.7 in `.ruby-version`, and Kamal at the gym app's version (2.12.0 in its `Gemfile.lock`). Both apps share one kamal-proxy, so they move to a new Kamal together.
- [x] RSpec and FactoryBot; system specs with Capybara and headless Chrome at 390×844, with one smoke spec. Copy the RuboCop config and `spec/i18n_spec.rb` from the gym app.
- [x] GitHub Actions and `bin/ci` as in the gym app: RuboCop, Brakeman, bundler-audit, importmap audit and RSpec against PostgreSQL 17.
- [x] I18n for `en` and `es-CO` with rails-i18n, `APP_LOCALE` as in the gym app, and time zone America/Bogota.
- [x] The `pesos` attribute type, with its spec.
- [x] Replace the generated README with a short one: what the app is, that it's being built, and its license.
- [x] Add a Commands section to CLAUDE.md.

Done when a fresh clone runs `bin/setup`, `bin/dev` and `bundle exec rspec`, and CI is green.

#### M1. Shops and sign-in (4 h)

- [x] Authentication from the Rails generator, without the email password reset. The account page lets users change their own password and sign out. A session lasts until the user signs out, so the phone stays signed in.
- [x] `shops`, and `users` belonging to a shop. acts_as_tenant with `require_tenant`, the tenant set from the signed-in user's shop.
- [x] Rake tasks: `shops:create` (shop name, `started_on`, today by default, and the user's name and email), which prints a generated password once; and `users:new_password` (email), which prints a new one once and signs the user out everywhere.

Done when request specs show that a user only reaches their own shop, and that a visitor without a session goes to sign in.

#### M2. The look and the shell (4 h)

- [x] The approved visual direction: Atkinson Hyperlegible Next and Mono self-hosted, the color tokens in Tailwind's `@theme`, and the layout with the shop's name, the account button and the tab bar, plus its wide layout.
- [x] Sign-in and account pages in the same style.
- [x] Rails 8's PWA manifest, with the app's name and 192 and 512 px icons (maskable), linked from the layout.

Done when the empty shell matches the approved screens at 390px and holds up at 1280px, in screenshots the owner approves.

#### M3. The shop: services, fixed costs and work days (6 h)

- [x] Money fields: one Stimulus controller that lets the user type digits only and formats the amount as they type. It filters on `input`, since Android keyboards don't report keys reliably in `keydown`.
- [x] A shared example for request specs: a user of another shop gets a 404. Services is the first controller with a shop's records, so it starts there, and every later controller uses it.
- [x] Services: the list with what each one leaves, create, edit, deactivate and activate, and the folded list of deactivated ones.
- [x] Fixed costs: the list with this month's amounts and total, add, change from a month (`FixedCosts::ChangeService`), remove from a month, the averaged mark, and the help about the home's bills.
- [x] Work days on the fixed costs page, with the month's work days and fixed costs per work day.

Done when model and service specs cover a change from a later month leaving the current one alone, a second change in the same month replacing the first, and a removal; query specs cover the fixed costs per day of months with different numbers of work days; and request specs cover isolation.

#### M4. Recording (5 h)

- [x] Record a job: date, service, quantity, price, materials, the live summary, "Guardar" and "Guardar y registrar otro", with one Stimulus controller.
- [x] Edit and delete jobs.
- [x] Record, edit and delete expenses and other income, with their notes and recent lists.

Done when a system spec records two jobs in a row with "Guardar y registrar otro", changing the price of one; model specs cover the copied price and material cost and the allowed dates; and request specs cover isolation.

#### Demo seeds (2 h, before M5)

- [x] Deterministic seeds (`Random.new(42)`, fixed lists), relative to today and built through the app's services: "Modistería La Puntada", from the approved screens, working Monday to Saturday, with its services (two of them deactivated), its fixed costs and a rent change from next month, and six months of jobs, expenses and other income, with some losing days; and a second shop working Monday to Friday, with fewer services and one month of history. Both users share a password that the seeds print.

Done when `bin/rails db:seed` builds both shops from any database, and CI runs it.

#### M5. Today (3 h)

- [x] The results of a period as one query object (`Results::PeriodQuery`), which Reports reuses.
- [x] Today as the home page: the goal panel with the tape bar and its note, the day off, the two record buttons, today's jobs and the month so far, through one facade.

Done when query specs cover a period in progress, a period across two months, the shop's start date and a day off; and a system spec checks the day's goal after recording a job.

#### M6. Deploy and backups (6 h)

- [x] DNS: in Cloudflare, under `yunquelabs.com`, an `A` record named `taller` pointing at the gym app's server, with the proxy off ("DNS only"), so kamal-proxy can get its certificate.
- [x] Kamal: service `tailor_shop_ledger` at `taller.yunquelabs.com`, on the gym app's server, with its local registry (`localhost:5555`), PostgreSQL 17 as an accessory with its own volume and no published port, and the secrets in `.kamal/secrets` read from the encrypted credentials, whose `config/master.key` is never committed. The proxy also serves the gym app: never run `kamal proxy reboot` without warning the owner.
- [x] `BackupJob` every night at 3:30 a.m. Bogotá time, after the gym app's at 3, copied from the gym app: a `pg_dump` of the primary database, uploaded with curl to the R2 bucket `tailor-shop-ledger-backups` (a lifecycle rule deletes objects after 30 days; its token has Object Read & Write on that bucket only). Then a ping to a Healthchecks.io check on the same schedule, in America/Bogota, or to the check's `/fail` URL when the backup fails. The ping URL lives in the encrypted credentials.
- [x] Sentry: a project of its own, errors only, with the gym app's initializer, which keeps personal data and the row PostgreSQL quotes in its errors out of the events.
- [ ] Restore drill: download a scheduled backup from R2, restore it into a local database and run the app on it.
- [x] `docs/deploy.md`, adapted from the gym app's: the server it shares, DNS, Kamal, shops and passwords, backups, restoring and monitoring. The README points to it.
- [x] With both apps running, check the server's memory (`free -m` and `docker stats --no-stream`).
- [x] On an Android phone, Chrome puts the app on the home screen. If Chrome asks for a service worker, register the one Rails generated, which caches nothing.

Done when the app runs over HTTPS next to the gym app; a scheduled backup has been restored following the written steps; and Healthchecks.io got the night's ping.

#### M7. Reports (6 h)

- [x] The period switch, the arrows, the result panel and the calculation, with `Results::PeriodQuery`.
- [x] The services that left the most in the period.
- [x] Month by month: the last six months, the current one marked "hasta hoy".
- [x] In the day view, the day's jobs and entries, each opening its form. Saving, cancelling or deleting a past day's record then returns to that day's report, as the rule under Today says; until M7 every record returns to Today.

Done when specs cover the boundaries of weeks, semesters and years, a period before the shop started and the ranking of services; and a system spec goes from the current month to the previous one.

#### M8. README (2 h)

- [x] README: what the app is and who it's for, screenshots at phone width from the demo seeds (Today, Record, Reports and the shop), the accounting rules, stack, local setup, tests, deploy and license.

Done when `bin/rails db:seed` on an empty database gives the demo shown in the screenshots.

#### M9. Orders (12 h)

The first shop takes deposits and is paid the rest later, sometimes in parts (gathered on 2026-10-19), and it starts only once v0.1 handles them.

- [x] `orders` and `payments`, and jobs in an order, with their validations.
- [x] Payments in `Results::PeriodQuery`, and the pending orders as a query object.
- [ ] The order's page: create, edit and delete an order; add, edit and delete its jobs through the job form; record, edit and delete its payments.
- [ ] Registrar's "Pedido"; on Hoy, "Te deben" and the day's payments; and the payments in a day's report.
- [ ] Keep the customer's name out of the logs.
- [ ] Demo seeds: La Puntada gets orders paid in two parts, one with a payment in between, one across two months, and some pending, one of them finished and never picked up.
- [ ] README: the rules for orders, and the Today screenshot again.
- [ ] Tag `v0.1.0` (moved from M8, since v0.1 now includes orders).

Done when model specs cover a payment over the order's total, a payment before its order's day and an order's day moving its jobs; query specs cover a deposit and the rest in different months, a pending order and one without jobs; request specs cover isolation; a system spec takes an order with two jobs and a deposit, then its last payment, checking Today after each; and the owner approves the new pages in screenshots at phone and desktop width.

#### The first shop

- [ ] Create the first shop with the rake task, starting on the first day it wrote down on paper.

Done when the first shop has its services, fixed costs and work days, and has entered the days it wrote down on paper, with the same totals as the paper.

### Before a second shop

- [ ] A privacy notice under Colombian Law 1581, linked from the sign-in page, and written terms of use, including the customers' names a shop keeps on its orders and what happens to a shop's data when it leaves.
- [ ] Export a shop's records, so it can take them when it leaves, and a rake task that deletes a shop with everything it owns, listing it first.

### Only when shops ask for it

- [ ] Export to Excel.
- [ ] How long each service takes, to see which one pays the most per hour.
- [ ] The accounts with and without the home's share (an idea of the owner's): a "belongs to the home" mark on fixed costs, expenses and other income; Today adds a line under the bar with the goal without the home's share, and Reports splits fixed costs into the shop's own and the home's share, with the profit before and after that share. Both views at once, never a switch.
- [ ] A holiday calendar, for shops that close on holidays.
- [ ] Due dates for orders and the state of their work (in progress, ready), to keep the shop's queue.
