module Seeds
  # Two demo shops. "Modistería La Puntada", from the approved screens: Monday to Saturday, its services, two of
  # them deactivated, its fixed costs with a rent change from next month, six months of jobs, expenses and other
  # income, some days at a loss, with today's jobs those of the Today screen, orders paid in parts, some still
  # owed for, and two customers who pay up front, one of whom owes. And "Arreglos El Dedal", in its owner's home:
  # Monday to Friday, fewer services, and one month of history.
  # Everything goes through the app's own services and forms, so a seed that breaks a rule fails instead of
  # creating impossible data. Deterministic (Random.new(42)) and relative to today; one transaction, so a
  # failing seed leaves the database as it was.
  class Demo
    PASSWORD = "costura-demo"

    # Services as [price, material cost, weight among a day's jobs]. Retired ones did jobs until
    # RETIRED_DAYS_AGO days ago, and were deactivated then.
    RETIRED_DAYS_AGO = 60
    SHOPS = [
      { name: "Modistería La Puntada", user: "Ana Gómez", email: "ana@demo.test", started_on: ->(today) { today.months_ago(6).beginning_of_month },
        work_days: [ 1, 2, 3, 4, 5, 6 ], jobs_a_day: [ 1, 2, 3, 3, 4, 4, 5, 5, 6, 7 ],
        services: { trouser_hem: [ 8_000, 500, 30 ], zipper: [ 15_000, 2_800, 14 ], waist: [ 14_000, 400, 10 ], skirt_hem: [ 12_000, 600, 12 ],
                    shirt: [ 16_000, 500, 8 ], buttons: [ 7_000, 1_800, 12 ], lining: [ 35_000, 6_000, 4 ], dress: [ 180_000, 65_000, 1 ] },
        retired_services: { embroidery: [ 12_000, 2_000, 4 ], curtains: [ 45_000, 8_000, 1 ] },
        fixed_costs: { rent: [ 900_000, false ], electricity: [ 120_000, true ], water: [ 55_000, true ], internet: [ 70_000, false ], phone: [ 45_000, false ] },
        rent_from_next_month: 950_000, expenses_a_month: 3, incomes_a_month: 1, orders: true, advances: true,
        # The Today screen's jobs but its zipper, which is an advance's (see record_advances), and the Record
        # screen's latest expenses and other income, by day of this month (instead of random ones).
        today: [ [ :trouser_hem, 2 ], [ :buttons, 1 ] ],
        this_month: [ [ "expense", :overlocker, 14, 35_000 ], [ "expense", :transport, 3, 12_000 ], [ "income", :scraps, 9, 20_000 ] ] },
      { name: "Arreglos El Dedal", user: "Rosa Pérez", email: "rosa@demo.test", started_on: ->(today) { today.prev_month },
        work_days: [ 1, 2, 3, 4, 5 ], jobs_a_day: [ 0, 1, 1, 2, 2, 3, 4 ],
        services: { trouser_hem: [ 7_000, 400, 10 ], zipper: [ 14_000, 2_500, 5 ], waist: [ 12_000, 300, 5 ], jacket: [ 25_000, 3_000, 2 ] },
        retired_services: {},
        fixed_costs: { home_rent: [ 250_000, false ], home_electricity: [ 35_000, true ], internet: [ 40_000, false ] },
        expenses_a_month: 1, incomes_a_month: 0, orders: false, advances: false, today: nil, this_month: [] }
    ].freeze

    EXPENSES = { overlocker: 35_000, transport: 12_000, spare_part: 28_000, scissors: 8_000, bulb: 6_000 }.freeze

    TEXTS = {
      en: {
        services: { trouser_hem: "Trouser hem", zipper: "Zipper replacement", waist: "Waist taken in", skirt_hem: "Skirt or dress hem",
                    shirt: "Shirt taken in", buttons: "Button replacement", lining: "Jacket lining", dress: "Dressmaking",
                    embroidery: "Name embroidery", curtains: "Curtains", jacket: "Jacket alteration" },
        fixed_costs: { rent: "Shop rent", electricity: "Electricity", water: "Water", internet: "Internet", phone: "Phone plan",
                       home_rent: "The shop's share of the rent", home_electricity: "The shop's share of the electricity" },
        entries: { overlocker: "Overlocker maintenance", transport: "Transport", spare_part: "Machine spare part", scissors: "Scissors sharpening",
                   bulb: "Light bulb for the shop", scraps: "Selling fabric scraps" }
      },
      "es-CO": {
        services: { trouser_hem: "Basta de pantalón", zipper: "Cambio de cremallera", waist: "Ajuste de cintura", skirt_hem: "Ruedo de falda o vestido",
                    shirt: "Entalle de camisa", buttons: "Cambio de botones", lining: "Forro de chaqueta", dress: "Confección de vestido",
                    embroidery: "Bordado de nombre", curtains: "Cortinas", jacket: "Arreglo de chaqueta" },
        fixed_costs: { rent: "Arriendo del local", electricity: "Luz", water: "Agua", internet: "Internet", phone: "Celular",
                       home_rent: "Parte del arriendo de la casa", home_electricity: "Parte de la luz de la casa" },
        entries: { overlocker: "Mantenimiento de la fileteadora", transport: "Transporte", spare_part: "Repuesto de la máquina", scissors: "Afilada de tijeras",
                   bulb: "Bombillo del taller", scraps: "Venta de retazos" }
      }
    }.freeze

    def initialize
      @rng = Random.new(42)
      @today = Date.current
      @texts = TEXTS.fetch(I18n.locale)
    end

    def run
      # Logging every query, with the source line of each in development, would make it several times slower.
      Rails.logger.silence do
        ActiveRecord::Base.transaction do
          wipe
          SHOPS.each { build_shop(it) }
        end
      end
      puts "Demo shops, all with the password #{PASSWORD}:"
      SHOPS.each { puts "  #{it[:name]}: #{it[:email]}" }
    end

    private
      # Every table but Rails' own, with ids starting again from 1.
      def wipe
        connection = ActiveRecord::Base.connection
        tables = connection.tables - [ ActiveRecord::Base.schema_migrations_table_name, ActiveRecord::Base.internal_metadata_table_name ]
        connection.execute("TRUNCATE #{tables.map { connection.quote_table_name(it) }.join(", ")} RESTART IDENTITY CASCADE")
      end

      def build_shop(config)
        shop = Shops::CreateService.call(name: config[:name], started_on: config[:started_on].call(@today), user_name: config[:user],
          user_email: config[:email], password: PASSWORD).shop
        shop.update!(work_days: config[:work_days])

        ActsAsTenant.with_tenant(shop) do
          services = create_services(config)
          add_fixed_costs(shop, config)
          record_jobs(shop, config, services)
          record_entries(shop, config)
          record_orders(services) if config[:orders]
          record_advances(services) if config[:advances]
          services.slice(*config[:retired_services].keys).each_value { it.update!(active: false) }
        end
      end

      def create_services(config)
        config[:services].merge(config[:retired_services]).to_h do |key, (price, material_cost)|
          [ key, Service.create!(name: @texts[:services][key], price:, material_cost:) ]
        end
      end

      # From the month the shop started, as a shop entering its days from paper does, and the rent changes from
      # next month.
      def add_fixed_costs(shop, config)
        fixed_costs = config[:fixed_costs].to_h do |key, (amount, averaged)|
          form = NewFixedCost.new(shop:, name: @texts[:fixed_costs][key], averaged:, amount:, starts_on: shop.started_on.beginning_of_month)
          [ key, FixedCosts::CreateService.call(form:) || raise(ArgumentError, form.errors.full_messages.to_sentence) ]
        end
        return unless config[:rent_from_next_month]

        change = FixedCostChange.new(fixed_cost: fixed_costs[:rent], amount: config[:rent_from_next_month], starts_on: @today.next_month.beginning_of_month)
        FixedCosts::ChangeService.call(change:) || raise(ArgumentError, change.errors.full_messages.to_sentence)
      end

      def record_jobs(shop, config, services)
        (shop.started_on..@today).each do |day|
          if day == @today && config[:today]
            config[:today].each { |key, quantity| Job.create!(service: services[key], done_on: day, quantity:) }
          elsif shop.work_days.include?(day.wday)
            weights = services_on(day, config, services)
            config[:jobs_a_day].sample(random: @rng).times { record_job(pick(weights), day, [ 1, 1, 1, 1, 1, 1, 2, 2, 3 ].sample(random: @rng)) }
          end
        end
      end

      # The services a day's jobs come from, each with its weight.
      def services_on(day, config, services)
        retired = day < @today - RETIRED_DAYS_AGO ? config[:retired_services] : {}
        config[:services].merge(retired).to_h { |key, (_price, _material_cost, weight)| [ services[key], weight ] }
      end

      # Now and then a garment costs more than the usual price, or the customer brings the materials.
      def record_job(service, done_on, quantity)
        job = Job.new(service:, done_on:, quantity:)
        job.price += 2_000 if @rng.rand < 0.08
        job.material_cost = 0 if @rng.rand < 0.06
        job.save!
      end

      def pick(weights)
        target = @rng.rand(weights.values.sum)
        weights.find { |_service, weight| (target -= weight).negative? }.first
      end

      def record_entries(shop, config)
        months = (shop.started_on..@today).group_by(&:beginning_of_month)
        months.delete(@today.beginning_of_month) if config[:this_month].any?

        months.each_value do |days|
          config[:expenses_a_month].times do
            key = EXPENSES.keys.sample(random: @rng)
            Entry.create!(kind: "expense", occurred_on: days.sample(random: @rng), concept: @texts[:entries][key], amount: EXPENSES[key])
          end
          config[:incomes_a_month].times do
            Entry.create!(kind: "income", occurred_on: days.sample(random: @rng), concept: @texts[:entries][:scraps], amount: @rng.rand(15..25) * 1_000)
          end
        end

        config[:this_month].each do |kind, key, day, amount|
          occurred_on = @today.change(day:)
          Entry.create!(kind:, occurred_on:, concept: @texts[:entries][key], amount:) if occurred_on <= @today
        end
      end

      # Orders as customers pay them, with fixed days and amounts: two paid off, one with a payment in between;
      # one left last month and paid off on the 1st of this one; and three still owed for, one of them finished and
      # never picked up. None comes in today, so Today keeps the approved screen's figures. :rest is what's owed.
      def record_orders(services)
        month = @today.beginning_of_month
        [
          [ "Carmen Díaz", @today - 70, { dress: 1 }, [ [ @today - 70, 72_000 ], [ @today - 52, :rest ] ] ],
          [ "Patricia Rojas", @today - 45, { lining: 2, zipper: 1 }, [ [ @today - 45, 25_000 ], [ @today - 38, 30_000 ], [ @today - 31, :rest ] ] ],
          [ "Sandra Castro", month - 5, { dress: 1, skirt_hem: 2 }, [ [ month - 5, 80_000 ], [ month, :rest ] ] ],
          [ "Gloria Suárez", @today - 40, { dress: 1 }, [ [ @today - 40, 70_000 ] ] ],
          [ "Marta Rodríguez", @today - 5, { trouser_hem: 3, zipper: 1 }, [ [ @today - 5, 20_000 ] ] ],
          [ "Lucía Herrera", @today - 2, { skirt_hem: 2 }, [] ]
        ].each do |customer_name, received_on, jobs, payments|
          order = Order.create!(customer_name:, received_on:)
          jobs.each { |key, quantity| Job.create!(order:, service: services[key], quantity:) }
          payments.each { |paid_on, amount| Payment.create!(order:, paid_on:, amount: amount == :rest ? order.owed : amount) }
        end
      end

      # Customers who pay up front, with fixed days and amounts: Hotel Almendros for the last months, which ran past
      # its balance once before its next top-up, and ends with the advances screens' balance after today's zipper,
      # one of the Today screen's jobs; and Lucía Restrepo, since this month, who owes a little.
      def record_advances(services)
        [
          [ "Hotel Almendros", [ [ @today - 75, 200_000 ], [ @today - 47, 150_000 ], [ @today - 19, 300_000 ], [ @today - 4, 100_000 ] ],
            [ [ @today - 72, :shirt, 4 ], [ @today - 66, :trouser_hem, 6 ], [ @today - 58, :lining, 2 ], [ @today - 51, :waist, 5 ], [ @today - 40, :buttons, 10 ],
              [ @today - 31, :waist, 2 ], [ @today - 17, :trouser_hem, 6 ], [ @today - 13, :shirt, 4 ], [ @today - 8, :waist, 5 ], [ @today - 5, :buttons, 10 ],
              [ @today - 1, :trouser_hem, 3 ], [ @today, :zipper, 1 ] ] ],
          [ "Lucía Restrepo", [ [ @today - 15, 120_000 ] ], [ [ @today - 12, :lining, 2 ], [ @today - 6, :skirt_hem, 2 ], [ @today - 1, :zipper, 2 ] ] ]
        ].each do |customer_name, top_ups, jobs|
          advance = Advance.create!(customer_name:)
          top_ups.each { |paid_on, amount| TopUp.create!(advance:, paid_on:, amount:) }
          jobs.each { |done_on, key, quantity| Job.create!(advance:, service: services[key], done_on:, quantity:) }
        end
      end
  end
end
